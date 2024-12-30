# Output the VPC details and ig nat gateway 
output "vpc_details_result" {
  value = {
    vpc_id                = aws_vpc.my_vpc.id
    cidr_block            = aws_vpc.my_vpc.cidr_block
    enable_dns_support    = aws_vpc.my_vpc.enable_dns_support
    enable_dns_hostnames  = aws_vpc.my_vpc.enable_dns_hostnames
    igw_id                = aws_internet_gateway.my_igw.id
    nat_gateway_id        = aws_nat_gateway.my_nat_gateway.id
  }

  description = "Details of the created VPC"
}
