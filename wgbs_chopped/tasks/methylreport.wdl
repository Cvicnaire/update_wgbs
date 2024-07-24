version 1.0 

# produce methylation report using bisamrk's methyation extractor
task GetMethylationReport {
    input {
      File bam_input
      String output_base_name
      
    }

  # input file size
  Float input_size = size(bam_input, "GB")

  # output name for reports
  String methylation_report_basename = basename(bam_input, ".bam")

  String methylation_mbias_report_bismark_name = methylation_report_basename + ".M-bias.txt"
  String methylation_mbias_report_output_name = output_base_name + ".Mbias_report.txt"

  String methylation_splitting_report_bismark_name = methylation_report_basename + "_splitting_report.txt"
  String methylation_splitting_report_output_name = output_base_name + ".splitting_report.txt"

  String methylation_CpG_context_report_bismark_name = "CpG_context_" + methylation_report_basename + ".txt"
  String methylation_CpG_context_report_output_name = output_base_name + ".CpG_context_report.txt"

  String methylation_non_CpG_context_report_bismark_name = "Non_CpG_context_" + methylation_report_basename + ".txt"
  String methylation_non_CpG_context_report_output_name = output_base_name + ".non_CpG_context_report.txt"



  command <<<
    set -euo pipefail

    cpan GD::Graph::lines\

    # get methylation report using Bismark
      bismark_methylation_extractor \
      --comprehensive \
      --merge_non_CpG \
      --report \
      ~{bam_input}

    # rename outputs
    mv ~{methylation_mbias_report_bismark_name} ~{methylation_mbias_report_output_name}
    mv ~{methylation_splitting_report_bismark_name} ~{methylation_splitting_report_output_name}
    mv ~{methylation_CpG_context_report_bismark_name} ~{methylation_CpG_context_report_output_name}
    mv ~{methylation_non_CpG_context_report_bismark_name} ~{methylation_non_CpG_context_report_output_name}

  runtime {
    docker: "quay.io/biocontainers/bismark:0.24.2--hdfd78af_0"
    cpu: 4
    
  }

  output {
    File methylation_mbias_report_output = methylation_mbias_report_output_name
    File methylation_splitting_report_output = methylation_splitting_report_output_name
    File methylation_CpG_context_report_output = methylation_CpG_context_report_output_name
    File methylation_non_CpG_context_report_output = methylation_non_CpG_context_report_output_name
    
  }
}