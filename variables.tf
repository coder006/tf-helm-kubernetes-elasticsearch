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
}

variable "kubeconfig_file_path" {
  type = string
  default = "/my/file/path"
}