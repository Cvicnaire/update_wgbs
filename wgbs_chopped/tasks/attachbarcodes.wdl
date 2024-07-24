version 1.0


task AttachBarcodes {
    input {
      File mapped_bam_input
      File tagged_unmapped_bam_input
      File reference_fasta
      File reference_dictionary
      Int cut_length
      String output_base_name
      
    }

      # input file size
      Float input_size = size(mapped_bam_input, "GB") +
        size(tagged_unmapped_bam_input, "GB") +
        size(reference_fasta, "GB") +
        size(reference_dictionary, "GB")

      # output names for bam with extracted barcodes
      String tagged_mapped_bam_output_name = output_base_name + ".tagged_mapped.bam"

  command <<<
    set -euo pipefail

   

    # create an unmapped bam
      picard MergeBamAlignment \
      SORT_ORDER="unsorted" \
      ADD_MATE_CIGAR=true \
      R1_TRIM=~{cut_length} R2_TRIM=~{cut_length} \
      IS_BISULFITE_SEQUENCE=true \
      UNMAP_CONTAMINANT_READS=false \
      UNMAPPED_BAM=~{tagged_unmapped_bam_input} \
      ALIGNED_BAM=~{mapped_bam_input} \
      REFERENCE_SEQUENCE=~{reference_fasta} \
      OUTPUT=~{tagged_mapped_bam_output_name}
  >>>

  # use docker image for given tool picard
  runtime {
    docker: "quay.io/biocontainers/mulled-v2-23d9f7c700e78129a769e78521eb86d6b8341923:8dde04faba6c9ac93fae7e846af3bafd2c331b3b-0"
    cpu: 4
  }

  output {
    File tagged_mapped_bam_output = tagged_mapped_bam_output_name
    
  }
}