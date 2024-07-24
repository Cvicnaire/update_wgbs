version 1.0

# sort the mapped reads
task Sort {
    input {
      File bam_input
      String output_base_name
      
    }

      # input file size
      Float input_size = size(bam_input, "GB")

      # output name for sorted bam
      String bam_sort_output_name = output_base_name + ".sorted.bam"

  # sort with samtools
  command <<<
    set -euo pipefail


      picard SortSam \
      INPUT=~{bam_input} \
      SORT_ORDER=coordinate \
      MAX_RECORDS_IN_RAM=300000 \
      OUTPUT=~{bam_sort_output_name}
  >>>

  runtime {
    docker: " quay.io/biocontainers/mulled-v2-23d9f7c700e78129a769e78521eb86d6b8341923:8dde04faba6c9ac93fae7e846af3bafd2c331b3b-0"
    cpu: 4
    
  }

  output {
    File bam_sort_output = bam_sort_output_name
   
  }
}
