variable "main_vpc_cidr" {
  default     = "10.0.0.0/16"
  description = "main vpc cidr"
}

variable "myIP" {
  default     = "x.x.x.x/32"
  description = "This is my IP"
}

variable "hackerIPs" {
  default     = ["y.y.y.y/32", "z.z.z.z/32"]
  description = "hackers to block"
}

variable "myFriendIPs" {
  default     = ["a.a.a.a/32", "b.b.b.b/32"]
  description = "my friends IPs I want to allow"
}