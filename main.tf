#resource "aws_key_pair" "personal" {
#  key_name   = "amazon-key"
#  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDdFyNTLqFeFhPC9MBSn/noch60Lngkue91rsL7Ug18gcOvn71G2/00KlXQ0LSUkeE27nWKF6ggrBrpIS2Bm1AbYmtGgEhpHYAeYS+cG7YOTJAp0WZ09Gld1LBdPwD/BVicwStY/hRYRwzFlsdzd3AqZ7dvm5fTDNcjUHjfwzJwqZjf6opYWo5C+maZTm9uRDlAcI4kftthd71OqcU1lggSuNv40odXXiioVr+vmtPzP1GJ+XPJCNvWOH7hmiajDblM9cb0FjwkO1H7xShdIvf1fqpHLiZnyv7eLrORCRLNBq0iZL6CBJHQa0lToZ7MMDl4iwPp+X3dJoHBTPRFtiw59FYgUpbb4sXMIeSTnuNb2L3zIiVRj6xt53srD5Qtdxu+Klr2De2HarNUV1cRV6EX4ts4r6wzJjixuXPkijt/PBaf4NZ3wio1dd8L/3ouPSOidDYmOBOVJjrDdHGrjz4T9kbkVhP/KyGH7pxqfMmAogq7NXuBPrHS7dC72FDpT1U= infracloud@vivek-shilimkar"
#}

resource "aws_instance" "ec2-instance" {

  ami                         = var.ami
  instance_type               = var.instance_type
  subnet_id                   = "subnet-6127e62d"
  security_groups             = [var.vpc_security_group_id_for_ec2]
  associate_public_ip_address = true
  key_name                    = "amazon-key"
  #depends_on                  = [aws_key_pair.personal]
  ebs_block_device {
    device_name = "/dev/sda1"
    volume_size = 320
  }
  tags = {
    Name = "${var.name}"
  }
  user_data = <<-EOF
    #!/bin/bash
    set -x
    curl https://releases.rancher.com/install-docker/20.10.sh | sh
    sudo chmod 777 /var/run/docker.sock
    #Install Rancher
    docker run -d --restart=unless-stopped -p 80:80 -p 443:443 --privileged -e CATTLE_BOOTSTRAP_PASSWORD=rancher#1234 rancher/rancher:${var.rancher_version}
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    sudo apt install unzip
    unzip awscliv2.zip
    sudo ./aws/install
    aws --version
    export AWS_KEY_ID=${var.AWS_KEY_ID}
    export AWS_SECRET_KEY_ID= ${var.AWS_SECRET_KEY_ID}
    export AWS_DEFAULT_OUTPUT= ${var.AWS_DEFAULT_OUTPUT}
    export AWS_REGION= 'us-east-2'
    aws ec2 describe-instances --region us-east-2 --filters "Name=tag:Name,Values=vivek-rancher-Server" | grep -i publicipaddress | cut -d ":" -f 2 | cut -c 3-15 > server_url
  EOF
}
