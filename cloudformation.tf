/*************************************************
*               VPC (CLOUDFORMATION)             *
*************************************************/

# Create the CloudFormation stack for our project if not already found
resource "null_resource" "create_cloudformation_stack" {
  provisioner "local-exec" {
    command = <<EOT
      STACK_NAME="${var.project_prefix}${var.vpc_suffix}"
      REGION="${var.aws_region}"

      # Check if the stack exists
      if aws cloudformation describe-stacks --stack-name $STACK_NAME --region $REGION 2>&1 | grep -q 'does not exist'; then

        echo "Stack $STACK_NAME does not exist. Creating stack..."
        aws cloudformation create-stack \
          --stack-name $STACK_NAME \
          --template-url https://s3.us-west-2.amazonaws.com/amazon-eks/cloudformation/2020-10-29/amazon-eks-vpc-private-subnets.yaml \
          --region $REGION

        aws cloudformation wait stack-create-complete --stack-name $STACK_NAME --region $REGION
      else
        echo "Stack $STACK_NAME already exists. Skipping creation."
      fi
    EOT
  }
}