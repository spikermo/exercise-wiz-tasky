/*************************************************
*                    NETWORK                     *
*************************************************/

# Waits until the VPC's subnets are fully available
resource "null_resource" "wait_for_subnets" {
  provisioner "local-exec" {
    command = <<EOT
      while true; do
        PUBLIC_SUBNET_ID=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=${var.project_prefix}${var.vpc_suffix}-PublicSubnet01" --query "Subnets[0].SubnetId" --output text)
        PRIVATE_SUBNET_ID=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=${var.project_prefix}${var.vpc_suffix}-PrivateSubnet02" --query "Subnets[0].SubnetId" --output text)
        
        if [ "$PUBLIC_SUBNET_ID" != "None" ] && [ "$PRIVATE_SUBNET_ID" != "None" ]; then
          echo "All resources found: PublicSubnet01=$PUBLIC_SUBNET_ID, PrivateSubnet02=$PRIVATE_SUBNET_ID"
          break
        else
          echo "Waiting for VPC resources to be available..."
          sleep 10
        fi
      done
    EOT
  }
}

# get my personal IP address
data "external" "my_ip" {
  program = ["bash", "-c", "printf '{\"ip\": \"%s\"}\n' \"$(curl -s -4 https://checkip.amazonaws.com)\""]
}

# Creates MongoDB Security Group
resource "aws_security_group" "mongodb" {
  depends_on = [null_resource.wait_for_subnets]

  name        = local.mongodb_sg_name
  vpc_id      = local.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${data.external.my_ip.result.ip}/32"] # My IP
  }

  ingress {
    from_port   = var.mongodb_port
    to_port     = var.mongodb_port
    protocol    = "tcp"
    cidr_blocks = [
      "${data.external.my_ip.result.ip}/32", # My IP
      local.vpc_cidr_block
    ]
  }

  # Allow inbound traffic from the EKS security group
  ingress {
    from_port       = var.mongodb_port
    to_port         = var.mongodb_port
    protocol        = "tcp"
    security_groups = [local.eks_sg_id]
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}