### output variables

output "mesh" {
  description = "Attributes of the service mesh"
  value       = aws_appmesh_mesh.mesh
}

output "virtual_node" {
  description = "Attributes of the virtual nodes"
  value       = aws_appmesh_virtual_node.vnode
}

output "virtual_service" {
  description = "Attributes of the virtual services"
  value       = aws_appmesh_virtual_service.vservice
}

output "virtual_router" {
  description = "Attributes of the virtual routers"
  value       = aws_appmesh_virtual_router.vrouter
}

