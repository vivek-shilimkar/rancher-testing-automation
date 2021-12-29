resource "aws_key_pair" "personal" {
  key_name   = "amazon-key"
  public_key = file("/home/infracloud/.ssh/id_rsa.pub")
}

resource "aws_instance" "ec2-instance" {

  ami                         = var.ami
  instance_type               = var.instance_type
  subnet_id                   = "subnet-6127e62d"
  security_groups             = [var.vpc_security_group_id_for_ec2]
  associate_public_ip_address = true
  key_name                    = "amazon-key"
  depends_on                  = [aws_key_pair.personal]
  ebs_block_device {
    device_name = "/dev/sda1"
    volume_size = 80
  }
  tags = {
    Name = "${var.name}"
  }
  user_data = <<-EOF
    #!/bin/bash
    curl https://releases.rancher.com/install-docker/20.10.sh | sh
    sudo chmod 777 /var/run/docker.sock
    docker run -d --restart=unless-stopped -p 80:80 -p 443:443 --privileged rancher/rancher:${var.rancher_version}
  EOF
}
