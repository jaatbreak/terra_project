provider "aws" {
    region = "ap-south-1"
}

## creating the vpc 

resource "aws_vpc" "aman-vpc" {
    cidr_block = "192.168.0.0/24"
    tags = {
        "Name" = "aman-vpc"
    }
}
## creating the subnets :-
resource "aws_subnet" "sunet-1" {
    vpc_id = aws_vpc.aman-vpc.id
    availability_zone = "ap-south-1a"
    cidr_block = "192.168.0.0/25"
    map_public_ip_on_launch = true
    tags = {
      "Name" = "subnet-1"
    }
}
##creating internet gatways :-
resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.aman-vpc.id
    tags = {
        "Name" = "igw"
    }
}

##creating the routing table :-
resource "aws_route_table" "route-1" {
    vpc_id = aws_vpc.aman-vpc.id
    route  {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.igw.id
    }
    tags = {
      "Name" = "route-1"
    } 
}

## Associate route table ;-
resource "aws_route_table_association" "as-1" {
    route_table_id = aws_route_table.route-1.id
    subnet_id = aws_subnet.sunet-1.id
  
}
## creating the security group :-
resource "aws_security_group" "security" {
    vpc_id = aws_vpc.aman-vpc.id
    tags = {
        "Name" = "security"
    }
    ingress  {
        description = "inbound"
        from_port = 22
        to_port = 22
        protocol = "TCP"
        self = true
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress  {
        description = "inbound"
        from_port = 80
        to_port = 80
        protocol = "TCP"
        self = true
        cidr_blocks = ["0.0.0.0/0"]
    }

    
    egress {
        description = "outbound"
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    } 
}    
  

##creating the instance :-
resource "aws_instance" "new_intance" {
    ami = "ami-0f5ee92e2d63afc18"
    instance_type = "t2.micro"
    key_name = "mumbai1.key"
    availability_zone = "ap-south-1a"
    vpc_security_group_ids = [aws_security_group.security.id]
    subnet_id = aws_subnet.sunet-1.id
    tags = {
        "Name" = "webserver"
    }
    connection {
      type = "ssh"
      user = "ubuntu"
      private_key = "${file("mumbai1.key.pem")}"
      host = self.public_ip
    }
    provisioner "remote-exec" {
        inline = [ 
            "sudo apt update  ",
            "sudo apt install -y docker.io",
            "sudo systemctl start docker",
            "sudo systemctl enable docker",
        ]
    }
    provisioner "file" {
        source = "./Dockerfile"
        destination = "/home/ubuntu/Dockerfile"
      
    }
    provisioner "remote-exec" {
        inline = [ 
            "sudo docker login -u ${var.docker_user} -p ${var.docker_pass}",
            "sudo docker pull amansingh12/shopping_page",
            "sudo docker run -dit --name vm -p 80:80 amansingh12/shopping_page",
            "sleep 10",
            "sudo docker build -t sports .",
            "sudo docker tag sports:latest amansingh12/update_terra_sport",
            "sudo docker push amansingh12/update_terra_sport ",
         ]
      
    }
    
   
}

