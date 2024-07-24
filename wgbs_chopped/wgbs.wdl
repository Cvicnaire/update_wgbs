version 1.0

import "tasks/trim.wdl" as Trim
import "tasks/unmappedbam.wdl" as CreateUnmappedBam
import "tasks/extractbarcodes.wdl" as ExtractCellBarcodes
import "tasks/align.wdl" as Align
import "tasks/attachbarcodes.wdl" as AttachBarcodes
import "tasks/mergebams.wdl" as MergeBams
import "tasks/sort.wdl" as Sort
import "tasks/filterduplicates.wdl" as FilterDuplicates
import "tasks/filtermapqual.wdl" as FilterMapQuality
import "tasks/methylreport.wdl" as GetMethylationReport
import "tasks/readgroup.wdl" as AddReadGroup
import "tasks/methylcaller.wdl" as MethylationTypeCaller
import "tasks/vcftoallc.wdl" as VCFtoALLC
import "tasks/coveragedepth.wdl" as ComputeCoverageDepth
import "tasks/indexbam.wdl" as IndexBam

# Main worklfow wgbs 

workflow CEMBA {
    input {
      # name of outputs and intermediate files of pipeline
      String output_base_sample_name

      # compressed read 1 and read 2 paired inputs
      File fastq_r1_gzipped_input
      File fastq_r2_gzipped_input

      File? monitoring_script

      # a list of cell barcodes that are being used
      File? barcode_white_list

      # location of barcode
      Int barcode_start_pos
      Int barcode_length

      # bowtie2 indexes used for mapping
      # using BuildCembaReference.wdl
      # reference dictionary for building VCF and attaching barcodes
      File reference_fasta
      File reference_fasta_index
      File reference_dictionary
      File fwd_converted_reference_fasta
      File rev_converted_reference_fasta
      Array[File] fwd_bowtie2_index_files
      Array[File] rev_bowtie2_index_files

      # trimming cutadapt options
      Int quality_cutoff
      Int min_length_paired_end_trim
      Int min_length_single_end_trim
      String read1_adapter_seq
      String read2_adapter_seq
      Int cut_length

      # paired end vs single end mapping boolean/option
      Boolean paired_end_run

      # should mark duplicates in picard mark or removes duplicates
      Boolean remove_duplicates

      # default add barcodes to read 1 in outputted bam (compitable with single end alignment only)
      Boolean extract_and_attach_barcodes_in_single_end_run

      # filter map quality option (optional)
      Int? min_map_quality

      # default names for adding a read group
      String read_group_library_name = "Methylation"
      String read_group_platform_name = "Illumina"
      String read_group_platform_unit_name = "snmC-Seq"
      
      Int cpu = 4
    }

    # version of this pipeline
    String pipeline_version = "1.1.6"

  # trim off hardcoded sequence adapters
  call Trim.Trim as TrimAdapters {
    input:
      fastq_input_read_a = fastq_r1_gzipped_input,
      fastq_input_read_b = fastq_r2_gzipped_input,
      quality_cutoff = quality_cutoff,
      min_length = min_length_paired_end_trim,
      read1_adapter_seq = read1_adapter_seq,
      read2_adapter_seq = read2_adapter_seq,
      output_base_name = output_base_sample_name
      
  }

  if (extract_and_attach_barcodes_in_single_end_run && !paired_end_run) {
    # produce an unmapped bam to tag the barcodes
    call CreateUnmappedBam.CreateUnmappedBam {
      input:
        fastq_input = TrimAdapters.trimmed_fastqs[0],
        output_base_name = output_base_sample_name + ".R1"
        
    }

    # extract and tag the barcodes to unmapped bam
    call ExtractCellBarcodes.ExtractCellBarcodes {
      input:
        fastq_input = TrimAdapters.trimmed_fastqs[0],
        unmapped_bam_input = CreateUnmappedBam.unmapped_bam_output,
        barcode_white_list = barcode_white_list,
        barcode_start_pos = barcode_start_pos,
        barcode_length = barcode_length,
        output_base_name = output_base_sample_name + ".R1"
        
    }
  }

  # trim off Degenerate bases H = [A, T or C]/primer index sequence of Read 1
  call Trim.Trim as TrimSingleRead1 {
    input:
      fastq_input_read_a = TrimAdapters.trimmed_fastqs[0],
      min_length = min_length_single_end_trim,
      cut_length = cut_length,
      output_base_name = output_base_sample_name + ".R1"
      
  }

  # trim off the C/T tail appended by Adaptase of read2
  call Trim.Trim as TrimSingleRead2 {
    input:
      fastq_input_read_a = TrimAdapters.trimmed_fastqs[1],
      min_length = min_length_single_end_trim,
      cut_length = cut_length,
      output_base_name = output_base_sample_name + ".R2"
      
  }

  if (paired_end_run) {
    # map as paired end
    call Align.Align as MapReadsPairedEnd {
      input:
        paired_end_run = true,
        directional = true,
        fastq_input_read_a = TrimSingleRead1.trimmed_fastqs[0],
        fastq_input_read_b = TrimSingleRead2.trimmed_fastqs[0],
        reference_fasta = reference_fasta,
        reference_fasta_index = reference_fasta_index,
        fwd_converted_reference_fasta = fwd_converted_reference_fasta,
        fwd_bowtie2_index_files = fwd_bowtie2_index_files,
        rev_converted_reference_fasta = rev_converted_reference_fasta,
        rev_bowtie2_index_files = rev_bowtie2_index_files,
        output_base_name = output_base_sample_name + ".paired_end"
       
    }
  }
  if (!paired_end_run) {
    # map read 1 as single-end
    call Align.Align as MapReadSingleEndRead1  {
      input:
        paired_end_run = false,
        directional = true,
        fastq_input_read_a = TrimSingleRead1.trimmed_fastqs[0],
        reference_fasta = reference_fasta,
        reference_fasta_index = reference_fasta_index,
        fwd_converted_reference_fasta = fwd_converted_reference_fasta,
        fwd_bowtie2_index_files = fwd_bowtie2_index_files,
        rev_converted_reference_fasta = rev_converted_reference_fasta,
        rev_bowtie2_index_files = rev_bowtie2_index_files,
        output_base_name = output_base_sample_name + ".R1.single_end"
        
    }

    # map read 2 as single-end
    call Align.Align as MapReadSingleEndRead2  {
      input:
        paired_end_run = false,
        directional = false,
        fastq_input_read_a = TrimSingleRead2.trimmed_fastqs[0],
        reference_fasta = reference_fasta,
        reference_fasta_index = reference_fasta_index,
        fwd_converted_reference_fasta = fwd_converted_reference_fasta,
        fwd_bowtie2_index_files = fwd_bowtie2_index_files,
        rev_converted_reference_fasta = rev_converted_reference_fasta,
        rev_bowtie2_index_files = rev_bowtie2_index_files,
        output_base_name = output_base_sample_name + ".R2.single_end"
    }
  }

  # either the paired end aligned bam or...
  # the single end aligned read 1 bam and the single end aligned read 2 bam
  Array[Pair[File, String]] alignment_outputs = (
    if paired_end_run
    then [(select_first([MapReadsPairedEnd.mapped_bam_output]), "")]
    else [
      (select_first([MapReadSingleEndRead1.mapped_bam_output]), ".R1"),
      (select_first([MapReadSingleEndRead2.mapped_bam_output]), ".R2")
    ]
  )

  scatter (alignment_output in alignment_outputs) {
    # sort the bam in coordinate order to filter
    call Sort.Sort as SortAlignmentOutputBam {
      input:
        bam_input = alignment_output.left,
        output_base_name = output_base_sample_name + alignment_output.right
       
    }

    # remove duplicates from bam
    call FilterDuplicates.FilterDuplicates {
      input:
        bam_input = SortAlignmentOutputBam.bam_sort_output,
        remove_duplicates = remove_duplicates,
        output_base_name = output_base_sample_name + alignment_output.right
       
    }

    # get a methylation report for the filtered duplicates bam
    call GetMethylationReport.GetMethylationReport as GetMethylationReportForFilterDuplicates {
      input:
        bam_input = FilterDuplicates.bam_remove_dup_output,
        output_base_name = output_base_sample_name + alignment_output.right
        
    }

    if (defined(min_map_quality)) {
      # filter bam by map quality
      call FilterMapQuality.FilterMapQuality {
      input:
        bam_input = FilterDuplicates.bam_remove_dup_output,
        min_map_quality = select_first([min_map_quality]),
        output_base_name = output_base_sample_name + alignment_output.right
        
      }

      # get methylation report for filtered bam
      call GetMethylationReport.GetMethylationReport as GetMethylationReportForAboveMinMapQReads {
        input:
          bam_input = FilterMapQuality.bam_filter_above_min_mapq_output,
          output_base_name = output_base_sample_name + alignment_output.right + ".above_min_map_quality"
          
      }

      # get methylation report for filtered bam
      call GetMethylationReport.GetMethylationReport as GetMethylationReportForBelowMinMapQReads {
        input:
          bam_input = FilterMapQuality.bam_filter_below_min_mapq_output,
          output_base_name = output_base_sample_name + alignment_output.right + ".below_min_map_quality"
         
      }
    }

    # if not filtering by map quality: the filtered duplicatets bam
    # else: the filtered map quality bam
    File filtered_bam = select_first([FilterMapQuality.bam_filter_above_min_mapq_output, FilterDuplicates.bam_remove_dup_output])
  }

  # if mapped in single end (2 alignment outputs)
  if (!paired_end_run) {
    File aligned_and_filtered_read1_bam = filtered_bam[0]
    File aligned_and_filtered_read2_bam = filtered_bam[1]

    if (extract_and_attach_barcodes_in_single_end_run) {
      # add barcodes from tagged unmapped bam to aligned bam
      call AttachBarcodes.AttachBarcodes {
        input:
          mapped_bam_input = aligned_and_filtered_read1_bam,
          tagged_unmapped_bam_input = select_first([ExtractCellBarcodes.tagged_unmapped_bam_output]),
          reference_fasta = reference_fasta,
          reference_dictionary = reference_dictionary,
          cut_length = cut_length,
          output_base_name = output_base_sample_name + ".R1"
          
      }
    }

    # merge read 1 and read 2 alligned, sorted and filtered bams
    call MergeBams.MergeBams {
      input:
        bam_input_a = select_first([AttachBarcodes.tagged_mapped_bam_output, aligned_and_filtered_read1_bam]),
        bam_input_b = aligned_and_filtered_read2_bam,
        output_base_name = output_base_sample_name
        
    }
  }

  # input bam is either the flitered and merged read 1 SE and read 2 SE bam or the filtered PE bam
  call AddReadGroup.AddReadGroup {
    input:
      bam_input = select_first([MergeBams.merged_bam_output, filtered_bam[0]]),
      read_group_library_name = read_group_library_name,
      read_group_platform_name = read_group_platform_name,
      read_group_platform_unit_name = read_group_platform_unit_name,
      read_group_platform_sample_name = output_base_sample_name,
      output_base_name = output_base_sample_name
     
  }

  # sort again in coordinate order after adding read group
  call Sort.Sort as SortFilteredBamWithReadGroup {
    input:
      bam_input = AddReadGroup.bam_with_read_group_output,
      output_base_name = output_base_sample_name + ".aligned.filtered"
     
  }

  # index the outputted bams
  call IndexBam.IndexBam {
    input:
      bam_input = SortFilteredBamWithReadGroup.bam_sort_output,
      output_base_name = output_base_sample_name + ".aligned.filtered.sorted"
      
  }

  # get methylated VCF
  call MethylationTypeCaller.MethylationTypeCaller as GetMethylationSiteVCF {
    input:
      bam_input = SortFilteredBamWithReadGroup.bam_sort_output,
      reference_fasta = reference_fasta,
      reference_fasta_index = reference_fasta_index,
      reference_dictionary = reference_dictionary,
      output_base_name = output_base_sample_name
      
  }

  # convert VCF to ALL
  call VCFtoALLC.VCFtoALLC {
    input:
      methylation_vcf_output_name = GetMethylationSiteVCF.methylation_vcf
  }

  # get number of sites that have a coverage greater than 1
  call ComputeCoverageDepth.ComputeCoverageDepth {
    input:
      bam = SortFilteredBamWithReadGroup.bam_sort_output,
      reference_fasta = reference_fasta
      
  }

  # output the bam, metrics and reports
  # select all will select an array consisting of 2 single end reports or an array of 1 paired end reports
  output {
    File aligned_and_filtered_bam = SortFilteredBamWithReadGroup.bam_sort_output
    File aligned_and_filtered_bam_index = IndexBam.bam_index_output

    File methylation_site_vcf = GetMethylationSiteVCF.methylation_vcf
    File methylation_site_vcf_index = GetMethylationSiteVCF.methylation_vcf_index

    File methylation_site_allc = VCFtoALLC.methylation_allc

    Int coverage_depth = ComputeCoverageDepth.total_depth_count

    ### TODO
    #
    # We know all the outputs below here either have 1 output or 2, depending on
    # whether or not the pipeline was run in paired-end mode.
    #
    # Ideally we could have 3 `File?` outputs with meaningfully distinct names for
    # each output instead of an array. Limitations in draft-2 WDL's handling of
    # optional types prevents us from doing this within a single workflow. We could
    # work around this by pulling pieces of the pipeline into a sub-workflow which
    # we explicitly call three times, but that'll only work in Terra if we can
    # make the sub-workflow public.

    Array[File] mapping_reports = select_all([
      MapReadSingleEndRead1.mapping_report_output,
      MapReadSingleEndRead2.mapping_report_output,
      MapReadsPairedEnd.mapping_report_output
    ])

    Array[File] duplicate_metrics = FilterDuplicates.metric_remove_dup_output

    Array[File] methylation_mbias_reports_filtered_duplicates = GetMethylationReportForFilterDuplicates.methylation_mbias_report_output
    Array[File] methylation_splitting_reports_filtered_duplicates = GetMethylationReportForFilterDuplicates.methylation_splitting_report_output
    Array[File] methylation_CpG_context_reports_filtered_duplicates = GetMethylationReportForFilterDuplicates.methylation_CpG_context_report_output
    Array[File] methylation_non_CpG_context_reports_filtered_duplicates = GetMethylationReportForFilterDuplicates.methylation_non_CpG_context_report_output

    Array[File] methylation_mbias_reports_filtered_above_min_mapq = select_all(
      GetMethylationReportForAboveMinMapQReads.methylation_mbias_report_output
    )
    Array[File] methylation_splitting_reports_filtered_above_min_mapq = select_all(
      GetMethylationReportForAboveMinMapQReads.methylation_splitting_report_output
    )
    Array[File] methylation_CpG_context_reports_filtered_above_min_mapq = select_all(
      GetMethylationReportForAboveMinMapQReads.methylation_CpG_context_report_output
    )
    Array[File] methylation_non_CpG_context_reports_filtered_above_min_mapq = select_all(
      GetMethylationReportForAboveMinMapQReads.methylation_non_CpG_context_report_output
    )

    Array[File] methylation_mbias_reports_min_filtered_below_mapq = select_all(
      GetMethylationReportForBelowMinMapQReads.methylation_mbias_report_output
    )
    Array[File] methylation_splitting_reports_filtered_below_min_mapq = select_all(
      GetMethylationReportForBelowMinMapQReads.methylation_splitting_report_output
    )
    Array[File] methylation_CpG_context_reports_filtered_below_min_mapq = select_all(
      GetMethylationReportForBelowMinMapQReads.methylation_CpG_context_report_output
    )
    Array[File] methylation_non_CpG_context_reports_filtered_below_min_mapq = select_all(
      GetMethylationReportForBelowMinMapQReads.methylation_non_CpG_context_report_output
    )
  }
}