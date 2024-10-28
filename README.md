```
Outputs:

command_app_frontend = <<EOT

  echo "http://$(kubectl get service ronniemoore-wiz-tasky -o jsonpath='{.status.loadBalancer.ingress[0].hostname}{"\n"}')"

EOT
command_ecr_update = <<EOT

aws ecr get-login-password --region us-east-1 | \
kubectl create secret docker-registry ecr-registry-secret \
  --docker-server=110299713907.dkr.ecr.us-east-1.amazonaws.com \
  --docker-username=AWS \
  --docker-password=$(aws ecr get-login-password --region us-east-1) --dry-run=client -o yaml | kubectl apply -f -

EOT
command_mongodb_ssh = <<EOT

  ssh -o StrictHostKeyChecking=no -i ~/Dropbox/aws-ec2-ronniemoore.pem ubuntu@$(terraform output -raw mongodb_public_ip)

EOT
command_update_kubeconfig = <<EOT

  aws eks update-kubeconfig --name ronniemoore-wiz-cluster

EOT
mongodb_private_ip = "192.168.2.112"
mongodb_public_ip = "54.208.189.49"
mongodb_s3_bucket_uri = "http://ronniemoore-wiz-mongodb-backups.s3.us-east-1.amazonaws.com"
mongodb_uri = "mongodb://adminUser:securePassword@192.168.2.112:27017/admin"
networking_eks_sg_id = "sg-04d3917d003c68687"
networking_mongodb_sg_name = "ronniemoore-wiz-mongodb-sg"
networking_my_public_ip = "207.242.49.130"
networking_subnet_id = "subnet-027288822f9848f95"
networking_vpc_cidr_block = "192.168.0.0/16"
networking_vpc_id = "vpc-0ab9fb04333085b2e"
tasky_ecr_server = "110299713907.dkr.ecr.us-east-1.amazonaws.com"
```
