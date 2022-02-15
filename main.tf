resource "aws_instance" "ec2-instance" {

  ami                         = var.ami
  instance_type               = var.instance_type
  subnet_id                   = "subnet-6127e62d"
  security_groups             = [var.vpc_security_group_id_for_ec2]
  associate_public_ip_address = true
  key_name                    = "amazon-key"
  ebs_block_device {
    device_name = "/dev/sda1"
    volume_size = 80
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
    docker run -d --restart=unless-stopped -p 80:80 -p 443:443 --privileged rancher/rancher:${var.rancher_version}
    #sleep 200
    cd $HOME
    #Saves bootstrap password log line to dockerpassword.txt
    docker logs $(docker ps --format '{{.Names}}') 2>&1 | grep "Bootstrap Password" > $HOME/dockerpassword.txt
    #Saves bootstrap password log line to BootstrapPassword
    cat dockerpassword.txt | grep -oP '(?<=Bootstrap Password: )[^ ]*' > $HOME/bootstrappassword
    export AWS_ACCESS_KEY_ID=${var.AWS_KEY_ID}
    export AWS_SECRET_ACCESS_KEY=${var.AWS_SECRET_KEY_ID}
    export AWS_DEFAULT_OUTPUT= ${var.AWS_DEFAULT_OUTPUT}
    export AWS_DEFAULT_REGION= 'us-east-2'
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    sudo apt install unzip
    unzip awscliv2.zip
    sudo ./aws/install
    aws --version
    aws ec2 describe-instances --region us-east-2 --filters "Name=tag:Name,Values=vivek-rancher-Server" | grep -i publicipaddress | cut -d ":" -f 2 > $HOME/temp_server_url
    export server_url=`cat $HOME/temp_server_url`
    sed -e 's/^"//' -e 's/"$//' <<< `echo $${$HOME/server_url::-1}` > $HOME/rancher-url
    export temp=`cat $HOME/rancher-url`
  EOF
}
