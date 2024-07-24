version 1.0

# create a ALLC from VCF 
task VCFtoALLC {
    input {
      File methylation_vcf_output_name
      
    }

  # input file size

  # output name for VCF and its index
  String methylation_allc_output_name = sub(basename(methylation_vcf_output_name), ".vcf$", ".allc")

  command <<<
    set -euo pipefail

    python3 /tools/convert-vcf-to-allc.py -i ~{methylation_vcf_output_name} -o ~{methylation_allc_output_name}
  >>>

  runtime {
    docker: "quay.io/humancellatlas/vcftoallc:v0.0.1"
    cpu: 4
  
  }

  output {
    File methylation_allc = methylation_allc_output_name
  }
}