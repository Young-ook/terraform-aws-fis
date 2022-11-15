### network/mesh
resource "aws_appmesh_mesh" "mesh" {
  name = var.name
  tags = var.tags
}

resource "aws_appmesh_virtual_node" "vnode" {
  for_each  = var.app
  name      = join("-", [var.name, each.key])
  mesh_name = aws_appmesh_mesh.mesh.name
  tags      = var.tags

  spec {
    listener {
      port_mapping {
        port     = 80
        protocol = "http"
      }
    }
    service_discovery {
      # service discovery to which the virtual node is expected to send inbound traffic.
      dns {
        hostname = lookup(each.value, "load_balancer")
      }
    }
    backend {
      # backends to which the virtual node is expected to send outbound traffic.
      virtual_service {
        virtual_service_name = aws_appmesh_virtual_service.vservice[each.key == "a" ? "b" : "a"].name
      }
    }
    logging {
      access_log {
        file {
          path = "/dev/stdout"
        }
      }
    }
  }
}

resource "aws_appmesh_virtual_service" "vservice" {
  for_each  = var.app
  name      = join("-", [var.name, each.key])
  mesh_name = aws_appmesh_mesh.mesh.name
  tags      = var.tags

  spec {
    provider {
      virtual_router {
        virtual_router_name = aws_appmesh_virtual_router.vrouter[each.key].name
      }
    }
  }
}

resource "aws_appmesh_virtual_router" "vrouter" {
  for_each  = var.app
  name      = join("-", [var.name, each.key])
  mesh_name = aws_appmesh_mesh.mesh.name
  tags      = var.tags

  spec {
    listener {
      port_mapping {
        port     = 80
        protocol = "http"
      }
    }
  }
}

resource "aws_appmesh_route" "route" {
  for_each            = var.app
  name                = join("-", [var.name, each.key])
  mesh_name           = aws_appmesh_mesh.mesh.name
  virtual_router_name = aws_appmesh_virtual_router.vrouter[each.key].name
  tags                = var.tags

  spec {
    http_route {
      match {
        prefix = "/"
      }
      action {
        weighted_target {
          virtual_node = aws_appmesh_virtual_node.vnode[each.key].name
          weight       = 1
        }
      }
    }
  }
}

resource "aws_ssm_document" "envoy" {
  name            = "Install-EnvoyProxy"
  document_format = "YAML"
  document_type   = "Command"
  content         = file(join("/", [path.module, "templates", "envoy.yaml"]))
}

resource "aws_ssm_association" "envoy" {
  for_each         = var.app
  name             = aws_ssm_document.envoy.name
  association_name = join("-", [var.name, each.key, "envoy"])
  parameters = {
    region       = var.aws_region
    mesh         = var.name
    vnode        = join("-", [var.name, each.key])
    envoyVersion = "v1.23.1.0"
    appPort      = "80"
  }
  targets {
    key = "tag:Name"
    values = [
      join("-", [var.name, each.key, "baseline"]),
      join("-", [var.name, each.key, "canary"]),
    ]
  }
}
