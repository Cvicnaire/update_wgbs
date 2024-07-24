version 1.0 

# filter bam by mapping quality
task FilterMapQuality {
    input {
      File bam_input
      Int min_map_quality
      String output_base_name
      
    }

      # input file size
      Float input_size = size(bam_input, "GB")

      # output name for filtered read
      String bam_filter_above_min_mapq_output_name = output_base_name + ".filtered.above_min_map_quality.bam"
      String bam_filter_below_min_mapq_output_name = output_base_name + ".filtered.below_min_map_quality.bam"

  command <<<
    set -euo pipefail

    

    # filter for a map quality
    # -b output is bam, -h include header, -q reads with mapping quality >=
    samtools view \
      -bhq~{min_map_quality} \
      -U ~{bam_filter_below_min_mapq_output_name} \
      ~{bam_input} > ~{bam_filter_above_min_mapq_output_name}
  >>>

  runtime {
    docker: "quay.io/biocontainers/mulled-v2-03d30cf7bcc23ba5d755e498a98359af8a2cd947:7b1ad5dbd0ee31d66967a1f20b4d8cd630dcec00-0"
    cpu: 4
    
  }

  output {
    File bam_filter_above_min_mapq_output = bam_filter_above_min_mapq_output_name
    File bam_filter_below_min_mapq_output = bam_filter_below_min_mapq_output_name
    
  }
}