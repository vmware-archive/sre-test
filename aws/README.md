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
      terraform.tfstate > gp_prod.pem

chmod 600 gp_prod.pem
```

## Bring in infrastructure values into environment
- Edit your _.envrc_ file for the correct number of hosts and for your GP cluster configuration.
- Run `direnv allow` to allow your _.envrc_ file to be reloaded.
```
direnv allow
```

- Make sure you can connect to the gp systems dw controller:
```
for host in ${MDW_IPV4} ${SMDW_IPV4} ${SDW1_IPV4} ${SDW2_IPV4} ${SDW3_IPV4} ${SDW4_IPV4}; do \
ssh -oStrictHostKeyChecking=no -i gp_prod.pem centos@$host uptime; done
```

- (Optional) Test logging into Controller
```
ssh -oStrictHostKeyChecking=no -i gp_prod.pem centos@${MDW_IPV4}
```

## Run Ansible to install GPDB, GPCC and Backup & restore utility
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

## Log into Controller (mdw) and verify the GPDB installation
```
ssh -oStrictHostKeyChecking=no -i gp_prod.pem centos@${MDW_IPV4}
```
- switch to gpadmin user

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
## TMUX - build/install/condigure tmux
```
sudo yum install -e 0 -y gcc libevent-devel ncurses-devel
curl -L https://github.com/tmux/tmux/releases/download/3.1c/tmux-3.1c.tar.gz -O
tar xf tmux-3.1c.tar.gz
cd tmux-3.1c
./configure
make -j$(nproc)
sudo make install
cd; curl -O https://raw.githubusercontent.com/gpakosz/.tmux/master/.tmux.conf
```
### TMUX commands (list sessions, attach to session) 
```
tmux ls
tmux a -t 0
```
* TPC-DS
```
# log into mdw node

# start/attach tmux session
tmux or tmux a -t 0

# As centos user
mkdir tpcds
cd tpcds
curl https://raw.githubusercontent.com/edespino/TPC-DS/centos/tpcds.sh -O
bash tpcds.sh
sed -i -e 's|gpadmin|centos|g' -e 's|3000|1|g' tpcds_variables.sh
TIMESTAMP=$(date "+%Y.%m.%d-%H.%M.%S"); bash ./tpcds.sh 2>&1 | tee tpch-${TIMESTAMP}.log
```
