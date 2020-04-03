> ___Note___:
> This guide uses Terraform for making API calls and state management. If you have helm installed on your machine, you can use that instead for installing the chart.

## What is Elasticsearch?

According to the Elasticsearch website:
> Elasticsearch is a distributed, open source search and analytics engine for all types of data, including textual, numerical, geospatial, structured, and unstructured.

Elasticsearch is generally used as the underlying engine for platforms that perform complex text search, logging, or real-time advanced analytics operations. The ELK stack (Elasticsearch, Logstash, and Kibana) has also become the de facto standard when it comes to logging and it's visualization in container environments.

## Architecture

Before we move forward, let us take a look at the basic architecture of Elasticsearch:

![Elasticsearch Nodes](https://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/images/za-2-az.png "Elasticsearch Cluster")

The above is an overview of a basic __Elasticsearch Cluster__. As you can see, the cluster is divided into several nodes. A __node__ is a server (physical or virtual) that stores some data and is a part of the elasticsearch cluster. A __cluster__, on the other hand, is a collection of several nodes that together form the cluster. Every node in turn can hold multiple shards from one or multiple indices. Different kinds of nodes available in Elasticsearch are _Master-eligible node_, _Data node_, _Ingest node_, and _Machine learning node_(Not availble in the OSS version). In this article, we will only be looking at the master and data nodes for the sake of simplicity.

### Master-eligible node

A node that has `node.master` flag set to `true`, which makes it eligible to be elected as the _master node_ which controls the cluster. One of the _master-eligible_ nodes is elected as the __Master__ via the [master election process](https://www.elastic.co/guide/en/elasticsearch/reference/current/modules-discovery.html). Following are few of the functions performed by the _master node_:

- Creating or deleting an index
- Tracking which nodes are part of the cluster
- Deciding which shards to allocate to which nodes

### Data node
A node that has `node.data` flag set to `true`. Data nodes hold the shards that contain the documents you have indexed. These nodes perform several operations that are IO, memory, and CPU extensive in nature. Some of the functions performed by _data nodes_ are:

- Data related operations like CRUD
- Search
- Aggregations

---

Terminology
-----------
Now that we have a basic idea about the Elasticsearch Architecture, let us see how to Elasticsearch inside a Kubernetes Cluster using Helm and Terraform. Before moving forward, let us go through some basic terminology.

__Kubernetes__: Kubernetes is a portable, extensible, open-source platform for managing containerized workloads and services, that facilitates both declarative configuration and automation

__Helm__: Helm is an application package manager running atop Kubernetes. It allows describing the application structure through convenient helm-charts and managing it with simple commands

__Terraform__: Terraform is a tool for building, changing, and versioning infrastructure safely and efficiently. Terraform can manage existing and popular service providers as well as custom in-house solutions

---

Installation
------------

First, let us describe the variables and the default values needed for setting up the Elasticsearch Cluster:

### Default Values:
```hcl
variable "elasticsearch" {
  type = object({
    master_node = object({
      volume_size   = number
      cpu           = number
      memory        = number
    })

    data_node = object({
      volume_size   = number
      cpu           = number
      memory        = number
    })
  })

  default = {
    master_node = {
      volume_size   = 20
      cpu           = 1
      memory        = 1.5
    }
    
    data_node = {
      volume_size   = 20
      cpu           = 1
      memory        = 1.5
    }
  }
}

variable "kubeconfig_file_path" {
  type      = string
  default   = "/my/file/path"
}
```

> For the sake of simplicity, I will assume that you have a working helm installtion. Although, you can still go over to the [Github Repository](https://github.com/coder006/tf-helm-kubernetes-elasticsearch.git) to take a look at how to install helm and tiller onto your Kubernetes cluster using Terraform.

### Terraform Helm Setup

This step involves declaring a helm provider and the elasticsearch helm repository to pull the helm chart from

```hcl
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
```

### Setting up Master Eligible and Data nodes

Let us take a look at some of the important fields used in the following helm release resources:

- `clusterName` - This refers to the name of the elasticsearch cluster and has the default value of `elasticsearch`. Because elasticsearch looks at the cluster name when joining a new node, it is better to set the value of this field to something else.
- `nodeGroup` - This tells the elasticsearch helm chart whether the node is a master eligible node or a data node
- `storageClassName` - The kubernetes storage class that you want to use for provisioning the attached volumes. You can skip this field if your cloud provider has a default storageclass object defined
- `cpu`: The number of CPU cores you want to give to the elasticsearch pod
- `memory`: The amount of memory you want to allocate to the elasticsearch pod

#### Master Eligible Nodes
```hcl
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
  storageClassName: "my-storage-class"
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
    name  = "imageTag"
    value = "7.6.2"
  }

  set {
    name  = "clusterName"
    value = "elasticsearch-cluster"
  }

  set {
    name  = "nodeGroup"
    value = "master"
  }
}
```

#### Data Nodes

```hcl
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
  storageClassName: "my-storage-class"
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
    name  = "imageTag"
    value = "7.6.2"
  }

  set {
    name  = "clusterName"
    value = "elasticsearch-cluster"
  }

  set {
    name  = "nodeGroup"
    value = "data"
  }
}
```

Happy Coding! Cheers :)