variable "prefix" {
  description = "Prefix for resources to be created. To not use any prefix value, you can set this value to `null` or an empty string."
  type        = string
  nullable    = true
}

variable "cluster_name" {
  description = "Cluster name"
  type        = string
}

# Need to have the count of zones to determine how many rules to add to the ACL for public ingress
variable "cluster_zone_count" {
  description = "Number of zones the cluster nodes are deployed in"
  type        = number
  default     = 2
}

variable "public_ingress_controller_name" {
  description = "Name for the ingress controller to be created"
  type        = string
  default     = "ingress-public"
}

variable "public_ingress_selector_label" {
  description = "Value for ingress label to select routes admitted to public ingress"
  type        = string
  default     = "ingress-public"
}

variable "sensitive_tokendata" {
  description = "IAM access token (with the Bearer prefix) used for the Kubernetes Service API calls"
  type        = string
  sensitive   = true
}

variable "ibmcloud_api_key" {
  description = "API key used by the NLB DNS lifecycle script to get an IAM token"
  type        = string
  sensitive   = true
}
