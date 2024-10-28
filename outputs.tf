/*************************************************
*                    OUTPUTS                     *
*************************************************/

output "networking_vpc_id" {
  value = local.vpc_id # i.e. vpc-0a3d7d5d30a45f5eb
}

output "networking_vpc_cidr_block" {
  value = data.aws_vpc.selected.cidr_block # i.e. 192.168.0.0/16
}
output "networking_subnet_id" {
  value = local.subnet_id # i.e. subnet-0e86e5f9d06cac9dd
}

output "networking_eks_sg_id" {
  value = local.eks_sg_id # i.e. "sg-01a119210a48490cb"
}

output "networking_mongodb_sg_name" {
  value = local.mongodb_sg_name # i.e. ronniemoore-wiz-mongodb-sg
}

output "networking_my_public_ip" {
  value = data.external.my_ip.result.ip
}

output "mongodb_s3_bucket_uri" {
  value = "http://${aws_s3_bucket.mongodb_backups.bucket}.s3.${var.aws_region}.amazonaws.com"
  # http://ronniemoore-wiz-mongodb-backups-bucket.s3.us-east-1.amazonaws.com
}

output "mongodb_private_ip" {
  value = aws_instance.mongodb.private_ip # i.e. 192.168.30.234
}

output "mongodb_public_ip" {
  value = aws_instance.mongodb.public_ip #i.e.  3.92.136.28
}

output "mongodb_uri" {
  value = local.mongodb_uri # i.e. mongodb://adminUser:securePassword@192.168.30.234:27017/admin
}

output "tasky_ecr_server" {
  value = var.docker_server # i.e. "110299713907.dkr.ecr.us-east-1.amazonaws.com"
}

/*************************************************
*                   COMMANDS                     *
*************************************************/

output "command_app_frontend" {
  value = <<EOF

  echo "http://$(kubectl get service ${var.project_prefix}-${var.app_name} -o jsonpath='{.status.loadBalancer.ingress[0].hostname}{"\n"}')"
  EOF
}
output "command_ecr_update" {
  value = <<EOF

aws ecr get-login-password --region ${var.aws_region} | \
kubectl create secret docker-registry ecr-registry-secret \
  --docker-server=${var.docker_server} \
  --docker-username=AWS \
  --docker-password=$(aws ecr get-login-password --region us-east-1) --dry-run=client -o yaml | kubectl apply -f -
  EOF
}

output "command_mongodb_ssh" {
  value = <<EOF

  ssh -o StrictHostKeyChecking=no -i ~/Dropbox/${var.aws_key_name}.pem ubuntu@$(terraform output -raw mongodb_public_ip)
  EOF
}

output "command_update_kubeconfig" {
  value = <<EOF

  aws eks update-kubeconfig --name ${var.project_prefix}${var.cluster_label}
  EOF
}
