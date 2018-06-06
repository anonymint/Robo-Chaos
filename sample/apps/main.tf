data "aws_ami" "image" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-2017.12.0.2018*"]
  }

  # owners = [""]
}

data "aws_subnet_ids" "aws_subnets" {
  vpc_id = "${var.aws_vpc_id}"
}

data "aws_subnet" "subnet" {
  count = "${length(data.aws_subnet_ids.aws_subnets.ids)}"
  id    = "${data.aws_subnet_ids.aws_subnets.ids[count.index]}"
}

data "aws_security_group" "security_default_group" {
  filter {
    name   = "group-name"
    values = ["default"]
  }
}

#
# IAM and Role
#

resource "aws_iam_instance_profile" "chaos_apps_profile" {
  name = "chaos_apps_role"
  role = "${aws_iam_role.chaos_apps_role.name}"
}

resource "aws_iam_role" "chaos_apps_role" {
  name = "chaos_apps_role"
  path = "/sre/"

  assume_role_policy = <<EOF
{
      "Version": "2012-10-17",
      "Statement": [
        {
          "Action": "sts:AssumeRole",
          "Principal": {
            "Service": "ec2.amazonaws.com"
          },
          "Effect": "Allow",
          "Sid": ""
        }
      ]
    }
EOF
}

resource "aws_security_group" "web_sg" {
  name        = "web_only80_sg"
  description = "web insecure only port 80 ingress"
  vpc_id      = "${var.aws_vpc_id}"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_iam_role_policy_attachment" "chaos_apps_attach" {
  role       = "${aws_iam_role.chaos_apps_role.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
}

# aws autoscaling create-launch-configuration 
# --launch-configuration-name lc1 --instance-type t1.micro 
# --image-id ami-fcf27fcc --key-name <keyname>
resource "aws_launch_configuration" "lc" {
  name                 = "chaos-monkey-lc"
  image_id             = "${data.aws_ami.image.id}"
  instance_type        = "t2.micro"
  iam_instance_profile = "${aws_iam_instance_profile.chaos_apps_profile.name}"
  security_groups      = ["${data.aws_security_group.security_default_group.id}"]

  # key_name = "YOUR_KEY_IF_NEED_SSH_ACCESS"

  root_block_device {
    delete_on_termination = true
  }

  user_data = <<EOF
  #!/bin/bash
  yum update -y
  amazon-linux-extras install nginx1.12
  systemctl start nginx
  systemctl enable nginx
  wget -O /usr/share/nginx/html/nginx-logo.png https://nginx.org/nginx.png
  EOF

  lifecycle {
    create_before_destroy = false
  }
}

# aws autoscaling create-auto-scaling-group 
# --auto-scaling-group-name monkey-target --launch-configuration-name lc1 
# --availability-zones us-west-2a --min-size 1 --max-size 1
resource "aws_autoscaling_group" "this" {
  name                 = "monkey-target"
  launch_configuration = "${aws_launch_configuration.lc.name}"
  min_size             = 2
  max_size             = 3
  vpc_zone_identifier  = ["${data.aws_subnet.subnet.*.id}"]

  lifecycle {
    create_before_destroy = false
  }

  tag {
    key                 = "Name"
    value               = "Monkey-Instance"
    propagate_at_launch = true
  }
}

# Create a new load balancer
resource "aws_elb" "chaos_monkey_elb" {
  name = "chaos-monkey-elb"

  availability_zones = ["${data.aws_subnet.subnet.*.availability_zone}"]
  security_groups    = ["${data.aws_security_group.security_default_group.id}", "${aws_security_group.web_sg.id}"]

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:80/"
    interval            = 30
  }

  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400
}

# Create a new load balancer attachment
resource "aws_autoscaling_attachment" "asg_attachment_bar" {
  autoscaling_group_name = "${aws_autoscaling_group.this.id}"
  elb                    = "${aws_elb.chaos_monkey_elb.id}"

  //  alb_target_group_arn = "${aws_lb.chaos_monkey_alb.arn}"
}

variable region {
  description = "Provide region to create these resources"
  default     = "us-east-1"
}

variable profile {
  description = "AWS profile you want to use"
  default     = "default"
}

variable "aws_vpc_id" {
  description = "VPC ID you want to create this ASG"
}

output "elb_dns" {
  value = "${aws_elb.chaos_monkey_elb.dns_name}"
}

provider "aws" {
  region  = "${var.region}"
  profile = "${var.profile}"
}
