# Jenkins on Amazon Kubernetes 

## Create a cluster



## Setup our Cloud Storage 

```
# deploy EFS storage driver

kubectl apply -k "github.com/kubernetes-sigs/aws-efs-csi-driver/deploy/kubernetes/overlays/stable/?ref=master"

# get VPC ID

aws eks describe-cluster --name getting-started-eks --query "cluster.resourcesVpcConfig.vpcId" --output text

# Get CIDR range

aws ec2 describe-vpcs --vpc-ids vpc-id --query "Vpcs[].CidrBlock" --output text

# security for our instances to access file storage

aws ec2 create-security-group --description efs-test-sg --group-name efs-sg --vpc-id VPC_ID
aws ec2 authorize-security-group-ingress --group-id sg-xxx  --protocol tcp --port 2049 --cidr VPC_CIDR

# create storage

aws efs create-file-system --creation-token eks-efs

# create mount point 

aws efs create-mount-target --file-system-id FileSystemId --subnet-id SubnetID --security-group GroupID

# grab our volume handle to update our PV YAML

aws efs describe-file-systems --query "FileSystems[*].FileSystemId" --output text

```


### Setup a namespace
```
kubectl create ns jenkins
```

### Setup our storage for Jenkins

```
kubectl get storageclass

# create volume
kubectl apply -f ./jenkins/amazon-eks/jenkins.pv.yaml 
kubectl get pv

# create volume claim
kubectl apply -n jenkins -f ./jenkins/amazon-eks/jenkins.pvc.yaml
kubectl -n jenkins get pvc
```

### Deploy Jenkins

```
# rbac
kubectl apply -n jenkins -f ./jenkins/jenkins.rbac.yaml 

kubectl apply -n jenkins -f ./jenkins/jenkins.deployment.yaml

kubectl -n jenkins get pods

```

### Expose a service for agents

```

kubectl apply -n jenkins -f ./jenkins/jenkins.service.yaml 

```

## Jenkins Initial Setup

```
kubectl -n jenkins exec -it <podname> cat /var/jenkins_home/secrets/initialAdminPassword
kubectl port-forward -n jenkins <podname> 8080

# setup user and recommended basic plugins
# let it continue while we move on!

```

## SSH to our node to get Docker user info

```
eval $(ssh-agent)
ssh-add ~/.ssh/id_rsa
ssh -i ~/.ssh/id_rsa ec2-user@ec2-13-239-41-67.ap-southeast-2.compute.amazonaws.com
id -u docker
cat /etc/group
# Get user ID for docker
# Get group ID for docker
```
## Docker Jenkins Agent

Docker file is [here](../dockerfiles/dockerfile) <br/>

```
# you can build it

cd ./jenkins/dockerfiles/
docker build . -t aimvector/jenkins-slave

```




