/*************************************************
*               COMPUTE (MONGODB)                *
*************************************************/

# Create EC2 instance for MongoDB
resource "aws_instance" "mongodb" {

  depends_on = [
    aws_eks_cluster.eks,
    aws_s3_bucket.mongodb_backups,
    aws_security_group.mongodb,
    aws_iam_instance_profile.mongodb_instance_profile,
  ]

  ami           = var.aws_ami_id
  key_name      = var.aws_key_name
  instance_type = var.aws_instance_type
  subnet_id     = local.subnet_id

  vpc_security_group_ids = [aws_security_group.mongodb.id]
  iam_instance_profile   = aws_iam_instance_profile.mongodb_instance_profile.name
  
  associate_public_ip_address = true

  tags = {
    Name = "${var.project_prefix}${var.mongodb_suffix}"
  }

  # Define user_data script to install MongoDB and backup script
  user_data = <<-EOF
#!/bin/bash

# Redirect all output to a log file
exec > /var/log/user_data.log 2>&1

# install tools then MongoDB 7.0.x
sudo apt-get update
sudo apt-get install -y wget zip awscli net-tools
wget -qO - https://www.mongodb.org/static/pgp/server-7.0.asc | sudo apt-key add -
sudo echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/7.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list
sudo apt-get update
sudo apt-get install -y mongodb-org

# ensure permissions are set correctly
sudo chown -R mongodb:mongodb /var/lib/mongodb
sudo chmod -R 755 /var/lib/mongodb

# enable service and start
sudo systemctl enable mongod
sudo systemctl start mongod

# Wait for MongoDB to start
sleep 10

# Create admin user and grant access to the database
mongosh admin --eval 'db.createUser({user: "${var.mongodb_user}", pwd: "${var.mongodb_password}", roles: [{role: "root", db: "admin"}]})'

# User created, so now enable authentication
sudo sed -i '/#security:/a\\nsecurity:\n  authorization: "enabled"' /etc/mongod.conf

# make it listen on all interfaces
sudo sed -i 's/bindIp: 127.0.0.1/bindIp: 0.0.0.0/' /etc/mongod.conf

# Restart MongoDB to apply changes
sudo systemctl restart mongod

# Create MongoDB backup to S3 script
cat << 'EOB' > /usr/local/bin/mongodb_backup.sh
#!/bin/bash
TIMESTAMP=$(date +"%F")
BACKUP_DIR="/var/backups/mongodb/$TIMESTAMP"
S3_BUCKET="${local.full_bucket_name}"

mkdir -p $BACKUP_DIR

mongodump --uri="mongodb://${var.mongodb_user}:${var.mongodb_password}@localhost:${var.mongodb_port}/${var.mongodb_database}" --out $BACKUP_DIR

aws s3 cp $BACKUP_DIR s3://$S3_BUCKET/$TIMESTAMP/ --recursive

# also zip and backup the zip
zip -r $BACKUP_DIR_$TIMESTAMP.zip $BACKUP_DIR

aws s3 cp $BACKUP_DIR_$TIMESTAMP.zip s3://$S3_BUCKET/

# Clean up local backups older than 7 days
find /var/backups/mongodb/ -mindepth 1 -mtime +7 -exec rm -rf {} \;
EOB

sudo chmod +x /usr/local/bin/mongodb_backup.sh

# Schedule the backup script to run daily
echo "0 2 * * * root /usr/local/bin/mongodb_backup.sh" > /etc/cron.d/mongodb_backup

echo "MongoDB setup complete!"
EOF
}