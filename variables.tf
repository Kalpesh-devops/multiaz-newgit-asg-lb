variable "cidr-vpc" {


}

//variable for subnets

variable "az-subnets" {
  type    = list(string)
  default = ["ap-south-1a", "ap-south-1b"]


}