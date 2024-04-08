provider "aws"{
    region = "ap-south-1"
    access_key = "AKIAQ3EGP5DFPFEJ444U"
    secret_key = "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"

}

#  VPC

resource "aws_vpc" "NewVPC"{
    cidr_block = "10.0.0.0/16"
    tags = {
        Name = "Terraform VPC"

    }
}

# SUBNET 1

resource "aws_subnet" "Subnet1"{
    vpc_id = aws_vpc.NewVPC.id
    cidr_block = var.prefix_cidr
    availability_zone = "ap-south-1a"
    tags = {
        Name = "Terraform Subnet 1"

    }
}

#IGW

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.NewVPC.id
  tags = {
        Name = "Terraform IGW"

    }

}

# ROUTE TABLE

resource "aws_route_table" "terraform_Route_Table" {
  vpc_id = aws_vpc.NewVPC.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = {
    Name = "Terraform-Route Table"
  }
}

# ROUTE TABLE ASSOCIATION

resource "aws_route_table_association" "Terraform_RT_Acc" {
  subnet_id      = aws_subnet.Subnet1.id
  route_table_id = aws_route_table.terraform_Route_Table.id
}

# OUTPUT
output "details-instance" {
  value       = aws_eip.EIP.public_ip
}


# SECURITY GROUP

resource "aws_security_group" "TerraformSecurityGroup" {
  vpc_id = aws_vpc.NewVPC.id
  name = "allow_web_traffic"
  description = "allowing web traffic"

  ingress {
    protocol  = "tcp"
    from_port = 443
    to_port   = 443
    description = "HTTPS"
    cidr_blocks = ["0.0.0.0/0"]
    
  }

  ingress {
    protocol  = "tcp"
    from_port = 80
    to_port   = 80
    description = "HTTP"
    cidr_blocks = ["0.0.0.0/0"]
    
  }

  ingress {
    protocol  = "tcp"
    from_port = 22
    to_port   = 22
    description = "SSH"
    cidr_blocks = ["0.0.0.0/0"]
    
  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "Allow all"
  }
}

# Network Interface

resource "aws_network_interface" "TerraformWebServer" {
  subnet_id       = aws_subnet.Subnet1.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.TerraformSecurityGroup.id]
  
}

# EIP

resource "aws_eip" "EIP" {
  domain = "vpc"  
  network_interface = aws_network_interface.TerraformWebServer.id
  associate_with_private_ip ="10.0.1.50"
  depends_on = [aws_internet_gateway.gw]
}

#resource Instance Ubuntu

resource "aws_instance" "terraform_ec" {
    ami = "ami-09298640a92b2d12c"
    instance_type = "t2.micro"
    availability_zone = "ap-south-1a"
    key_name = "key1"

    network_interface {
        device_index = 0
        network_interface_id = aws_network_interface.TerraformWebServer.id
    }
    tags = {
        Name = "Linux-Instance"
    }
    user_data =<<-EOF
    #!/bin/bash
    sudo yum update -y
    sudo yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
    sudo systemctl start amazon-ssm-agent
    sudo systemctl enable amazon-ssm-agent
    EOF
}

variable prefix_cidr {
  type        = string
  #default     = "10.0.1.0/24"
  description = "cidr block"
}
