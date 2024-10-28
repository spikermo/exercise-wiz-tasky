/*************************************************
*                    APP (TASKY)                 *
*************************************************/

# Build the Docker image whenever the custom Dockerfile is updated
resource "null_resource" "build_app" {
  depends_on = [aws_ecr_repository.app_repository]

  triggers = {
    dockerfile_checksum = filemd5("${path.module}/${var.app_dockerfile}")
  }

  # build using my overridden Dockerfile
  provisioner "local-exec" {
    command = <<EOT
      # copy in custom Dockerfile to submodule
      cp -f ${var.app_dockerfile} tasky/
      cd tasky/

      docker build -t ${var.project_prefix}-${var.app_name} -f ${var.app_dockerfile} .

      # clean up my custom Dockerfile from the submodule
      rm -f ${var.app_dockerfile}
      cd ..
    EOT
  }
}

# Push to ECR every run to make sure we're current
resource "null_resource" "push_app" {
  depends_on = [null_resource.build_app]

  triggers = {
    always = timestamp()
  }

  # Build, tag, and push the latest Docker image to ECR
  provisioner "local-exec" {
    command = <<EOT
      # working directory
      cd tasky
      
      # Create the ECR repository (or fail silently if already exists)
      aws ecr create-repository --repository-name ${aws_ecr_repository.app_repository.name} > /dev/null 2>&1 || true

      # Log in to ECR
      aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${var.docker_server}

      # Tag the image as latest
      docker tag ${local.short_app_name}:latest ${local.full_app_uri}

      # Build a multi-platform image and push
      docker buildx build --platform linux/amd64,linux/arm64 -t ${local.full_app_uri} --push --quiet .

      cd ..
    EOT
  }
}

# References Kubernetes templates for app deployment
locals {
  # Get all .tpl files in the kubernetes directory
  app_template_files = fileset("${path.module}/kubernetes", "*.tpl")
}

# Updates Kubernetes templates
resource "local_file" "kubernetes_templates" {
  depends_on = [
    aws_eks_cluster.eks,
    aws_instance.mongodb,
    aws_ecr_repository.app_repository,
    null_resource.push_app
  ]

  for_each = { for file in local.app_template_files : file => file }

  # Renders the template file and replaces the specified variables
  content = templatefile("${path.module}/kubernetes/${each.value}", {
    PROJECT_PREFIX = var.project_prefix,
    APP_NAME       = var.app_name,
    APP_IMAGE      = local.full_app_uri,
    MONGODB_URI    = local.mongodb_uri
  })

  # Output to filename without the .tpl extension
  filename = "${path.module}/kubernetes/${replace(each.value, ".tpl", "")}"
}

# Updates Kubernetes configurations
resource "null_resource" "manage_kubernetes" {
  depends_on = [
    local_file.kubernetes_templates,
    null_resource.push_app
  ]

  triggers = {
    always = timestamp(),
  }

  # Update Kubernetes config and applies changes
  provisioner "local-exec" {
    command = <<EOT
      # Update kubeconfig
      aws eks update-kubeconfig --region ${var.aws_region} --name ${local.cluster_name}

      # Grab ECR login and update it as a Kubernetes docker-registry secret
      aws ecr get-login-password --region ${var.aws_region} \
        | kubectl create secret docker-registry ecr-registry-secret \
        --docker-server=${var.docker_server} --docker-username=AWS \
        --docker-password=$(aws ecr get-login-password --region ${var.aws_region}) --dry-run=client -o yaml \
        | kubectl apply -f -

      # Apply Kubernetes configuration
      kubectl apply -f ${path.module}/kubernetes/

      # Update containers
      kubectl rollout restart deployment ${var.project_prefix}-${var.app_name}

      # Delete any empty (0) replicasets that may be left over 
      kubectl get rs --no-headers | awk '$2 == 0 {print $1}' | xargs kubectl delete rs
    EOT
  }
}

# Create the ECR repository for the app
resource "aws_ecr_repository" "app_repository" {
  depends_on = [aws_eks_cluster.eks]

  name = "${var.project_prefix}-${var.app_name}"

  # Automatically check images for vulnerabilities
  image_scanning_configuration {
    scan_on_push = true
  }

  # Enable force delete to remove all images when the repository is destroyed
  force_delete = true
}
  
# Set the repository's lifecycle policy for 30 day expiration
resource "aws_ecr_lifecycle_policy" "app_repository_lifecycle_policy" {
  depends_on = [aws_ecr_repository.app_repository]

  repository = aws_ecr_repository.app_repository.name

  policy = <<EOF
  {
    "rules": [
      {
        "rulePriority": 1,
        "description": "Expire untagged images older than 30 days",
        "selection": {
          "tagStatus": "untagged",
          "countType": "sinceImagePushed",
          "countUnit": "days",
          "countNumber": 30
        },
        "action": {
          "type": "expire"
        }
      }
    ]
  }
  EOF
}