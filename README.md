# end-to-end-DEvops

*step to configure vm and runner

before terraform plan or apply set these password in cmd or powershell 1st these are the secrets will add into pipeline secrets later

$env:TF_VAR_vm_admin_password = 'Vm-Str0ng-Pass-2026!'
$env:TF_VAR_db_password       = 'Db-Str0ng-Pass-2026!'

*after tf apply go to vm add user to IAM as Virtual administrator login
and download conifgure thing from vpn gateway
and connect vpn using the configuration and 

1st remove old vpn key "ssh-keygen -R 10.0.1.4"
*in terminal login into vm "az ssh vm --ip ip address"

*then install git into it "sudo apt update" and install git "sudo apt install git -y"

*then install Ansible "sudo apt install ansible -y"

*then git clone https://github.com/Devops-End/end-to-end-DEvops.git

*then
cd ~/end-to-end-DEvops
git pull
cd Ansible
ansible-playbook -c local -i localhost, local.yml -e runner_token=AZ3M7T726Y7MD6BJZVDLXRTK2WWMW

#access kubectl
az login --identity
az aks get-credentials -g terraform-rg -n terraform-aks --overwrite-existing
kubectl get nodes 