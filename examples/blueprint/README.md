[[English](README.md)] [[한국어](README.ko.md)]

# FIS Blueprint
This is FIS (AWS Fault Injection Simulator) Blueprint example helps you compose complete FIS experiments that are fully bootstrapped with the operational software that is needed to deploy and operate chaos engineering. Chaos engineering is the discipline of experimenting on a distributed system in order to build confidence in the system's capability to withstand turbulent and unexpected conditions in production. If you want know why and how to do chaos engineering, please refer to [this page](https://github.com/Young-ook/terraform-aws-fis/tree/main/README.md). With this FIS Blueprint example, you describe the configuration for the desired state of your fault-tolerant AWS environment and resilience testing tools, such as the control plane, computing nodes, databases, storage, network and fault injection simulator, as an Infrastructure as Code (IaC) template/blueprint. Once a blueprint is configured, you can use it to stamp out consistent environments across multiple AWS accounts and Regions using your automation workflow tool, such as Jenkins, CodePipeline. Also, you can use FIS Blueprint to easily bootstrap a reliable cloud-native application stack with confidence. FIS Blueprints also helps you implement relevant security controls needed to operate workloads from multiple teams.

## Setup
## Download
Download this example on your workspace
```
git clone https://github.com/Young-ook/terraform-aws-fis
cd terraform-aws-fis/examples/blueprint
```

Then you are in **blueprint** directory under your current workspace. There is an exmaple includes a terraform configuration to create and manage an EKS cluster and Addon utilities on your AWS account. Please make sure you have the terraform and kubernetes tools in your environment, or go to the [eks project page](https://github.com/Young-ook/terraform-aws-eks) and follow the installation instructions before you move to the next step.
All things are ready, apply terraform:
```
terraform init
terraform apply
```
Also you can use the *-var-file* option for customized paramters when you run the terraform plan/apply command.
```
terraform plan -var-file fixture.tc1.tfvars
terraform apply -var-file fixture.tc1.tfvars
```

### Update kubeconfig
We need to get kubernetes config file for access the cluster that we've made using terraform. After terraform apply, you will see the bash command on the outputs. The terraform output should look similar to the one below. To update kubeconfig, simply, copy the bash command from the terraform output and run it on your workspace. Then export the downloaded file to **KUBECONFIG** environment variable. For more details, please refer to the [user guide](https://github.com/Young-ook/terraform-aws-eks#generate-kubernetes-config).
```
bash -e .terraform/modules/eks/script/update-kubeconfig.sh -r ap-northeast-2 -n fis-blueprint -k kubeconfig
export KUBECONFIG=kubeconfig
```

### Access Chaos Mesh
[Chaos Mesh](https://chaos-mesh.org/docs/) is an open source cloud-native Chaos Engineering platform. It offers various types of fault simulation and has an enormous capability to orchestrate fault scenarios. Using Chaos Mesh, you can conveniently simulate various abnormalities that might occur in reality during the development, testing, and production environments and find potential problems in the system. AWS FIS supports ChaosMesh and Litmus experiments for containerized applications running on Amazon Elastic Kubernetes Service (EKS). Using the new Kubernetes custom resource action for AWS FIS, you can control ChaosMesh and Litmus chaos experiments from within an AWS FIS experiment, enabling you to coordinate fault injection workflows among multiple tools. For example, you can run a stress test on a pod’s CPU using ChaosMesh or Litmus faults while terminating a randomly selected percentage of cluster nodes using AWS FIS fault actions.

In your local workspace, run kubernetes command to connect to your chaos-mesh dashboard through a proxy:
```
kubectl -n chaos-mesh port-forward svc/chaos-dashboard 2333:2333
```
If you are run this example in your Cloud9 IDE, you have to change the local port to 8080 instead of 2333.
```
kubectl -n chaos-mesh port-forward svc/chaos-dashboard 8080:2333
```
Open `http://localhost:2333` on your web browser. If you are in your Cloud9 IDE, click *Preview* and *Preview Running Application*. This shows chaos mesh dashboard login page. When you access your chaos mesh dashboard, first, you have to create user accounts and bind permissions. Follow the [Manage User Permissions](https://chaos-mesh.org/docs/manage-user-permissions/) instructions to create a new user and generate access token.
![cm-dashboard-login](../../images/cm-dashboard-login.png)

### Allow AWS FIS to call chaos mesh manager
First, to use AWS FIS as a centralized fault injection manager that leverages chaos mesh to inject faults into kubernetes resources, you have to create a chaos-mesh-manager RBAC role in your Kubernetes cluster. Next, you need to integrate using the aws-auth config map in the kube-system namespace.

This is kubernetes command to create chaos-mesh-manager role:
```
kubectl apply -f cm-manager.yaml
```

Then, check the aws-auth configmap:
```
kubectl -n kube-system describe cm aws-auth
```

The chaos mesh manager Kubernetes RBAC Role and the AWS FIS IAM Role must be integrated as shown below.
```
auth
Name:         aws-auth
Namespace:    kube-system
Labels:       <none>
Annotations:  <none>

Data
====
mapAccounts:
----
[]

mapRoles:
----
- "groups":
  - "system:bootstrappers"
  - "system:nodes"
  "rolearn": "arn:aws:iam::111100001234:role/fis-blueprint-kubernetes-ng"
  "username": "system:node:{{EC2PrivateDNSName}}"
- "groups":
  - "system:masters"
  - "chaos-mesh-manager-role"
  "rolearn": "arn:aws:iam::111100001234:role/fis-blueprint-fis-run"
```

## Applications
- [LAMP](./apps/README.md#lamp)
- [Redispy](./apps/README.md#redispy)
- [SockShop](./apps/README.md#sockshop)
- [Yelb](./apps/README.md#yelb)

## Expreiments
### Terminate Kubernetes Pod

![aws-fis-eks-pod-kill-description](../../images/eks/aws-fis-eks-pod-kill-description.png)
![aws-fis-eks-pod-kill-stop-condition](../../images/eks/aws-fis-eks-pod-kill-stop-condition.png)
![aws-fis-eks-pod-kill-watch](../../images/eks/aws-fis-eks-pod-kill-watch.png)

## Clean up
Run terraform:
```
terraform destroy
```
**[DON'T FORGET]** You have to use the *-var-file* option when you run terraform destroy command to delete the aws resources created with extra variable files.
```
terraform destroy -var-file fixture.tc1.tfvars
```

# Additional Resources
## AWS Fault Injection Simulator
- [Chaos Testing with AWS Fault Injection Simulator and AWS CodePipeline](https://aws.amazon.com/blogs/architecture/chaos-testing-with-aws-fault-injection-simulator-and-aws-codepipeline/)
- [Increase your e-commerce website reliability using chaos engineering and AWS Fault Injection Simulator](https://aws.amazon.com/blogs/devops/increase-e-commerce-reliability-using-chaos-engineering-with-aws-fault-injection-simulator/)

## Chaos Mesh
- [Simulate Kubernetes Resource Stress Test](https://chaos-mesh.org/docs/simulate-heavy-stress-on-kubernetes/) 
- [Simulate AWS Faults](https://chaos-mesh.org/docs/simulate-aws-chaos/)

## Terraform Modules
- [Terraform module: Amazon Aurora](https://github.com/Young-ook/terraform-aws-aurora)
- [Terraform module: Amazon EKS](https://github.com/Young-ook/terraform-aws-eks)
- [Terraform module: AWS Systems Manager](https://github.com/Young-ook/terraform-aws-ssm)
- [Terraform module: Spinnaker](https://github.com/Young-ook/terraform-aws-spinnaker)
