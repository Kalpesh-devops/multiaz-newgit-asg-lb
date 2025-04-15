resource "aws_security_group" "Int-alb" {
  vpc_id = aws_vpc.main.id
  tags = {
    name = "Int-alb"
  }
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

resource "aws_security_group" "alb-int" {
  vpc_id = aws_vpc.main.id
  tags = {
    name = "alb-int"
  }

  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.Int-alb.id]
    //cidr_blocks = [aws_security_group.Int-alb.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]

  }

}

//application loadbalancer
resource "aws_lb" "Int-alb-april" {
  tags = {
    name = "Int-alb-april"
  }
  load_balancer_type = "application"
  internal           = false
  security_groups    = [aws_security_group.Int-alb.id]
  subnets            = aws_subnet.public-subnets[*].id
  depends_on         = [aws_internet_gateway.igw-multiaz]

}

resource "aws_lb_target_group" "alb-tg-april" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "alb-tg-april"
  }
  port     = "80"
  protocol = "HTTP"


}

resource "aws_lb_listener" "alb-listener" {
  load_balancer_arn = aws_lb.Int-alb-april.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb-tg-april.arn

  }

}

//launch template for ec2

resource "aws_launch_template" "launch-template-ec2" {
  //count = length(var.az-subnets)
  //name          = "launch-template-ec2->${count.index+1}"
  image_id      = "ami-002f6e91abff6eb96"
  instance_type = "t2.micro"
  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.alb-int.id]

  }

  user_data = filebase64("userdata.sh")

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "launch-template-ec2"

    }
  }
}

resource "aws_autoscaling_group" "ec2-asg" {
  max_size            = 3
  min_size            = 2
  desired_capacity    = 2
  name                = "ec2-asg-april"
  target_group_arns   = [aws_lb_target_group.alb-tg-april.arn]
  vpc_zone_identifier = aws_subnet.private-subnets[*].id
 
  launch_template {
    id      = aws_launch_template.launch-template-ec2.id
    version = "$Default"
  }
  health_check_type = "EC2"

}

output "alb_dns_name" {
  value = aws_lb.Int-alb-april.dns_name

}