version 1.0

# add read group name for support of downstream tools including GATK
task AddReadGroup {
    input {
      File bam_input
      String read_group_library_name
      String read_group_platform_name
      String read_group_platform_unit_name
      String read_group_platform_sample_name
      String output_base_name
      
    }

      # input file size
      Float input_size = size(bam_input, "GB")

      # output name for bam with a read group
      String added_read_group_output_bam_name = output_base_name + ".with_added_read_group.bam"

  command <<<
    set -euo pipefail

  
    gatk  \
    AddOrReplaceReadGroups \
      --INPUT ~{bam_input} \
      --RGLB ~{read_group_library_name} \
      --RGPL ~{read_group_platform_name} \
      --RGPU ~{read_group_platform_unit_name} \
      --RGSM ~{read_group_platform_sample_name} \
      --OUTPUT ~{added_read_group_output_bam_name}
  >>>

  runtime {
    docker: "quay.io/biocontainers/mulled-v2-a4c30dc1a2dfc3f31070c6a8acc1c627f7a22916:5ab2be4575ded1ac8069d0c687af84407210604e-0"
    cpu: 4
    
  }

  output {
    File bam_with_read_group_output = added_read_group_output_bam_name
    
  }
}