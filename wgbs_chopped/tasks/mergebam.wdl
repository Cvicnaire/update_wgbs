version 1.0

# Merging bam reads 1 & 2 

task MergeBams {
    input {
      File bam_input_a
      File bam_input_b
      String output_base_name
      
    }

      # input file size
      Float input_size = size(bam_input_a, "GB") + size(bam_input_b, "GB")

      # output name for merged bam
      String merged_bam_output_name = output_base_name + ".merged.bam"

  command <<<
    set -euo pipefail



    # merge 2 bams with samtools
    samtools merge \
      ~{merged_bam_output_name} \
      ~{bam_input_a} ~{bam_input_b}
  >>>
# samtools image with other packages, good for now. might need to create samtools image
  runtime {
    docker: "quay.io/biocontainers/mulled-v2-03d30cf7bcc23ba5d755e498a98359af8a2cd947:7b1ad5dbd0ee31d66967a1f20b4d8cd630dcec00-0"
    cpu: 4
  
  }

  output {
    File merged_bam_output = merged_bam_output_name
    
  }
}