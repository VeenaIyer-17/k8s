# k8s

## Team Information

| Name | NEU ID | Email Address |
| --- | --- | --- |
| Akash Katakam | 001400025 | katakam.a@husky.neu.edu |
| Ravi Kiran    | 001439467 | lnu.ra@husky.neu.edu |
| Veena Iyer    | 001447061 | iyer.v@husky.neu.edu|

## Pre-requisites
You need to configure the following first before using this playbook:
1. Add AWS credentials of member accounts-  KOPS
3. Create S3 bucket for KOPS State Store
4. Generate new SSH key for connecting to bastion node


### 1. Create IAM users
Create a new IAM user in each member accounts having console as well as programmatic access. Attach followig policies to these users:

1. AdministratorAccess
2. AmazonRoute53FullAccess
3. AmazonS3FullAccess
4. IAMFullAccess
5. AmazonEC2FullAccess
6. AmazonVPCFullAccess

> Note: Make sure you download the Access Keys file (*.csv) for each user. These keys will be used to setup profiles in the next step.

### 2. Setting up AWS profiles of member accounts
Open `~/.aws/credentials` in any text editor. It should look like the following:
```
[kops]
aws_access_key_id = <aws-access-key-id-of-root-account>
aws_secret_access_key = <aws-secret-access-key-for-root-account>

```

Append credentials of your member accounts, and tag them with profile names. In our case, it is `dev` and `prod`, which represent our different environments.

```ini
[kops]
aws_access_key_id = <aws-access-key-id-for-root-account>
aws_secret_access_key = <aws-secret-access-key-for-root-account>

[dev]
aws_access_key_id = <aws-access-key-id-for-dev-account>
aws_secret_access_key = <aws-secret-access-key-for-dev-account>

[prod]
aws_access_key_id = <aws-access-key-id-for-prod-account>
aws_secret_access_key = <aws-secret-access-key-for-prod-account>
```

### 3. Create DNS hosted zones
>Note: It is assumed that you have a DNS Hosted Zone in your root account, from the course CSYE6225

For kops/k8s we need to have a domain/hosted zone. Create public DNS hosted zones using the AWS Route 53 service for each of your member accounts. Name these Hosted Zones as follows:

`<environment>.<domain-name>`. 

In our case: `k8s.dev.<domain-name>` and `k8s.prod.<domain-name>`

### 4. Create S3 bucket for KOPS State Store

Create an S3 bucket in `us-east-1` region for each of your member accounts.

`k8s.<environment>.<domain-name>-state-store`

In our case: `dev.<domain-name>-state-store` and `prod.<domain-name>-state-store`

### 6. Generate new SSH key for connecting to bastion host

Create a new SSH key using the following command:

```sh
ssh-keygen rsa -C "your_email_id"

```

## Create/Delete Kubernetes cluster

Run the playbook `webservers.yml` in the root of the repository with extra variables (some are required).

```sh
ansible-playbook webservers.yal --extra-vars "<variable-key>=<variable-value>"

```
### **Given below is the list of accepted variables.**

| Key | Required | Default | Values |
| --- | --- | --- | --- |
| command | Yes |  | String - start \| delete |
| kops_state_store | Yes |  | String - ARN of the s3 bucket. Eg. s3://s3bucketname |
| cluster_name | Yes |  | String - Name of the cluster created. Eg. cluster.example.com |
| dns_zone_id | Yes (if command=start) |  | String - DNS ZONE ID of the private hosted zone (Can be found in Route 53) |
| public_dns_zone_id | Yes | | String - DNS ZONE ID of the public hosted zone (Can be found in Route 53) |
| public_domain_name | Yes | | String - Name of your domain |
| node_count | No | 3 | Number - Number of worker nodes |
| ssh_path | No |  | String - Path of the public SSH key previously generated |
| master_count | No | 3 | Number - Number of Master Nodes |
| node_size | No | t2.medium | String - Type of EC2 Instance |
| master_size | No | t2.medium | String - Type of EC2 Instance |
| topology | No | private | String - public \| private |
| networking | No | weave | String - Networking mode to use. kubenet \| classic \| external \| kopeio-vxlan (or kopeio) \| weave \| flannel-vxlan (or flannel) \| flannel-udp \| calico \| canal \| kube-router \| romana \| amazon-vpc-routed-eni \| cilium \| cni. |
| bastion | No | true | Boolean - true \| false |
| dns | No | private | String - public \| private |
| cloud | No | aws | String - gce \| aws \| vsphere \| openstack |
| profile | No | dev | String - AWS named profile in `~/.aws/credentials` |
| k8s_version | No | 1.13.0 | String - Kubernetes Version |


### To create a Kubernetes Cluster use the following

Run the following command in the root of the project

```
ansible-playbook webservers.yml -e "command=start clustername=<name-of-your-cluster> state_store=s3://<name-of-your-s3-bucket> node_count=2 node_size=t2.micro master_size=t2.micro dns_zone_id=<hosted-zone-id> profile=<aws-profile> k8s_version=<version> ssh_path=<ssh_key> region=<region>"
```
### To connect to the bastion node, use the ssh key passed in the previous command:- 
```sh
ssh -o "IdentitiesOnly=yes" -i /path/to/key admin@"DNSNameOfLoadBalancer"
```

### To delete a Kubernetes Cluster use the following
Run the following command in the root of the project

```
ansible-playbook webservers.yml -e "command=stop clustername=<name-of-your-cluster> state_store=s3://<name-of-your-s3-bucket> node_count=2 node_size=t2.micro master_size=t2.micro dns_zone_id=<hosted-zone-id> profile=<aws-profile> k8s_version=<version> ssh_path=<ssh_key> region=<region>"
```

### To ssh into bastion node

```sh
ssh -i <YourPrivateKey> ec2-user@<Public Dns Ip>
```