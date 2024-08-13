variable "vpc_id" {
  type = string
}
variable "cluster_arn" {
  type = string
}
variable "image_url" {
  type = string
}
variable "image_tag" {
  type = string
}
variable "private_subnet_ids" {
  type = list(string)
}
variable "environment" {
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}
variable "secrets" {
  type = list(object({
    name      = string
    valueFrom = string
  }))
  default = []
}
variable "cpu" {
  type    = number
  default = 256
}
variable "memory" {
  type    = number
  default = 512
}
variable "lb_subnet_ids" {
  type = list(string)
}
variable "desired_count" {
  type = number
}
variable "maximum_percent" {
  type = number
}
variable "minimum_healthy_percent" {
  type = number
}
