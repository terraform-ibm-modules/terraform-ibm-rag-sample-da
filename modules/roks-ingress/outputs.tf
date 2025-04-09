output "cluster_workload_ingress_subdomain" {
  description = "Public ingress subdomain"
  value       = local.ingress_subdomain

}

output "cluster_workload_ingress_controller" {
  description = "Ingress controller attributes"
  value       = kubernetes_manifest.workload_ingress
}

output "cluster_workload_ingress_service" {
  description = "Ingress controller service attributes"
  value       = data.kubernetes_service.ingress_router_service
}

output "vpc_public_load_balancer" {
  description = "Public ALB attributes "
  value       = data.ibm_is_lb.ingress_vpc_alb
}

output "vpc_alb_acl" {
  description = "ACL attributes for public ALB"
  value       = data.ibm_is_network_acl.alb_acl
}
