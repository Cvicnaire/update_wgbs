version 1.0

# Filter bam by removing duplicates
task FilterDuplicates {
    input {
      File bam_input
      Boolean remove_duplicates
      String output_base_name
      
    }

      # input file size
      Float input_size = size(bam_input, "GB")

      # output name for filtered reads
      String bam_remove_dup_output_name = output_base_name + ".filtered.duplicates.bam"
      String metric_remove_dup_output_name = output_base_name + ".filtered.duplicate_metrics"

  command <<<
    set -euo pipefail

      picard MarkDuplicates \
      INPUT=~{bam_input} \
      OUTPUT=~{bam_remove_dup_output_name} \
      METRICS_FILE=~{metric_remove_dup_output_name} \
      REMOVE_DUPLICATES=~{remove_duplicates}
  >>>

  runtime {
     docker: "quay.io/biocontainers/mulled-v2-23d9f7c700e78129a769e78521eb86d6b8341923:8dde04faba6c9ac93fae7e846af3bafd2c331b3b-0"
     cpu: 4
     
  }

  output {
    File bam_remove_dup_output = bam_remove_dup_output_name
    File metric_remove_dup_output = metric_remove_dup_output_name
    
  }
}