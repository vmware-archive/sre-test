# Set up the AWS Cluster

## Set up direnv
This simplifies the process as it provides environment variables that can be accessed via the scripts 
- `cp REPO/.envrc.sample REPO/.envrc`
- edit REPO/.envrc and fill in your _AWS_ACCESS_KEY_ID_, _AWS_SECRET_ACCESS_KEY_ and _pivnet_api_token_.

## Use Terraform to set up the AWS infrastructure
- `terraform init`
- `terraform plan'
- `terraform apply'

## Bring in infrastructure values into environment
- edit your _.envrc_ file for the correct number of hosts and for your node name.  Instructions are in that file.
- `direnv allow` to allow your _.envrc_ file to be reloaded.
  - `direnv allow`
- edit the file _gen_ansible_hosts.bash_ for the correct number of hosts.
- make sure you can connect to the jumpbox:
  - `ping -c2 ${JUMPBOX_IPV4}`
  - `ssh -oStrictHostKeyChecking=no -i files/gp_dev.pem centos@${JUMPBOX_IPV4}`
