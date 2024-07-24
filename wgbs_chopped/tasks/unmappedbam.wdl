version 1.0

# Creating unmapped bam from the input fastq files


task CreateUnmappedBam {
    input {
      # read 1 when with adapter sequences trimmed off
      File fastq_input
      String output_base_name
      
    }

      # input file size
      Float input_size = size(fastq_input, "GB")

      # output name for unaligned bam
      String unmapped_bam_output_name = output_base_name + ".unmapped.bam"

  command <<<
    set -euo pipefail

    # create an unmapped bam
      picard FastqToSam \
      FASTQ=~{fastq_input} \
      SAMPLE_NAME=~{output_base_name} \
      OUTPUT=~{unmapped_bam_output_name}
  >>>

  # use docker image for given tool picard
  runtime {
    docker: "quay.io/biocontainers/mulled-v2-23d9f7c700e78129a769e78521eb86d6b8341923:8dde04faba6c9ac93fae7e846af3bafd2c331b3b-0"
    cpu: 4
    
  }

  output {
    File unmapped_bam_output = unmapped_bam_output_name
    
  }
}