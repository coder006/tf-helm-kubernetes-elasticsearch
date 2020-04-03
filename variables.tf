variable "elasticsearch" {
  type = object({
    master_node = object({
      volume_size = number
      cpu = number
      memory = number
    })

    data_node = object({
      volume_size = number
      cpu = number
      memory = number
    })
  })

  default = {
    master_node = {
      volume_size = 20
      cpu = 1
      memory = 1.5
    }

    data_node = {
      volume_size = 20
      cpu = 1
      memory = 1.5
    }
  }
}

variable "kubeconfig_file_path" {
  type = string
  default = "/my/file/path"
}