# Set up the AWS Cluster

## Dependencies
- [direnv](https://direnv.net/)
- [terraform](https://www.terraform.io/)
- [ansible](https://www.ansible.com/)
- Install additional Ansible modules
```
ansible-galaxy collection install community.general
ansible-galaxy collection install ansible.posix
```
- [jq](https://stedolan.github.io/jq/)
## Set up direnv
This simplifies the process as it provides environment variables that can be accessed via the scripts 
```
cp .envrc.sample .envrc
```

- edit `.envrc` and fill in your _AWS_ACCESS_KEY_ID_, _AWS_SECRET_ACCESS_KEY_ and _pivnet_api_token_.

## Use Terraform to set up the AWS infrastructure
```
terraform init
terraform plan
terraform apply
```

## Extract PEM file from `terraform.tfstate` file.
```
jq -r '.resources[] | select(.type == "tls_private_key") | .instances[0].attributes.private_key_pem' \
      terraform.tfstate > gp_dev.pem

chmod 600 gp_dev.pem
```

## Bring in infrastructure values into environment
- Edit your _.envrc_ file for the correct number of hosts and for your GP cluster configuration.
- Run `direnv allow` to allow your _.envrc_ file to be reloaded.
```
direnv allow
```

- Make sure you can connect to the jumpbox & gp systems dw controller:
```
ping -c2 ${JUMPBOX_IPV4}
for host in ${JUMPBOX_IPV4} ${MDW_IPV4} ${SMDW_IPV4} ${SDW1_IPV4} ${SDW2_IPV4}; do \
ssh -oStrictHostKeyChecking=no -i gp_dev.pem centos@$host uptime; done
```

- (Optional) Test logging into Jumpbox and Controller
```
ssh -oStrictHostKeyChecking=no -i gp_dev.pem centos@${JUMPBOX_IPV4}
ssh -oStrictHostKeyChecking=no -i gp_dev.pem centos@${MDW_IPV4}
```

## Run Ansible
- `cd ansible`
- If needed, edit the script _gen_ansible_files.bash_ for the correct number of hosts. This will generate ansible files with resource details from Terraform execution.
```
./gen_ansible_files.bash
```
- You can adjust parameters of the GPDB install, including the number of segments per host, by editing
 _gpdb-vars.yml_.
```
ansible-playbook --inventory-file=ansible_hosts ansible-playbook-all.yml -e @gpdb-vars.yml
```

## Log into Controller (mdw) and run gpinitsystem
```
ssh -oStrictHostKeyChecking=no -i gp_dev.pem centos@${MDW_IPV4}
gpinitsystem -c gpinitsystem_config.ipv4
```

## Run some sample gp cluster queries
```
psql -c "select version()"
psql -c "select * from gp_segment_configuration"
psql -c "show optimizer"
psql -c "SELECT gp_opt_version()"
psql -c 'SELECT * FROM gp_stat_replication'
```

## Retrieve version from Postgres binary
```
postgres --version
postgres --gp-version
postgres --catalog-version
```

## Use Terraform to teardown infrastructure
```
terraform destroy
```
