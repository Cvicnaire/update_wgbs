version 1.0

# create bam index
task IndexBam {
    input {
      File bam_input
      String output_base_name
     
    }

      # input file size
      Float input_size = size(bam_input, "GB")

      # output name for indexed bam
      String bam_index_output_name = output_base_name + ".bam.bai"

  command <<<
    set -euo pipefail
    # index bam with samtools
    samtools index -b ~{bam_input} ~{bam_index_output_name}
  >>>

  runtime {
    docker: "quay.io/biocontainers/mulled-v2-03d30cf7bcc23ba5d755e498a98359af8a2cd947:7b1ad5dbd0ee31d66967a1f20b4d8cd630dcec00-0"
    cpu: 4
    
  }

  output {
    File bam_index_output = bam_index_output_name
    
  }
}
