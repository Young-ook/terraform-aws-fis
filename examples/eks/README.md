[[English](README.md)] [[한국어](README.ko.md)]

# Chaos Engineering
Chaos engineering is the discipline of experimenting on a distributed system in order to build confidence in the system's capability to withstand turbulent and unexpected conditions in production. The goal of chaos engineering is to identify and remediate weakness in a system through controlled experiments that introduce random and unpredictable behavior. Therefore, Chaos engineering is NOT about breaking thingsrandomly without a purpose, chaos engineering is about breaking things in a controlled environment and through well-planned experiments in order to build confidence in your application to withstand turbulent conditions. If you want know why and how to do chaos engineering, please refer to this [page](https://github.com/Young-ook/terraform-aws-fis/blob/main/README.md).

![aws-fis-eks-arch](../../images/eks/aws-fis-eks-arch.png)

## Download example
Download this example on your workspace
```sh
git clone https://github.com/Young-ook/terraform-aws-fis
cd terraform-aws-fis/examples/eks
```

## Setup
[This](https://github.com/Young-ook/terraform-aws-fis/blob/main/examples/eks/main.tf) is an example of terraform configuration file to create AWS Fault Injection Simulator experiments for chaos engineering. Check out and apply it using terraform command.

If you don't have the terraform and kubernetes tools in your environment, go to the main [page](https://github.com/Young-ook/terraform-aws-fis) of this repository and follow the installation instructions.

### Create Cluster
Run terraform:
```
terraform init
terraform apply
```
Also you can use the `-var-file` option for customized paramters when you run the terraform plan/apply command.
```
terraform plan -var-file fixture.tc1.tfvars
terraform apply -var-file fixture.tc1.tfvars
```

### Update kubeconfig
Update and download kubernetes config file to local. You can see the bash command like below after terraform apply is complete. The output looks like below. Copy and run it to save the kubernetes configuration file to your local workspace. And export it as an environment variable to apply to the terminal.
```
bash -e .terraform/modules/eks/script/update-kubeconfig.sh -r ap-northeast-2 -n eks-fis -k kubeconfig
export KUBECONFIG=kubeconfig
```

### Microservices Architecture Application
For this lab, we picked up the Sock Shop application. Sock Shop is a microservices architecture sample application that Weaveworks initially developed. They made it open source so it can be used by other organizations for learning and demonstration purposes.

Create the namespace and deploy application.
```
kubectl apply -f manifests/sockshop-demo.yaml
```
Verify that the pod came up fine (ensure nothing else is running on port 8079):
```
kubectl -n sockshop get pod -l name=front-end
```
The output will be something like this:
```
NAME                         READY   STATUS    RESTARTS   AGE
front-end-7b8bcd59cb-wd527   1/1     Running   0          9s
```

#### Local Workspace
In your local workspace, connect through a proxy to access your application's endpoint.
```
kubectl -n sockshop port-forward svc/front-end 8080:80
```
Open `http://localhost:8080` on your web browser. This shows the Sock Shop main page.

#### Cloud9
In your Cloud9 IDE, run the application.
```
kubectl -n sockshop port-forward svc/front-end 8080:80
```
Click `Preview` and `Preview Running Application`. This opens up a preview tab and shows the Sock Shop main page.

![weaveworks-sockshop-frontend](../../images/eks/weaveworks-sockshop-frontend.png)

🎉 Congrats, you’ve deployed the sample application on your cluster.

### Run Load Generator
Run load generator inside kubernetes
```
kubectl apply -f manifests/sockshop-loadtest.yaml
```

## Run Fault Injection Experiments
This module automatically creates fault injection simulator experiment templates on your AWS account. Move to the AWS FIS service page on the AWS Management Console and select Experiment templates menu on the left. Then you will see the created experiment templates for chaos engineering. To test your environment, select a experiment template that you want to run and click the `Actions` button on the right top on the screen. You will see `Start experiment` in the middle of poped up menu and select it. And follow the instructions.

![aws-fis-experiment-templates](../../images/eks/aws-fis-experiment-templates.png)

### Terminate EKS Nodes
AWS FIS allows you to test resiliency of EKS cluster node groups. See what happens if you shut down some ec2 nodes for kubernetes pods or services within a certain percentage. This test verifies that the EKS managed node group launches new instances to meet the defined desired capacity and ensures that the application containers continues to run well. Also, this test will help you understand what happens to your application when you upgrade your cluster. At this time, in order to satisfy both resiliency and ease of cluster upgrade, the container should be designed so that it can be moved easily. This makes it easy to move containers running on the failed node to another node to continue working. This is an important part of a cloud-native architecture.

#### Define Steady State
Before we begin a failure experiment, we need to validate the user experience and revise the dashboard and metrics to understand that the systems are working under normal state, in other words, steady state.

![aws-fis-cw-dashboard](../../images/eks/aws-fis-cw-dashboard.png)

Let’s go ahead and explore Sock Shop application. Some things to try out:
1. Register and log in using the below credentials (These are very secure so please don’t share them)
    * Username: `user`
    * Password: `password`
1. View various items
1. Add items to cart
1. Remove items from cart
1. Check out items

#### Hypothesis
The experiment we’ll run is to verify and fine-tune our application availability when compute nodes are terminated accidentally. The application is deployed as a container on the Kubernetes cluster, we assume that if some nodes are teminated, the Kubernetes control plane will reschedule the pods to the other healthy nodes. In order for chaos engineering to follow the scientific method, we need to start by making hypotheses. To help with this, you can use an experiment chart (see below) in your experiment design. We encourage you to take at least 5 minutes to write your experiment plan.

**Steady State Hypothesis Example**

+ Title: Services are all available and healthy
+ Type: What are your assumptions?
   - [ ] No Impact
   - [ ] Degraded Performance
   - [ ] Service Outage
   - [ ] Impproved Performance
+ Probes:
   - Type: CloudWatch Metric
   - Status: `service_number_of_running_pods` is greater than 0
+ Stop condition (Abort condition):
   - Type: CloudWatch Alarm
   - Status: `service_number_of_running_pods` is less than 1
+ Results:
   - What did you see?
+ Conclusions:
   - [ ] Everything is as expected
   - [ ] Detected something
   - [ ] Handleable error has occurred
   - [ ] Need to automate
   - [ ] Need to dig deeper

#### Run Experiment
Make sure that all your EKS node group instances are running. Go to the AWS FIS service page and select `TerminateEKSNodes` from the list of experiment templates. Then use the on-screen `Actions` button to start the experiment. AWS FIS shuts down EKS nodes for up to 70% of currently running instances. In this experiment, this value is 40% and it is configured in the experiment template. You can edit this value in the target selection mode configuration if you want to change the number of EKS nodes to shut down You can see the terminated instances on the EC2 service page, and the new instances will appear shortly after the EKS node is shut down.

![aws-fis-terminate-eks-nodes-action-complete](../../images/eks/aws-fis-terminate-eks-nodes-action-complete.png)

![aws-fis-terminate-eks-nodes](../../images/eks/aws-fis-terminate-eks-nodes.png)

You can see the nodes being shut down in the cluster:
```
kubectl -n sockshop get node -w
NAME                                            STATUS   ROLES    AGE     VERSION
ip-10-1-1-205.ap-northeast-2.compute.internal   Ready    <none>   21m     v1.20.4-eks-6b7464
ip-10-1-9-221.ap-northeast-2.compute.internal   Ready    <none>   4m40s   v1.20.4-eks-6b7464
ip-10-1-9-221.ap-northeast-2.compute.internal   NotReady   <none>   4m40s   v1.20.4-eks-6b7464
ip-10-1-9-221.ap-northeast-2.compute.internal   NotReady   <none>   4m40s   v1.20.4-eks-6b7464
```

#### Discussion
Then access the microservices application again. What happened? Perhaps a node shutdown by a fault injection experiment will cause the application to crash. This is because the first deployment of the application did not consider high availability (stateless, immutable, replicable) characteristics against single node or availability-zone failure. In the next stage, you will learn how to improve the architecture for reliabiliy and high availability.

Before we move to the next step, we need to think about one thing. In this experiment, business healthy state (steady state) is specified as cpu utilization and number of healthy pods. But after the first experiment, you will see the service does not work properly even though the monitoring indicators are in the normal range. It would be weird it is also meaningful. This result shows that unintended problems can occur even if the monitoring numbers are normal. It could be one of the experimental results that can be obtained through chaos engineering.

Go forward.

#### Architecture Improvements
Cluster Autoscaler is a tool that automatically adjusts the size of the Kubernetes cluster when one of the following conditions is true:
+ there are pods that failed to run in the cluster due to insufficient resources.
+ there are nodes in the cluster that have been underutilized for an extended period of time and their pods can be placed on other existing nodes.

Cluster Autoscaler provides integration with Auto Scaling groups. Cluster Autoscaler will attempt to determine the CPU, memory, and GPU resources provided by an EC2 Auto Scaling Group based on the instance type specified in its Launch Configuration or Launch Template. Click [here](https://github.com/kubernetes/autoscaler/tree/master/cluster-autoscaler/cloudprovider/aws) for more information.

Watch the logs to verify cluster autoscaler is installed properly. If everything looks good, we are now ready to scale our cluster.
```
kubectl -n kube-system logs -f deployment/cluster-autoscaler
```

Scale out pods and apply pod-anti-affinity policy for high availability.
```
kubectl apply -f manifests/sockshop-demo-ha.yaml
```

![aws-fis-eks-pod-anti-affinity](../../images/eks/aws-fis-eks-pod-anti-affinity.png)

#### Rerun Experiment
Back to the AWS FIS service page, and rerun the terminate eks nodes experiment against the target to ensure that the microservices application is working in the previously assumed steady state.

![aws-fis-sockshop-with-ha](../../images/eks/aws-fis-sockshop-with-ha.png)

### CPU Stress
AWS FIS allows you to test resiliency of EKS cluster node groups. See what happens on your application when your EKS nodes (ec2 instances) has very high CPU utilization. This test verifies that the application on the EKS managed node group works properly even with increased CPU utilization.

#### Run Experiment
Make sure that all your EKS node group instances are running. Go to the AWS FIS service page and select `CPUStress` from the list of experiment templates. Then use the on-screen `Actions` button to start the experiment. In this experiment, AWS FIS increases CPU utilization for half of the ec2 instances with the env=prod tag. You can change the target percentage of an experiment in the experiment template. To change the number of EKS nodes to which the CPU stress experiment will be applied, edit the filter or tag values in the target selection mode configuration in the template. After starting the experiment, you can see the CPU utilization increase on the EC2 service page or the CloudWatch service page.

![aws-fis-cpu-stress-eks-nodes-action-complete](../../images/eks/aws-fis-cpu-stress-eks-nodes-action-complete.png)

![aws-fis-cw-cpu](../../images/eks/aws-fis-cw-cpu.png)

![aws-fis-cw-cpu-alarm](../../images/eks/aws-fis-cw-cpu-alarm.png)

### Disk Stress
With this disk stress experiment, you can test if the alarm fires when there is not enough space on the compute node to write files(such as logs). This test verifies that you have set up an alarm to be raised when the disk utilization metric is greater than a threshold. See what happens to your application when the disk file system utilization on the EKS node (ec2 instance) is very high.

#### Define Steady State
Before we begin a failure experiment, we need to validate the user experience and revise the dashboard and metrics to understand that the systems are working under normal state, in other words, steady state. The goal of this experiment is to verify that the disk usage alarm works well when disk usage increases. So an alarm off state is our planned steady state.

#### Run Experiment
Make sure that all your EKS node group instances are running. Go to the AWS FIS service page and select `DiskStress` from the list of experiment templates. Then use the on-screen `Actions` button to start the experiment. In this experiment, AWS FIS increases Disk filesystem utilization for all ec2 instances with the env=prod tag. If you want, you can change the experiment targets in the experiment template. To change the number of EKS nodes to which the Disk stress experiment will be applied, edit the filter or tag values in the target selection mode configuration in the template. After starting the experiment, you can see the Disk filesystem utilization increase on the CloudWatch service page.

![aws-fis-disk-stress-eks-nodes-action-stopped](../../images/eks/aws-fis-disk-stress-eks-nodes-action-stopped.png)

![aws-fis-cw-disk](../../images/eks/aws-fis-cw-disk.png)

## Clean up
### Remove Application
Delete all kubernetes resources.
```
kubectl delete -f manifests/sockshop-demo-ha.yaml
kubectl delete -f manifests/sockshop-loadtest.yaml
```
### Remove Infrastructure
Run terraform:
```
terraform destroy
```
Don't forget you have to use the `-var-file` option when you run terraform destroy command to delete the aws resources created with extra variable files.
```
terraform destroy -var-file fixture.tc1.tfvars
```
