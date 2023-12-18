# Hackathon 2022

## Welcome to Tikal Hackathon 2022
This repo provides basic infrastructure and services,
as well as an example Python workload deployed on EKS using GitLab pipeline.

This repository is an example, or structure that works out of the box: this does
not necessarily mean that you have to use it as-is. Your team has the freedom to change whatever you want.

Let's get started!

---

## Requirements

### Git
Instllation instruction [here](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)

### Terraform
Version 1.4.3 or later. [Installation instructions](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)

### Cloudfairy CLI
Cloudfairy version 0.1.16

Installation: `npm i -g @cloudfairy/cli`

> Requires [nodejs 16.14 or later and npm](https://nodejs.org/en/download/package-manager/) installed

### Helm (optional)
```shell
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
helm completion bash > /etc/bash_completion.d/helm
```

### Kubectl (optional)
```shell
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
echo 'source <(kubectl completion bash)' >>~/.bashrc
kubectl completion bash >/etc/bash_completion.d/kubectl
```

### Terragrunt (optional)
Version v0.38.2 or later

> This is optional, in case we need to debug the deployment process. [Installation instructions](https://terragrunt.gruntwork.io/docs/getting-started/install/)

---

## This repository structure.
1. [argocd](argocd) - Hold Helm Chart releases for system components and cluster add-ons, deployed using ArgoCD ApplicationSet
   1. [applications](argocd/applications) - ArgoCD Applications
   1. [releases](argocd/releases) - Helm Chart releases
      1. [cluster-addons](argocd/releases/cluster-addons) - K8S Cluster Addons (keda autoscaling, prometheus, grafana, loki, etc...)
      1. [system-components](argocd/releases/system-components) - K8S System Components (Cluster autoscaler, nginx ingress, cert-manager, etc...)
1. [terraform](terraform)
   1. [cloudfairy](terraform/cloudfairy) - Cloudfairy's hackathon library to get you started real quick
   1. [modules](terraform/modules) - TF modules for AWS EKS and various services (sqs, s3, efs, etc...)
   1. [projects](terraform/projects) - Projects for dedicated VPC and EKS cluster
1. [flask-celery](flask-celery) - Example Python project deployed on EKS with GitLab pipelines & ArgoCD
1. [backstage](backstage) - Scaffoled backstage app. [Documentation.](https://backstage.io/docs/overview/what-is-backstage)

> Important: for the included ci-cd pipeline to work, do not change the structure of the folders.

---

# Architecture and deployment with _cloudfairy_
> Cloudfairy is a cli tool that helps you design your application and generate terraform/terragrunt files for your deployment.

Assume our product consists of the following components:

1. Backstage (Web server and frontend)
1. Your own backend service "`Hackstage`"
1. Postgres (used by backstage)
1. Redis server (used by Hackstage)

```
              ┌────────────┐      ┌────────────┐
              │            │      │            │
Internet ─────► Backstage  │──────►  Postgres  │
Access        │            │      │            │
              └────────────┘      └────────────┘
                    │
                    │
                    │
              ┌─────▼──────┐      ┌────────────┐
              │            │      │            │
              │  Hackstage │──────►  Redis     │
              │            │      │            │
              └────────────┘      └────────────┘
```

We can now create our infrastructure with cloudfairy the following way:

> Use the repository path `terraform` as your working directory

## Initialize cloudfairy for the first time
```bash
# Initialize cloudfairy for the first time on the developer machine
# If not already installed: npm i -g @cloudfairy/cli
fairy init

# Make sure we are working the correct directory
# <path/to/repo>/terraform
cd terraform

# Let us select the hackathon library as default for quick development
cd cloudfairy
fairy lib add hackinfra $(pwd)
cd ..
fairy lib set-default hackinfra
```

## Let's start designing our project
```bash
# <path/to/repo>/terraform

# Initialize a new cloudfairy project
fairy project init
# Name your project "group<YOUR-GROUP-NUMBER>". Example "group07".

# now we have a cloudfairy.project.json file without any data
# Let's start adding our components

fairy project add-component
# Select from the menu "hackinfra/deployment - Docker deployment"
# We shall name it "backstage",
# expose port 80,
# and choose "true" for ingress (we need internet access)

# Let's add postgres (shorthand for project is "p", add-component is "add")
fairy p add
# Select postgres and provide your information. Let's name it "database".

# Let's add redis
fairy p add
# At this point you should already know what to do...

# Let's add our custom "Hackstage" backend service
fairy p add
# Again we will select "hackinfra/deployment - Docker deployment"
# Expose the port matching our code, and we do not allow internet access

# Lets us see the list of our components
fairy p

# We expect to see output such as
Project Info: group07
Components: 4
┌──────────────────┬───────────┬──────────────────────┬──────────────┐
│ ID               │ Name      │ Type                 │ Connected to │
├──────────────────┼───────────┼──────────────────────┼──────────────┤
│ 9642a9e71e82e1e4 │ backstage │ hackinfra/deployment │              │
│ 338f8b8218729c26 │ hackstage │ hackinfra/deployment │              │
│ f5cc12dace20bf6d │ redis     │ hackinfra/redis      │              │
│ a00637bfeb38f333 │ database  │ hackinfra/postgres   │              │
└──────────────────┴───────────┴──────────────────────┴──────────────┘

```

## Connect backstage to postgres, and our backend to redis
```bash
fairy p connect backstage database
# Cloudfairy will ask us to provide names of the environment variables that points to postgres, the username and password. Choose whatever works for us, remember to configure it later in backstage configuration file.

fairy p connect backstage hackstage
# Environment variable points to "hackstage"'s internal address.

fairy p connect hackstage redis
# Same here for environment variables...
```

## Make sure everything is set
```bash
fairy p ls

# We expect to see something like this:
Project Info: group07
Components: 4
┌──────────────────┬───────────┬──────────────────────┬───────────────────┐
│ ID               │ Name      │ Type                 │ Connected to      │
├──────────────────┼───────────┼──────────────────────┼───────────────────┤
│ 9642a9e71e82e1e4 │ backstage │ hackinfra/deployment │database,hackstage │
│ 338f8b8218729c26 │ hackstage │ hackinfra/deployment │             redis │
│ f5cc12dace20bf6d │ redis     │ hackinfra/redis      │                   │
│ a00637bfeb38f333 │ database  │ hackinfra/postgres   │                   │
└──────────────────┴───────────┴──────────────────────┴───────────────────┘
```

## Important: Set the cloud provider credentials
Use the credentials provided to you by admin, or ask team leader.
Your remote state bucket is: `tikal-hackathon2022-group07-tf-state` (you will be prompted for this)

```bash
fairy project set-cloud-provider
# Choose AWS
# Fill in the details
```

When we commit our `cloudfairy.project.json`, the pipeline will generate terraform/terragrunt and apply all the changes.

> Please note that for the first run it might take a while. Creating network, clusters and other infrastructure might take even 30 minutes. Be patient and let the automation deal with it.

## Architecture changes
Since the architecture and cloud infrastructure is managed with cloudfairy, it is recommended to use the cli for changes.
For help, type `fairy project help` or `fairy help` for other commands.

You can reconfigure components, remove them or add new ones.

Ensure the file `cloudfairy.project.json` is committed with the changes for the automation to take place. Changes might take time depending on their nature.

## Connect to cluster
```shell
aws --region eu-west-1 eks update-kubeconfig --name group07 --alias group07
kubectl config use-context tikal-hack
kubectl version
```

---

# Additional information

## Docker Registry
Due to Docker Hub rate limits we advise using [Quay](https://quay.io/)
or [ECR Public Gallery](https://gallery.ecr.aws/) to avoid issues.  
To pull images from your [private registry](https://gitlab.com/tikalk.com/fuse/hackathon-2022/group07/group07/container_registry) 
you can use the image pull secret named `gitlab-docker-pull` (created by Terraform):  
```yaml
apiVersion: apps/v1
kind: Deployment
#[...]
spec:
  replicas: 1
  selector:
    #[...]
  template:
    #[...]
    spec:
      imagePullSecrets:
        - name: gitlab-docker-pull
      containers:
        #[...]
```

## Logs & Monitoring
The cluster comes prepared with Prometheus/Grafana/Loki for logs and metrics,
accessible at https://grafana.group07.hack22.tikalk.dev

## HTTPS
We use cert-manager and LetsEncrypt to provide ssl certificates,
the ingress controller is configured with a default wildcard certificate:
`*.group07.hack22.tikalk.dev`.

To use this certificate with ingress resources just omit the `secretName` key:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
#[...]
spec:
  rules:
    - host: service.example.com
  #[...]
  tls:
    - hosts:
        - service.example.com
      #secretName omitted to use default wildcard certificate
```
