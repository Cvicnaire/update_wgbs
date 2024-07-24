version 1.0

workflow BuildCembaReferences {
  input {
    File reference_fasta
    
  }

  String pipeline_version = "1.0.0"

  call BuildBisulfiteReferences as Convert {
    input:
      fasta_input = reference_fasta
      
  }

  call Bowtie2Build as IndexForward {
    input:
      fasta_input = Convert.fwd_converted_reference_fasta_output,
      index_prefix = "BS_CT"
      
  }

  call Bowtie2Build as IndexReverse {
    input:
      fasta_input = Convert.rev_converted_reference_fasta_output,
      index_prefix = "BS_GA"
      
  }

  call CreateReferenceDictionary {
    input:
      reference_fasta = reference_fasta
     
  }

  call CreateReferenceFastaIndex {
    input:
      reference_fasta = reference_fasta
      
  }

  output {
    File reference_fasta_dict = CreateReferenceDictionary.ref_dict_output
    File reference_fasta_index = CreateReferenceFastaIndex.ref_index_output
    File fwd_converted_reference_fasta = Convert.fwd_converted_reference_fasta_output
    File rev_converted_reference_fasta = Convert.rev_converted_reference_fasta_output
    Array[File] fwd_bowtie2_index_files = IndexForward.bowtie2_index_files
    Array[File] rev_bowtie2_index_files = IndexReverse.bowtie2_index_files
  }
}

task BuildBisulfiteReferences {
  input {
    File fasta_input
    

  Float input_size = size(fasta_input, "GB")

  String fwd_converted_reference_fasta_output_name = "genome_mfa.CT_conversion.fa"
  String rev_converted_reference_fasta_output_name = "genome_mfa.GA_conversion.fa"
  }
  command <<<
   
    python3 /projectnb/bubhub/users/camv/workflows/cemba/build_cemba_references/build_bisulfite_references.py \
      --input-fasta ~{fasta_input} \
      --forward-convert-out ~{fwd_converted_reference_fasta_output_name} \
      --reverse-convert-out ~{rev_converted_reference_fasta_output_name}

  >>>

  runtime {
    docker: "quay.io/biocontainers/adpred:1.2.8--pyhdfd78af_0"
    cpu: 16
  }

  output {
    File fwd_converted_reference_fasta_output = fwd_converted_reference_fasta_output_name
    File rev_converted_reference_fasta_output = rev_converted_reference_fasta_output_name
    
  }
}

task Bowtie2Build {
  input {
    File fasta_input
    String index_prefix
    
  }

  Float input_size = size(fasta_input, "GB")

  command <<<
    bowtie2-build -f ~{fasta_input} ~{index_prefix}
  >>>

  runtime {
    docker: "quay.io/biocontainers/bowtie2:2.5.4--he20e202_2"
    cpu: 16
  }

  output {
    Array[File] bowtie2_index_files = glob("~{index_prefix}*")
    
  }
}

task CreateReferenceDictionary {
  input {
    File reference_fasta
    
  }

  Float input_size = size(reference_fasta, "GB")

  String ref_dict_output_name = basename(reference_fasta, ".fa") + ".dict"

  command <<<
    set -euo pipefail

    picard CreateSequenceDictionary \
      REFERENCE=~{reference_fasta} \
      OUTPUT=~{ref_dict_output_name}
  >>>
  #picard image
  runtime {
    docker: "quay.io/biocontainers/mulled-v2-23d9f7c700e78129a769e78521eb86d6b8341923:8dde04faba6c9ac93fae7e846af3bafd2c331b3b-0"
    cpu: 16
  }

  output {
    File ref_dict_output = ref_dict_output_name
    
  }
}

task CreateReferenceFastaIndex {
  input {
    File reference_fasta
   
  }

  Float input_size = size(reference_fasta, "GB")

  String ref_index_output_name = basename(reference_fasta) + ".fai"

  command <<<
    set -euo pipefail

    cp ~{reference_fasta} fasta_temp.fa

    samtools faidx fasta_temp.fa

    mv fasta_temp.fa.fai ~{ref_index_output_name}
  >>>

  runtime {
    docker: "quay.io/biocontainers/mulled-v2-03d30cf7bcc23ba5d755e498a98359af8a2cd947:7b1ad5dbd0ee31d66967a1f20b4d8cd630dcec00-0"
    cpu: 16
  }

  output {
    File ref_index_output = ref_index_output_name
    
  }
}
