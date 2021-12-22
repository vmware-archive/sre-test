Installing PXF
  --------------
  
  1. Clone the PXF repository  from github.
  
  2. cd pxf
  
  3. You can adjust the parameters by editing pxf-vars.yml file if required.
     Eg:
		pivnet_release_version
		pivnet_product_file_id
		pivnet_pxf_version
		java_version
		
  4. Edit the below details in the hostsfile as per your cluster information.
        ansible_user --> provide username to login to maternode.
		ansible_ssh_private_key_file --> Provide the path to .pem file to connect to masternode.
		ansible_host --> Greenplum Database Master node public ip.
  
  5. Execute the below command to install the PXF.
		ansible-playbook -i hostsfile main.yml -e @pxf-vars.yml -e "pivnet_api_token=<UAA API TOKEN>"
		
		Get the UAA API TOKEN from Tanzunet (https://network.pivotal.io/).
		
  6. After Executing the above ansible script, we can observe "JAVA_PATH","PXF_BASE" in the console output.
  
  7. Once PXF is installed, please follow the below steps.
  
     Check the PXF status and start the PXF cluster.
	 
	 Please Configure PXF connector as per External data source requirement.
	 
	 Refer to PXF documentation for more details (https://gpdb.docs.pivotal.io/pxf/6-2/using/cfg_server.html).
