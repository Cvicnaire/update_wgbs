version 1.0


# get the number of sites the have coverage of 1 or more
task ComputeCoverageDepth {
    input {
      File bam
      File reference_fasta
      
    }

      Float input_size = size(bam, "GB") + size(reference_fasta, "GB")

  command <<<
    set -euo pipefail

    # get samtools output and pipe into word count
    samtools depth \
      --reference ~{reference_fasta} \
      ~{bam} \
      | wc -l
  >>>

  runtime {
    docker: "quay.io/biocontainers/mulled-v2-03d30cf7bcc23ba5d755e498a98359af8a2cd947:7b1ad5dbd0ee31d66967a1f20b4d8cd630dcec00-0"
    cpu: 4
    
  }

  output {
    Int total_depth_count = read_int(stdout())
    
  }
}