[[English](README.md)] [[한국어](README.ko.md)]

# Chaos Engineering
Chaos engineering is the discipline of experimenting on a distributed system in order to build confidence in the system's capability to withstand turbulent and unexpected conditions in production. If you want know why and how to do chaos engineering, please refer to this [page](https://github.com/Young-ook/terraform-aws-fis/blob/main/README.md).

## Download example
Download this example on your workspace
```sh
git clone https://github.com/Young-ook/terraform-aws-fis
cd terraform-aws-fis/examples/ec2
```

## Setup
[This](https://github.com/Young-ook/terraform-aws-fis/blob/main/examples/ec2/main.tf) is an example of terraform configuration file to create AWS Fault Injection Simulator experiments for chaos engineering. Check out and apply it using terraform command.

If you don't have the terraform tools in your environment, go to the main [page](https://github.com/Young-ook/terraform-aws-fis#terraform) of this repository and follow the installation instructions.

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

## Run Fault Injection Experiments
This module automatically creates fault injection simulator experiment templates on your AWS account. Move to the AWS FIS service page on the AWS Management Console and select Experiment templates menu on the left. Then you will see the created experiment templates for chaos engineering. To test your environment, select a experiment template that you want to run and click the `Actions` button on the right top on the screen. You will see `Start experiment` in the middle of poped up menu and select it. And follow the instructions.

![aws-fis-experiment-templates](../../images/ec2/aws-fis-experiment-templates.png)

### Run Load Generator
Terraform configuration also creates a load generator autoscaling group for your application instances. When running, this load generator instance runs a load generator script that repeatedly sends http requests to the application load balancer. After running the terraform apply command, you will see the terraform output as below. That is an example of `loadgen` script created by terraform.

```
#!/bin/bash
while true; do
  curl -I http://my-loadbalancer-1234567890.us-west-2.elb.amazonaws.com
  echo
  sleep .5
done
```

Before you begin the first chaos engineering experiment, must run the load generator script. Select the whole `loadgen` terraform output andcopy it, then access the load generator ec2 instance via systems manager (session manager). And save the copied text as a new bash script to `loadgen.sh` on the load generator instance. Run the script:
```
./loadgen.sh
```

If you don't know how to access a ec2 instance through session manager, please refer to [this guide](https://github.com/Young-ook/terraform-aws-ssm/blob/main/README.md#connect)

This step is very important because it warms up the instances for cloudwatch metrics. After few minutes, all cloudwatch alarms will be chaged to *OK* status from *Insufficient data* in minutes after the load generator script running.

### Network Latency
This test will inject network latency to target instances. A response from the instance will be delayed in specified milisecond defined in the experiment template. To run this example, follow belows.

1. Move on the EC2 service page. Press the `Instances (running)` to switch the screen to show the list of running instances.
1. Select a ec2 instance of autoscaling group that you created by this module. Maybe its name looks like ssm-fis-tc1.
1. Click `Connect` button and choose `Session` tab to access the instance using AWS Session Manager. And finally press the orange `Connect` button and go.
1. You are in the instance, run ping test to the others in the same autoscaling group.
1. Back to the FIS page, Select `NetworkLatency` template in the experiment templates list. Click the `Actions` and `Start experiment` button to start a new chaos experiment.
1. See what happens in the ping logs. The latency will be increased.

![aws-fis-ec2-network-latency](../../images/ec2/aws-fis-ec2-network-latency.png)

#### Define Steady State
First of all, we need to define steady state of the service. This means the service is healthy and working well. We use ‘p90’ to refer to the 90th percentile data; that is, 90% of the observations fall below this value. Percentiles for p90, p95, p99, p99.9, p99.99 or any other percentile from 0.1 to 100 in increments of 0.1% (including p100) of request metric can now be visualized in near real time. We will use this alarm for stop condition of fault injection experiment.

**Steady State Hypothesis Example**

+ Title: Services are all available and healthy
+ Type: What are your assumptions?
   - [ ] No Impact
   - [ ] Degraded Performance
   - [ ] Service Outage
   - [ ] Impproved Performance
+ Probes:
   - Type: CloudWatch Metric
   - Status: `p90`
+ Stop condition (Abort condition):
   - Type: CloudWatch Alarm
   - Status: `p90`
+ Results:
   - What did you see?
+ Conclusions:
   - [ ] Everything is as expected
   - [ ] Detected something
   - [ ] Handleable error has occurred
   - [ ] Need to automate
   - [ ] Need to dig deeper

#### Stop Condition
This scenario shows how to abort an experiment when an emergency alert is raised. This is a very important feature for reducing customer impact during chaotic engineering of production systems. Some experiments have a lot of impact on customers during fault injection. If the application goes wrong, the experiment must be stopped autumatically.

##### Update Alarm Source
To test stop condition with cloudwatch alarm, we have to replace the stop condition with p90 latency alarm on the edit page of experiment template on the AWS management console.  This alarm means that our application has latency issues with user responses.

1. Move on the FIS service page.
1. Select `experiment templates` on the navigation bar.
1. Find out `NetworkLatency` template from the list and select.
1. Click `Actions` button and select `Update experiment template` menu to update the template configuration.
1. Scroll down to the bottom of edit page. And update the stop condition alarm to `blahblah-p90-alarm` and save.

![aws-fis-stop-condition-update-p90](../../images/ec2/aws-fis-stop-condition-update-p90.png)

#### Run Experiment
We are now ready to start network latecy fault injection and test the emergency stop of aws fault injection simulator is working well to reduce the customer impact. Go to the AWS FIS service page and select `NetworkLatency` from the list of experiment templates. Then use the on-screen `Actions` button to start the experiment. AWS FIS injects network latency into the target, which are the EC2 instances we configured in the experiment template. This will delay all requests from the load generator executed in the previous step by 100ms. This experiment is automatically stopped when the p90 latency alarm is triggered.

![aws-fis-api-latency-alarm-p90](../../images/ec2/aws-fis-api-latency-alarm-p90.png)

![aws-fis-ec2-network-latency-action-stop](../../images/ec2/aws-fis-ec2-network-latency-action-stop.png)

#### Architecture Improvements
##### Adjust Targets
After the emergency button test, A new experiment can be started to prove the hypothesis that even if one of the servers in the cluster suddenly slows down, the entire application service can respond within an average of 100 ms.

1. Move on the AWS FIS service page.
1. Select `experiment templates` on the navigation bar.
1. Find out `NetworkLatency` template from the list and select.
1. Click `Actions` button and select `Update experiment template` menu to update the template configuration.
1. Scroll down to `Targets` configuration. And select ec2-instances(aws:ec2:instance) item. Expands the item and click *Edit* button.
1. On the edit target popup window, changed the selection mode with `Count` and set the value of `Number of resources` to 1.
1. Save and close.

![aws-fis-target-selection-mode-count](../../images/ec2/aws-fis-target-selection-mode-count.png)

##### Scale-out Nodes
Increase the capacity of the ec2 autoscaling group to distribute requests from the load balancer. This will help reduce p90 latency by distributing the load when aws fis creates network latency situations for the target.

1. Go to the Amazon EC2 service page.
1. Select `Autoscaling group` on the bottom of left hand navigation bar.
1. On the Auto Scaling groups page, select the check box next to the Auto Scaling group whose settings you want to manage. The name is something like this `ssm-fis-xxxx`. A split pane opens up in the bottom part of the Auto Scaling groups page, showing information about the group that's selected.
1. In the lower pane, in the Details tab, view or change the current settings for minimum, maximum, and desired capacity.
1. Update the desired and maximum capacity to 9.

#### Rerun Experiment
Back to the AWS FIS service page, and rerun the network latency experiment against the updated target to ensure that the API response is in the previously assumed steady state. In this case, the p90 delay alarm is not triggered. That is, 90% of the data points for latency are faster than the threshold. Therefore this experiment will be completed normaly.

![aws-fis-ec2-network-latency-action-complete](../../images/ec2/aws-fis-ec2-network-latency-action-complete.png)

#### Clean up
Restore desired capacity of the autoscaling group for next step.

1. Go to the Amazon EC2 service page.
1. Select `Autoscaling group` on the bottom of left hand navigation bar.
1. On the Auto Scaling groups page, select the Auto Scaling group you want to adjust.
1. Restore maximum and desired capacity. Set the desired capacity to 2 and the maximum capacity to 6. Save.

### CPU Stress
When you successfully start the CPU stress experiment, the CPU utilization of some target instances increases. You can view this metric on the Monitoring tab displayed when the user selects an ec2 instance, or on the CloudWatch service page.

#### Define Steady State
Before we begin creating failures, a starting point would be to understand the steady state of your application. This includes validating the user experience and revising your dashboard and metrics to understand your systems are operating under normal conditions. Check the monitoring metrics and alarms for API response and CPU utilization on the AWS cloudwatch. If everything looks fine, you can start from there.

##### Update Alarm Source
For this CPU stress experiment, we need to roll back the alarm configuration to its previous state. This alert means that the application's CPU usage is very high and the application is slow.

1. Move on the FIS service page.
1. Select `experiment templates` on the navigation bar.
1. Find out `CPUStress` template from the list and select.
1. Click `Actions` button and select `Update experiment template` menu to update the template configuration.
1. Scroll down to the bottom of edit page. And update the stop condition alarm to `blahblah-cpu-alarm` and save.

#### Run Experiment
Run `CPUStress` experiment. Let's see the target tracking policyfor EC2 autoscaling group is working well. With target tracking scaling policies, you select a scaling metric and set a target value. EC2 Auto Scaling creates and manages the CloudWatch alarms that trigger the scaling policy and calculates the scaling adjustment based on the metric and the target value. The scaling policy adds or removes capacity as required to keep the metric at, or close to, the specified target value. In addition to keeping the metric close to the target value, a target tracking scaling policy also adjusts to changes in the metric due to a changing load pattern.

#### Comparative experiment
Remove the target tracking policy from the EC2 Autoscaling group to test what happens when there is a spike in CPU usage. The average value of CPU utilization will continue to increase. Probably because there is no policy to add more server resources to spread the workload. To test the hypothesis defined in the previous step, we reuse the AWS FIS experiment to inject a CPU stress situation.

### Terminate EC2 Instances
AWS FIS allows you to test resilience based on ec2 autoscaling group. See what happens when you terminate some ec2 instances in a specific availability zone. This test will check if the autoscaling group launches new instances to meet the desired capacity defined. Use this test to verify that the autoscaling group overcomes the single availability zone failure.

#### Define Steady State
#### Run Experiment

### Throttling AWS API
When running API throttling test, you can see the throttling error when you call the AWS APIs (e.g., DescribeInstances) in the target ec2 instance.

1. Move on the EC2 service page. Press the `Instances (running)` to switch the screen to show the list of running instances.
1. Select a ec2 instance of autoscaling group that you created by this module. Maybe its name looks like ssm-fis-tc1.
1. Click `Connect` button and choose `Session` tab to access the instance using AWS Session Manager. And finally press the orange `Connect` button and go.
1. You are in the instance, run aws command-line interface (cli) to describe instances where region you are in.
1. First try, you will see `Unauthorized` error.
1. Back to the FIS page, Select `ThrottleAPI` template in the experiment templates list. Click the `Actions` and `Start experiment` button to start a new chaos experiment.
1. Then you will see the changed error message when you run the same aws cli. The error message is API Throttling.

Following screenshot shows how it works. First line shows the request and reponse about ec2-describe-instances api using AWS CLI. The error message is `Unauthorized` because the target role the instance has does not have right permission to describe instances. And second line is the reponse of the same AWS API call when throttling event is running. You will find out that the error message has been changed becuase of fault injection experiment.

![aws-fis-throttling-ec2-api](../../images/ec2/aws-fis-throttling-ec2-api.png)

### Disk Stress

![aws-fis-ec2-disk-stress-metrics](../../images/ec2/aws-fis-ec2-disk-stress-metrics.png)
![aws-fis-ec2-disk-stress](../../images/ec2/aws-fis-ec2-disk-stress.png)

## Clean up
Run terraform:
```
terraform destroy
```
Don't forget you have to use the `-var-file` option when you run terraform destroy command to delete the aws resources created with extra variable files.
```
terraform destroy -var-file fixture.tc1.tfvars
```
