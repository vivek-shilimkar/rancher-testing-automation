resource "aws_instance" "ec2-instance" {

  ami                         = var.ami
  instance_type               = var.instance_type
  subnet_id                   = "subnet-6127e62d"
  security_groups             = [var.vpc_security_group_id_for_ec2]
  associate_public_ip_address = true
  key_name                    = "amazon-key"
  ebs_block_device {
    device_name = "/dev/sda1"
    volume_size = 320
  }
  tags = {
    Name = var.name
  }

  user_data = <<-EOF
    #!/bin/bash
    set -x

    # Install Docker
    curl https://releases.rancher.com/install-docker/25.0.sh | sh
    sudo chmod 777 /var/run/docker.sock

    # Install Rancher
    if [ "${var.registry}" == "docker" ]; then
      docker run -d --restart=unless-stopped -p 80:80 -p 443:443 --privileged -e CATTLE_BOOTSTRAP_PASSWORD=${var.BTPASSWORD} rancher/rancher:${var.rancher_version}
    elif [ "${var.registry}" == "prime" ]; then
      docker run -d --privileged --restart=unless-stopped -p 80:80 -p 443:443 -e CATTLE_BOOTSTRAP_PASSWORD=${var.BTPASSWORD} -e CATTLE_AGENT_IMAGE=stgregistry.suse.com/rancher/rancher-agent:${var.rancher_version} stgregistry.suse.com/rancher/rancher:${var.rancher_version}
    else
      echo "Invalid registry option. Exiting."
      exit 1
    fi

    # Install AWS CLI and Dependencies
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    sudo apt update -y && sudo apt install -y unzip jq
    unzip awscliv2.zip
    sudo ./aws/install
    aws --version

    # Configure AWS CLI
    mkdir -p /home/ubuntu/.aws
    chown -R ubuntu:ubuntu /home/ubuntu/.aws

    export AWS_REGION=us-east-2
    export AWS_DEFAULT_OUTPUT=json
    export TF_VAR_AWS_ACCESS_KEY_ID="$AWS_ACCESS_KEY_ID"
    export TF_VAR_AWS_SECRET_ACCESS_KEY="$AWS_SECRET_ACCESS_KEY"

    echo "[default]" > /home/ubuntu/.aws/credentials
    echo "aws_access_key_id = $AWS_ACCESS_KEY_ID" >> /home/ubuntu/.aws/credentials
    echo "aws_secret_access_key = $AWS_SECRET_ACCESS_KEY" >> /home/ubuntu/.aws/credentials

    echo "[default]" > /home/ubuntu/.aws/config
    echo "region = us-east-2" >> /home/ubuntu/.aws/config

    # Test AWS CLI
    aws sts get-caller-identity || exit 1

    # Wait for Rancher to become available
    PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
    RANCHER_URL=https://$PUBLIC_IP
    MAX_RETRIES=30
    RETRY_INTERVAL=10
    COUNTER=0

    echo "Waiting for Rancher to start at $RANCHER_URL"
    while [ $COUNTER -lt $MAX_RETRIES ]; do
      if curl -k --silent --fail $RANCHER_URL; then
        echo "Rancher is ready at $RANCHER_URL"
        break
      fi
      echo "Rancher not ready yet. Retrying in $RETRY_INTERVAL seconds..."
      sleep 300
      COUNTER=$((COUNTER + 1))
    done

    if [ $COUNTER -eq $MAX_RETRIES ]; then
      echo "Rancher did not become available in time."
      exit 1
    fi

    # Login and Fetch Tokens
    PASSWORD=rancher#1234
    LOGINTOKEN=$(curl -k -s "$RANCHER_URL/v3-public/localProviders/local?action=login" -H 'content-type: application/json' --data-binary '{"username":"admin","password":"'"$PASSWORD"'","ttl":60000}' | jq -r .token)
    if [ -z "$LOGINTOKEN" ]; then
      echo "Failed to fetch login token."
      exit 1
    fi

    APIKEY=$(curl -k -s "$RANCHER_URL/v3/token" -H 'Content-Type: application/json' -H "Authorization: Bearer $LOGINTOKEN" --data-binary '{"type":"token","description":"for scripts and stuff"}' | jq -r .token)

    # Create a New User and Assign Role
    USERNAME=testuser
    USERID=$(curl -s -u "$APIKEY" "$RANCHER_URL/v3/user" -H 'content-type: application/json' --data-binary '{"type":"user","username":"'"$USERNAME"'","password":"'"$PASSWORD"'","name":"vivek"}' --insecure | jq -r .id)
    curl -s -u "$APIKEY" "$RANCHER_URL/v3/globalrolebinding" -H 'content-type: application/json' --data-binary '{"type":"globalRoleBinding","globalRoleId":"user","userId":"'"$USERID"'"}' --insecure

    # Save Tokens
    echo $APIKEY | tee /tmp/Tokens > /dev/null
    echo $LOGINTOKEN >> /tmp/Tokens

    # Cleanup Temporary Files
    rm -rf awscliv2.zip aws

  EOF
}

output "rancher_server_url" {
  value = "https://${aws_instance.ec2-instance.public_ip}"
}

output "rancher_login_token" {
  value = "Fetch tokens using SSH or SSM after the instance is created."
}
