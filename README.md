# GitOps example

It prepare for educational purpose about the GitOps methodology in the praktice. 

## Description

A little game to present a the GitOps.

The plan to easy to understand and lean more about the GitOps.  
This will show, how can anybody create a simple flow with a simple app. The goal is to create a simple web server with automated  deployment.

GitOps are not equal with these softwares only. You can use your favorite solutions for git GitHub, Gitlab, BitBucket etc. You can use ArgoCD instead of FluxCD. So lot of different solution are on the internet to apply GitOps methodology on your system. In this current case we will use the Kubernetes as infrastructure. 

Enviroment:

- GitHub
- Kubernetes with Kustomization

Used softwares to reach the goal:

- FluxCD
- Helm
- Kustomize
- kubectx + kubens
- k9s

The solution will work on this way.

User send a git commit. FluxCD will be check it via the source controller` FluxCD component. If it has a new commit try to apply it on the system. The Kustomization supported by Kubernetes default. The Kustomize controller will update the configurtion on Kubernetes elements (Configmaps, Secrects, Deployments, Pods, Services etc.). The deployment with the new config will be done by Helm controller.

I will be use the Flux word instead of the FluxCD in my documentation. Please keep in your mind. 

## Requirements

Please install the following components as pre-requisites

Optional: If you like the easiest way, just install Homebrew and install every requirements with it on Linux.  
Homebrew install guide: [https://docs.brew.sh/Homebrew-on-Linux](https://docs.brew.sh/Homebrew-on-Linux)

Mandatory components:

- Git client  
  Official install guide: [https://git-scm.com/book/en/v2/Getting-Started-Installing-Git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)
- Docker  
  Official install guide: [https://docs.docker.com/get-docker/](https://docs.docker.com/get-docker/)
- docker-compose  
  Official install guide [https://docs.docker.com/compose/install/](https://docs.docker.com/compose/install/)
- Minikube (Kubernetes in Docker)  
  Official install guide: [https://minikube.sigs.k8s.io/docs/start/](https://minikube.sigs.k8s.io/docs/start/)
- FluxCD CLI tool  
  Official install guide: [https://fluxcd.io/docs/installation/](https://fluxcd.io/docs/installation/)
- Helm CLI tool  
  Official install guide: [https://helm.sh/docs/intro/install/#through-package-managers](https://helm.sh/docs/intro/install/#through-package-managers)
- Kubectx and kubens  
  Official install guide: [https://github.com/ahmetb/kubectx](https://github.com/ahmetb/kubectx)
- K9s (terminal GUI tool for Kubernetes)  
  Officail install guide: [https://k9scli.io/topics/install/](https://k9scli.io/topics/install/)   

## Pre-requisites verfication

Please check all of the command is available after the installation. If the version numbers are different (newer, than the examples, it is okay.)

1. Git client

    ```bash
    git --version
    ```

    Sample command output:
    
    ```bash
    git version 2.17.1
    ```

1. Docker

    ```bash
    docker version
    ```
    
    Sample command output:
    
    ```bash
    Client: Docker Engine - Community
    Version:           20.10.12
    API version:       1.41
    Go version:        go1.16.12
    Git commit:        e91ed57
    Built:             Mon Dec 13 11:45:27 2021
    OS/Arch:           linux/amd64
    Context:           default
    Experimental:      true

    Server: Docker Engine - Community
    Engine:
    Version:          20.10.12
    API version:      1.41 (minimum version 1.12)
    Go version:       go1.16.12
    Git commit:       459d0df
    Built:            Mon Dec 13 11:43:36 2021
    OS/Arch:          linux/amd64
    Experimental:     true
    containerd:
    Version:          1.4.12
    GitCommit:        7b11cfaabd73bb80907dd23182b9347b4245eb5d
    runc:
    Version:          1.0.2
    GitCommit:        v1.0.2-0-g52b36a2
    docker-init:
    Version:          0.19.0
    GitCommit:        de40ad0
    ```

1. Docker compose

    ```bash
    docker-compose version
    ```
    
    Sample command output:
    
    ```bash
    docker-compose version 1.27.4, build 40524192
    docker-py version: 4.3.1
    CPython version: 3.7.7
    OpenSSL version: OpenSSL 1.1.0l  10 Sep 2019
    ```

1. Minikube (Kubernetes in Docker)

   ```bash
    minikube version
    ```  
    
    Sample command output:
    
    ```bash
    minikube version: v1.24.0
    commit: 76b94fb3c4e8ac5062daf70d60cf03ddcc0a741b
    ```

1. FluxCD CLI tool 

    ```bash
    flux --version
    ```
    
    Sample command output:
    
    ```bash
    flux version 0.24.1
    ```

## Clone this git repo to your machine (optional)

1. Create a `git` folder in your home directory

    ```bash
    mkdir git
    ```

1. Clone this repo to your machine

    ```bash
    git clone https://github.com/<your username>/gitops-demo.git
    ```
1. Enter the cloned code

    ```bash
    cd gitops-demo
    ```

## Create a kubernetes cluster

1. Run `minikube` command

    ```bash
    minikube start
    ```

    Sample output:

    ```bash
    😄  minikube v1.24.0 on Ubuntu 18.04
    ✨  Automatically selected the docker driver. Other choices: kvm2, virtualbox, ssh, none
    ❗  docker is currently using the aufs storage driver, consider switching to overlay2 for better performance
    👍  Starting control plane node minikube in cluster minikube
    🚜  Pulling base image ...
    > gcr.io/k8s-minikube/kicbase: 355.78 MiB / 355.78 MiB  100.00% 9.54 MiB p/
    🔥  Creating docker container (CPUs=2, Memory=3900MB) ...
    > kubeadm.sha256: 64 B / 64 B [--------------------------] 100.00% ? p/s 0s
    > kubelet.sha256: 64 B / 64 B [--------------------------] 100.00% ? p/s 0s
    > kubectl.sha256: 64 B / 64 B [--------------------------] 100.00% ? p/s 0s
    > kubectl: 44.73 MiB / 44.73 MiB [-------------] 100.00% 14.98 MiB p/s 3.2s
    > kubeadm: 43.71 MiB / 43.71 MiB [--------------] 100.00% 4.54 MiB p/s 9.8s
    > kubelet: 115.57 MiB / 115.57 MiB [------------] 100.00% 11.53 MiB p/s 10s

        ▪ Generating certificates and keys ...
        ▪ Booting up control plane ...
        ▪ Configuring RBAC rules ...
    🔎  Verifying Kubernetes components...
        ▪ Using image gcr.io/k8s-minikube/storage-provisioner:v5
    🌟  Enabled addons: default-storageclass, storage-provisioner
    🏄  Done! kubectl is now configured to use "minikube" cluster and "default" namespace by default
    ```
1. Enable metrics for CPU and memory usage (optional)

    ```bash
    minikube addons enable metrics-server
    ```
    Sample output:

    ```bash
       ▪ Using image k8s.gcr.io/metrics-server/metrics-server:v0.4.2
    🌟  The 'metrics-server' addon is enabled
    ```
## Create a personal access token

You need to create a personal access token on GitHub, because your password cannot be used with FluxCD later (and it will be not so safe)

Official guide to access token creation: [https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token)

Feel free to define the token name. (example: fluxdemo)
The repo and the user only enough for this token.

## Flux preparation steps

### Create your repository on GitHub

1. Click on top right on **`"+"`** icon and chhose the new repository
1. Fill the repository name: `flux-demo`
1. Check the checkbox before the text: `Add a README file`
1. Click on `Create repository` button (bottom of the page)

### Clone your repository to your device

1. Open a terminal (command line)
1. Enter the `git` directory (if you are not there already)
    ```bash
    cd ~/git
    ```

1. Clone the repository to your folder
    
    Replace `"<your username>"` with your username

    ```bash
    git clone https://github.com/<your username>/flux-demo.git
    ```

1. Enter the direytory

    ```bash
    cd flux-demo
    ```
1. Create a new branch for test

    ```bash
    git checkout -b demo1
    ```

## Prepare FluxCD for first use

All of the command need to run inthe git repo folder.  
Default: ~/.git/flux-demo

1. Create directory structure:

Use this command to create the directory structure:
Note: It will not work maybe on Windows.

```bash
mkdir -p apps/{base,prod,stg,dev} \
         clusters/{prod,stg,dev} \
         infrastructure/{base,prod,stg,dev} \
         infrastructure/base/sources \ 
         flux-init/
```

More information about the structure: [https://fluxcd.io/docs/guides/repository-structure/](https://fluxcd.io/docs/guides/repository-structure/)

The `"sources"` directory will contains the Helm chart repository definitions. I assume we will use all of the sources in all environment. If you would like to separate it, maybe possible to create a `"sources"` directory inside of each environment specifc directory.

Sample result of tree command:

```bash
├── apps
|   ├── base
|   ├── prod
|   ├── stg
│   └── dev
├── clusters
|   ├── prod
|   ├── stg
│   ├── dev
|   └── sources
├── flux-init
└── infrastructure
    ├── base
    ├── prod
    ├── stg
    └── dev
```

## Create Flux code

### Introduction

We will work only with the **`"dev"`** environment. Feel free to practice on the other environments.

Hints for file exiting. It will be used **vi** and after every commands need to be hit the Enter key.

If you prefer different editor feel free to use it.

### Creation steps

All of the command need to run inthe git repo folder.  
Default: ~/.git/flux-demo

We are creating the Flux deployment for Kubernetes

1. Create namespace configuration file

    Note: `ns` - Namespace

    ```bash
    vi flux-init/namespace.yaml
    ```

    Enable file edit with `insert` key or `i` key

    Add the following contect to the file

    ```yaml
    apiVersion: v1
    kind: Namespace
    metadata:
      name: flux-ns
    ```
    
    Save file with `:wq`

1. Create role configuration

    This role will be guaranteed the access to the Kubernetes objects.


    ```bash
    vi flux-init/role.yaml
    ```

    Enable file edit with `insert` key or `i` key

    Add the following contect to the file

    ```yaml
    apiVersion: rbac.authorization.k8s.io/v1
    kind: Role
    metadata:
      name: flux-role
      namespace: flux-ns
    rules:
    - apiGroups: ["apiextensions.k8s.io"]
      resources: ["customresourcedefinitions"]
      verbs: ["list", "watch"]
    - apiGroups: [""]
      resources: ["namespaces"]
      verbs: ["list"]
    - apiGroups: [""]
      resources: ["secrets"]
      verbs: ["get", "list", "watch"]
    - apiGroups: [""]
      resources: ["serviceaccounts"]
      verbs: ["get", "list", "watch"]
    - apiGroups: ["helm.fluxcd.io"]
      resources: ["helmreleases"]
      verbs: ["*"]
    ```
    
    Save file with `:wq`

1. Create role-binding configuration

    This will be assign the role with the service account.

    ```bash
    vi flux-init/role-binding.yaml
    ```

    Enable file edit with `insert` key or `i` key

    Add the following contect to the file

    ```yaml
    apiVersion: rbac.authorization.k8s.io/v1
    kind: RoleBinding
    metadata:
      name: flux-sa-rb
      namespace: flux-ns
    roleRef:
      apiGroup: rbac.authorization.k8s.io
      kind: Role
      name: flux-role
    subjects:
    - name: flux-sa
      namespace: flux-ns
      kind: ServiceAccount
    ```
    
    Save file with `:wq`

1. Create cluster role configuration

    This role will descirbe the right to the cluster.

    ```bash
    vi flux-init/cluster-role.yaml
    ```

    Enable file edit with `insert` key or `i` key

    Add the following contect to the file

    ```yaml
    apiVersion: rbac.authorization.k8s.io/v1
    kind: ClusterRole
    metadata:
      name: flux-cr
    rules:
    - apiGroups:
      - apiextensions.k8s.io
      resources:
      - customresourcedefinitions
      verbs:
      - list
      - watch
    - apiGroups:
      - ""
      resources:
      - namespaces
      verbs:
      - list
    ```
    
    Save file with `:wq`

1. Create cluster role binding configuration

    This will assign the cluster role with the service account.

    ```bash
    vi flux-init/cluster-role-binding.yaml
    ```

    Enable file edit with `insert` key or `i` key

    Add the following contect to the file

    ```yaml
    apiVersion: rbac.authorization.k8s.io/v1
    kind: ClusterRoleBinding
    metadata:
      name: flux-crb
    roleRef:
      apiGroup: rbac.authorization.k8s.io
      kind: ClusterRole
      name: flux-cr
    subjects:
    - name: flux-sa
      namespace: flux-ns
      kind: ServiceAccount
    ```
    
    Save file with `:wq`

1. Create kustomization configuration

    This will call the previous configuration in the defined order and apply it.

    ```bash
    vi flux-init/kustomization.yaml
    ```

    Enable file edit with `insert` key or `i` key

    Add the following contect to the file

    ```yaml
    apiVersion: kustomize.config.k8s.io/v1beta1
    kind: Kustomization
    resources:
    - role.yaml
    - role-binding.yaml
    - cluster-role.yaml
    - cluster-role-binding.yaml
    - namespace.yaml
    ```
    
    Save file with `:wq`

1. Verify your files are correct and ready to deploy them

    ```bash
    kubectl apply -k flux-init/ --dry-run=client
    ```

    Sample output:

    ```bash
    namespace/flux-ns configured (dry run)
    role.rbac.authorization.k8s.io/flux-role configured (dry run)
    clusterrole.rbac.authorization.k8s.io/flux-crd configured (dry run)
    rolebinding.rbac.authorization.k8s.io/flux-sa-rb configured (dry run)
    clusterrolebinding.rbac.authorization.k8s.io/flux-crb configured (dry run)
    ```

1. Push your code to the GitHub

    ```bash
    git push -u origin demo1
    ```

## Deploy FluxCD

1. Deploy the FluxCD roles on Kubernetes

    ```bash
    kubectl apply -k flux-init/
    ```
1. Bootstrap the FluxCD

    Create a connection between the FluxCD and the Git repository via SSH. If you are using GitHub, Gitlab or Bitbucket please see the [FluxCD documentation bootstrap section](https://fluxcd.io/docs/cmd/flux_bootstrap/) about the possibilities.

    Some words about the parameters:

    - HTTPS will be used for the communication
    - Owner is your username every time
    - Repository cover your repository name (`"flux-demo"`)
    - Branch is your branch that you are already created above.
    - PATH will be define which environment is deployed here
    - Private means your repo will configured as public (and not private)
    - Personal define the owner is a user and not an organization
    - Namespace parameter is telling which namespace are prepaed to flux (basically it is optional in thiss case, because all of the config file contains the namespace configuration)
    - Token auth parater force the token auth method to GitHub

    ```bash
    flux bootstrap github \
      --owner=<your github username> \
      --repository=flux-demo \
      --branch=demo1 \
      --path=clusters/dev \
      --private=false \
      --personal=true \
      --namespace=flux-ns \
      --token-auth
    ```

    Please copy your access token after this message:

    `Please enter your GitHub personal access token (PAT):`

    Sample command output:

    ```bash
    ► connecting to github.com
    ► cloning branch "demo1" from Git repository "https://github.com/<your username>/flux-demo.git"
    ✔ cloned repository
    ► generating component manifests
    ✔ generated component manifests
    ✔ committed sync manifests to "demo1" ("<your commit hash>")
    ► pushing component manifests to "https://github.com/<your username>/flux-demo.git"
    ✔ installed components
    ✔ reconciled components
    ► determining if source secret "flux-ns/flux-system" exists
    ► generating source secret
    ► applying source secret "flux-ns/flux-system"
    ✔ reconciled source secret
    ► generating sync manifests
    ✔ generated sync manifests
    ✔ committed sync manifests to "demo1" ("<git commit hash>")
    ► pushing sync manifests to "https://github.com/<your username>/flux-demo.git"
    ► applying sync manifests
    ✔ reconciled sync configuration
    ◎ waiting for Kustomization "flux-ns/flux-ns" to be reconciled
    ✔ Kustomization reconciled successfully
    ► confirming components are healthy
    ✔ helm-controller: deployment ready
    ✔ kustomize-controller: deployment ready
    ✔ notification-controller: deployment ready
    ✔ source-controller: deployment ready
    ✔ all components are healthy
    ```
1. We have a base FluxCD installation on Kubernetes.

    You can able to check it with k9s  
    (the k9s documentation are linked above)

    or you can check it manually

    ```bash
    kubens flux-ns
    kubenctl get pods
    ```

## Create our first deployment with FluxCD

We will create files, and those will describe our software resources (like a Helm chart repositories),application Helm charts, application configuration.

### Nginx ingress controller

Nginx controller will be deployed from Helm chart. In first step need to be defined the Helm repository, after we can prepare the configuration for the nginx-controller Helm Chart and last step to define the Helm release.

Nginx ingress controller is an infrastructure related element and it will be serve our application ingresses. That is the reason, why we add it to the infrastructure directory instead of apps/base.
| Function place | Path |
|----------------|------|
| Repository defintion | infrastructure/sources/ |  
| Flux configuration   | cluster/`<env>`/ |
| Configuration | apps/`<env>`/ |
| Helm release configuration | apps/base/`<app name>`/ |
| Infrastructure Helm relases | infrastructure/base/`<app name>`/ |

1. Add Bitnami as Helm repository as source of the Helm charts.

    ```bash
    vi infrastructure/sources/bitnami.yaml
    ```

    Enable file edit with `insert` key or `i` key

    Add the following contect to the file

    ```yaml
    apiVersion: source.toolkit.fluxcd.io/v1beta1
    kind: HelmRepository
    metadata:
      name: bitnami
    spec:
      interval: 30m
      url: https://charts.bitnami.com/bitnami
    ```

    Save file with `:wq`

1. Add Kustomization for sources.

    If you will to add more sources later, just define same way as above and add the file to tle list in kustomization.yaml

    ```bash
    vi infrastructure/sources/kustomization.yaml
    ```

    Enable file edit with `insert` key or `i` key

    Add the following contect to the file

    ```yaml
    apiVersion: kustomize.config.k8s.io/v1beta1
    kind: Kustomization
    namespace: flux-system
    resources:
    - bitnami.yaml
    ```

    Save file with `:wq`

1. Add Kustomization for the `dev` environment.

  If you will to add more sources later, just define same way as above and add the file to tle list in kustomization.yaml

    ```bash
    vi infrastructure/dev/kustomization.yaml
    ```

    Enable file edit with `insert` key or `i` key

    Add the following contect to the file

    ```yaml
    apiVersion: kustomize.config.k8s.io/v1beta1
    kind: Kustomization
    namespace: flux-system
    resources:
    - sources
    ```

    Save file with `:wq`

1. Create `nginx-controller` directory in infrastructure

  ```bash
  mkdir infrastructure/apps/nginx-controller
  ```

1. Create namespace for Nginx ingress controller

    Note: `ns` - Namespace

    ```bash
    vi infrastructure/apps/namespace.yaml
    ```

    Enable file edit with `insert` key or `i` key

    Add the following contect to the file

    ```yaml
    apiVersion: v1
    kind: Namespace
    metadata:
      name: nginx-ns
    ```
    
    Save file with `:wq`
