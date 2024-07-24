version 1.0

# create a VCF contain locus methylation information
task MethylationTypeCaller {
    input {
      File bam_input
      File reference_fasta
      File reference_fasta_index
      File reference_dictionary
      String output_base_name
      
    }

  # input file size
  Float input_size = size(bam_input, "GB") +
                      size(reference_fasta, "GB") +
                      size(reference_fasta_index, "GB") +
                      size(reference_dictionary, "GB")

  # output name for VCF and its index
  String methylation_vcf_output_name = output_base_name + ".vcf"
  String methylation_vcf_index_output_name = methylation_vcf_output_name + ".idx"

  command <<<
    set -euo pipefail

   
    gatk MethylationTypeCaller \
      --input ~{bam_input} \
      --reference ~{reference_fasta} \
      --output ~{methylation_vcf_output_name} \
      --create-output-variant-index 
  >>>

  runtime {
    docker: "quay.io/biocontainers/mulled-v2-a4c30dc1a2dfc3f31070c6a8acc1c627f7a22916:5ab2be4575ded1ac8069d0c687af84407210604e-0"
    cpu: 4
    
  }

  output {
    File methylation_vcf = methylation_vcf_output_name
    File methylation_vcf_index = methylation_vcf_index_output_name
   
  }
}