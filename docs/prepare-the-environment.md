# Prepare the environment

As a next step we need to prepare our machine to able to ready for FluxCD. We will apply these  steps:

* GitHub: Create repository and personal access token\
  (it will be necessary for Flux to communicate with the git repository)
* create our Kubernetes cluster over Docker

## GitHub

### Create your repository on GitHub

1. Click on top right on **`"+"`** icon and choose the new repository
2. Fill the repository name: `flux-demo`
3. Check the checkbox before the text: `Add a README file`
4. Click on `Create repository` button (bottom of the page)

### Create a personal access token

You need to create a personal access token on GitHub, because your password cannot be used with FluxCD later (and it will be not so safe)

Official guide to access token creation: [https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token)

Feel free to define the token name. (like `fluxdemo`)\
The repository and the user only enough for this token.

## Local machine

### Create a kubernetes cluster

1. Run `minikube` command

    ```bash
    minikube start -cpus 2 --memory 4096
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

2. Enable metrics for CPU and memory usage (optional)

    ```bash
    minikube addons enable metrics-server
    ```

    Sample output:

    ```bash
       ▪ Using image k8s.gcr.io/metrics-server/metrics-server:v0.4.2
    🌟  The 'metrics-server' addon is enabled
    ```

### Clone your repository to your device

1. Open a terminal (command line)
2. Enter the `git` directory (if you are not there already)

    ```bash
    cd ~/git
    ```

3. Clone the repository to your folder

    Replace `"<your username>"` with your username

    ```bash
    git clone https://github.com/<your username>/flux-demo.git
    ```

4. Enter the directory

    ```bash
    cd flux-demo
    ```

5. Create a new branch for test

    ```bash
    git checkout -b demo1
    ```

### Prepare directory structure

All of the command need to run in the git repo folder.\
Default: \~/.git/flux-demo

1. Create directory structure:

Use this command to create the directory structure: Note: It will not work maybe on Windows.

```bash
mkdir -p apps/{base,prod,stg,dev} \
         clusters/{prod,stg,dev} \
         infrastructure/{base,prod,stg,dev} \
         flux-init/
```

More information about the structure: [https://fluxcd.io/docs/guides/repository-structure/](https://fluxcd.io/docs/guides/repository-structure/)

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
│   └── dev
├── flux-init
└── infrastructure
    ├── base
    ├── prod
    ├── stg
    └── dev
```

### Create .gitkeep files

We are creating .gitkeep files, for all of the empty directory, because it will appear in git as well.

```bash
find . -type d \( -path "./infrastructure*" -o -path "./apps*" -o -path "./clusters*" \) -exec touch {}/.gitkeep \;
```
