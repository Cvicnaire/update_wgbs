version 1.0

#trim task
task Trim {
    input {
      Int min_length
      # read 1 when trimming adapters
      File fastq_input_read_a
      # read 2 when trimming adapters
      File? fastq_input_read_b
      String output_base_name
      String? read1_adapter_seq
      String? read2_adapter_seq
      Int? quality_cutoff
      Int? cut_length
      
    }

      # input file size
      Float input_size = size(fastq_input_read_a, "GB") + (if defined(fastq_input_read_b) then size(fastq_input_read_b, "GB") else 0)

      # output names for trimmed reads
      String fastq_trimmed_adapter_output_name_a = output_base_name
                                                     + (if defined(fastq_input_read_b) then ".R1.trimmed_adapters.fastq.gz" else ".trimmed_single.fastq.gz")
      String fastq_trimmed_adapter_output_name_b = (if defined(fastq_input_read_b) then output_base_name + ".R2.trimmed_adapters.fastq.gz" else "")

  # using cutadapt to trim off sequence adapters in paired end mode and c/t adaptase and cell/well barcode in sinlge end mode
  command <<<
   

    # fastq's, "-f", -A for paired adapters read 2"
      cutadapt \
      --minimum-length ~{min_length} \
      --output ~{fastq_trimmed_adapter_output_name_a} \
      ~{true="--paired-output"  false="" defined(fastq_input_read_b)} ~{fastq_trimmed_adapter_output_name_b} \
      ~{true="--quality-cutoff" false="" defined(quality_cutoff)} ~{quality_cutoff} \
      ~{true="--adapter" false="" defined(read1_adapter_seq)} ~{read1_adapter_seq} \
      ~{true="-A" false="" defined(read2_adapter_seq)} ~{read2_adapter_seq} \
      ~{true="--cut" false="" defined(cut_length)} ~{cut_length} \
      ~{true="--cut -" false="" defined(cut_length)}~{cut_length} \
      ~{fastq_input_read_a} ~{fastq_input_read_b}
  >>>

  # use docker image for given tool cutadapat
  runtime {
    docker: "quay.io/biocontainers/cutadapt:4.9--py38h0020b31_0"
    cpu: 4
    
  }

  output {
    Array[File] trimmed_fastqs = (if defined(fastq_input_read_b) then [fastq_trimmed_adapter_output_name_a, fastq_trimmed_adapter_output_name_b] else [fastq_trimmed_adapter_output_name_a])
    
  }
}