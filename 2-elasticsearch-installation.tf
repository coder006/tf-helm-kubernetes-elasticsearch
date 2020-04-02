provider "helm" {
  kubernetes {
    config_path = var.kubeconfig_file_path
  }
  version = "~> 0.10.4"
  service_account = kubernetes_service_account.tiller.metadata[0].name
  install_tiller = true
}

data "helm_repository" "stable" {
  name = "elastic"
  url  = "https://helm.elastic.co"
}

resource helm_release "elasticsearch_master" {
  name       = "elasticsearch-master"
  repository = data.helm_repository.stable.metadata[0].name
  chart      = "elasticsearch"
  version    = "7.6.1"
  timeout    = 900

  values = [
    <<RAW_VALUES
volumeClaimTemplate:
  accessModes: [ "ReadWriteOnce" ]
  storageClassName: "alicloud-disk-ssd"
  resources:
    requests:
      storage: ${var.elasticsearch.master_node.volume_size}Gi
resources:
  requests:
    cpu: ${var.elasticsearch.master_node.cpu}
    memory: ${var.elasticsearch.data_node.memory}Gi
roles:
  master: "true"
  ingest: "false"
  data: "false"
RAW_VALUES
  ]

  set {
    name = "imageTag"
    value = "7.6.2"
  }

  set {
    name = "clusterName"
    value = "elasticsearch-cluster"
  }

  set {
    name = "nodeGroup"
    value = "master"
  }
}

resource helm_release "elasticsearch_data" {
  name       = "elasticsearch-data"
  repository = data.helm_repository.stable.metadata[0].name
  chart      = "elasticsearch"
  version    = "7.6.1"
  timeout    = 900

  values = [
    <<RAW_VALUES
volumeClaimTemplate:
  accessModes: [ "ReadWriteOnce" ]
  storageClassName: "alicloud-disk-ssd"
  resources:
    requests:
      storage: ${var.elasticsearch.data_node.volume_size}Gi
resources:
  requests:
    cpu: ${var.elasticsearch.data_node.cpu}
    memory: ${var.elasticsearch.data_node.memory}Gi
roles:
  master: "false"
  ingest: "true"
  data: "true"
RAW_VALUES
  ]

  set {
    name = "imageTag"
    value = "7.6.2"
  }

  set {
    name = "clusterName"
    value = "elasticsearch-cluster"
  }

  set {
    name = "nodeGroup"
    value = "data"
  }
}