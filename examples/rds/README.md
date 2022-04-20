[[English](README.md)] [[한국어](README.ko.md)]

## Download example
Download this example on your workspace
```sh
git clone https://github.com/Young-ook/terraform-aws-fis
cd terraform-aws-fis/examples/rds
```

## Setup
[This](https://github.com/Young-ook/terraform-aws-fis/blob/main/examples/rds/main.tf) is an example of terraform configuration file to create AWS Fault Injection Simulator experiments for chaos engineering. Check out and apply it using terraform command.

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
## Docker LAMP
Docker example with Apache, MySql 8.0, PhpMyAdmin and Php (Linux, Apache, MySQL, PHP)
If you use docker-compose as an orchestrator. Run these containers:

```
docker-compose up -d
```

Open phpmyadmin at [http://localhost:8000](http://localhost:8000)
Open web browser to look at a simple php example at [http://localhost:8001](http://localhost:8001)

Run mysql client:

- `docker-compose exec db mysql -u root -p`

## Create Experiment Templates
This module automatically creates fault injection simulator experiment templates on your AWS account. Move to the AWS FIS service page on the AWS Management Conosol and select Experiment templates menu on the left. Then users will see the created experiment templates for chaos engineering.

![aws-fis-experiment-templates](../../images/rds/aws-fis-experiment-templates.png)

## Run Experiments
To test your environment, select a experiment template that you want to run and click the `Actions` button on the right top on the screen. You will see `Start experiment` in the middle of poped up menu and select it. And follow the instructions.

### Failover DB Cluster
AWS FIS allows you to test resilience of Aurora DB cluster.

#### Update kubeconfig
Update and download kubernetes config file to local. You can see the bash command like below after terraform apply is complete. Copy this and run it to save the kubernetes configuration file to your local workspace. And export it as an environment variable to apply to the terminal.
```
bash -e .terraform/modules/eks/script/update-kubeconfig.sh -r ap-northeast-2 -n aurora-fis -k kubeconfig
export KUBECONFIG=kubeconfig
```

#### Define Steady State
Before we begin a failure experiment, we need to validate the user experience and revise the dashboard and metrics to understand that the systems are working under normal state, in other words, steady state.

#### Run Experiment
Go to the AWS FIS service page and select `FailoverDBCluster` from the list of experiment templates. Then use the on-screen `Actions` button to start the experiment.

![aws-rds-aurora-cluster-failover-state](../../images/rds/aws-fis-aurora-cluster-failover-state.png)

![aws-rds-aurora-cluster-normal-state.png](../../images/rds/aws-fis-aurora-cluster-normal-state.png)

## Clean up
Run terraform:
```
terraform destroy
```
Don't forget you have to use the `-var-file` option when you run terraform destroy command to delete the aws resources created with extra variable files.
```
terraform destroy -var-file fixture.tc1.tfvars
```
