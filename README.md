# A quest in the clouds

## Usage
Upon pushing a commit to Github the following will occur:
1. The app will be packaged into a docker container using a Github action.
1. A Github action will run to use Terraform provision a VPC, subnets, and EKS cluster, as well as the Elastic Beanstalk Docker application, environment, and application version. Finally it will also provision a security group and and EC2 instance to launch into it, a security group for an ELB, and an ELB to front the EC2 instance with HTTP and HTTPS listeners.
1. The same Github action will run another Terraform command to deploy the application to the EKS cluster using helm.

## Takeaways
Given more time I would separate the IaC and app/Helm into separate repos with separate deployment flows.

I started this solution using EKS hoping that by running the container in privileged mode it would satisfy items 1, 3, and 5 immediately, not knowing how your binaries work. Unfortunately that didn't work as the do not access the underlying instance when using Docker and do not detect that they are in a Docker container when running in EKS as it is not Docker. I left the EKS cluster provisioning and Helm chart to show my capabilities.

From there I added an Elastic Beanstalk deployment to satisfy the Docker portion.

After that I added Elastic Beanstalk for Node.js to get the secret word but that also did not work. So I simply created and instance to get the secret word. That didn't work either and I realized it's because your binaries don't work with AWS Linux 2023. I removed this later on as I did not need it and I already had an Elastic Beanstalk instance to show my capabilities.

After that I launched an Ubuntu instance to get the secret word and wrote terraform to launch an instance running a Docker container I built with the Secrete Word as an environment variable and and ELB in front of it with a self-signed certificate set on a listner.


![alt Success!](https://raw.githubusercontent.com/esser-labs/rearc-quest/main/Success.png)
