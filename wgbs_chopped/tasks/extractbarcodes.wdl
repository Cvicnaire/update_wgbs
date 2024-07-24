 version 1.0
 
 task ExtractCellBarcodes {
    input {
      # read 1 when with adapter sequences trimmed off
      File fastq_input
      File unmapped_bam_input
      File? barcode_white_list
      Int barcode_start_pos
      Int barcode_length
      String output_base_name
      
    }

      # input file size
      Float input_size = size(fastq_input, "GB") + (if defined(barcode_white_list) then size(barcode_white_list, "GB") else 0)

      # output names for read1 bam with extracted barcodes
      String tagged_unmapped_bam_output_name = output_base_name + ".tagged_unmapped.bam"

  command <<<
    set -euo pipefail


    # extract barcode and tag them to the unmapped bam
    AttachBarcodes \
      --r1 ~{fastq_input} \
      --u2 ~{unmapped_bam_input} \
      --cell-barcode-start-position ~{barcode_start_pos} \
      --cell-barcode-length ~{barcode_length} \
      ~{true="--whitelist" false="" defined(barcode_white_list)} ~{barcode_white_list} \
      --output-bamfile ~{tagged_unmapped_bam_output_name}
  >>>

  # use docker image for given tool sctools
  runtime {
    docker: "quay.io/biocontainers/sctools:1.0.0--hd03093a_3"
    cpu: 4
    
  }

  output {
    File tagged_unmapped_bam_output = tagged_unmapped_bam_output_name
    
  }
}