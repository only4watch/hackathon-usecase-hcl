terraform {
  required_providers {
    kind = {
      source  = "tehcyx/kind"
      version = "0.3.0"
    }
  }
}

provider "kind" {}

resource "kind_cluster" "k8s" {
  name       = var.cluster_name
  node_image = "kindest/node:${var.kubernetes_version}"

  wait_for_ready = true

  kind_config {
    api_version = "kind.x-k8s.io/v1alpha4"
    kind        = "Cluster"

    # Networking block (optional)
    networking {
      api_server_address = "0.0.0.0"
      api_server_port    = 6443
    }

    # Node block
    node {
      role = "control-plane"

      # Extra port mappings FOR INGRESS
      extra_port_mappings {
        container_port = 80
        host_port      = 80
        protocol       = "TCP"
      }

      extra_port_mappings {
        container_port = 443
        host_port      = 443
        protocol       = "TCP"
      }

      # Kubeadm patches
      kubeadm_config_patches = [
        <<EOF
kind: ClusterConfiguration
apiServer:
  extraArgs:
    service-node-port-range: "80-32767"
EOF
      ]
    }
  }
}

output "cluster_name" {
  value = var.cluster_name
}
