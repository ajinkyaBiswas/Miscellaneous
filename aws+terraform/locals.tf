locals {
  main_vpc_cidr               = "10.0.0.0/16"
  public_subnet_cidr          = "10.0.1.0/24"
  private_subnet_withNAT_cidr = "10.0.2.0/24"
  private_subnet_noNAT_cidr   = "10.0.3.0/24"
}