# provider "aws" {
#   region = "us-east-2"
# }

# resource "aws_launch_configuration" "example" {
#   image_id        = "ami-0fb653ca2d3203ac1"
#   instance_type   = "t2.micro"
#   security_groups = [aws_security_group.instance.id]

#   user_data = <<-EOF
#           #!/bin/bash
#           echo "Hello, Gulian Technology!" > index.html
#           nohup busybox httpd -f -p ${var.server_port} &
#           EOF
#   # Required when using a launch configuration with an auto scaling group.
#   lifecycle {
#     create_before_destroy = true
#   }
# }

# resource "aws_autoscaling_group" "example" {
#   launch_configuration = aws_launch_configuration.example.name
#   vpc_zone_identifier  = data.aws_subnets.default.ids

#   min_size = 2
#   max_size = 10
#   tag {
#     key                 = "Name"
#     value               = "terraform-asg-example"
#     propagate_at_launch = true
#   }
# }

# resource "aws_security_group" "instance" {
#   name = "terraform-example-instance"
#   ingress {
#     from_port   = var.server_port
#     to_port     = var.server_port
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

# }

# data "aws_vpc" "default" {
#   default = true
# }

# data "aws_subnets" "default" {
#   filter {
#     name   = "vpc-id"
#     values = [data.aws_vpc.default.id]
#   }
# }


provider "aws" {
  region = "us-east-2"
}

# # ---------------------------------------------------------------------------
# # Variable – server port used by the HTTP server and the security group rule
# # ---------------------------------------------------------------------------
# variable "server_port" {
#   description = "The port the web server will listen on"
#   type        = number
#   default     = 8080
# }

# ---------------------------------------------------------------------------
# Launch Template  (replaces the deprecated aws_launch_configuration)
# ---------------------------------------------------------------------------
resource "aws_launch_template" "example" {
  name_prefix   = "terraform-lt-example-"
  image_id      = "ami-0fb653ca2d3203ac1"
  instance_type = "t2.micro"

  vpc_security_group_ids = [aws_security_group.instance.id]

  user_data = base64encode(<<-EOF
    #!/bin/bash
    echo "Hello, Gulian Technology!" > index.html
    nohup busybox httpd -f -p ${var.server_port} &
    EOF
  )

  # Ensures a new template version is created before the old one is destroyed,
  # which is the equivalent of the lifecycle block that was on the launch
  # configuration.
  lifecycle {
    create_before_destroy = true
  }
}

# ---------------------------------------------------------------------------
# Auto Scaling Group
# ---------------------------------------------------------------------------
resource "aws_autoscaling_group" "example" {
  vpc_zone_identifier = data.aws_subnets.default.ids

  min_size = 2
  max_size = 10

  # Launch templates are referenced via a nested block rather than a plain
  # name attribute.
  launch_template {
    id      = aws_launch_template.example.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "terraform-asg-example"
    propagate_at_launch = true
  }
}

# ---------------------------------------------------------------------------
# Security Group
# ---------------------------------------------------------------------------
resource "aws_security_group" "instance" {
  name = "terraform-example-instance"

  ingress {
    from_port   = var.server_port
    to_port     = var.server_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ---------------------------------------------------------------------------
# Data Sources
# ---------------------------------------------------------------------------
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}
