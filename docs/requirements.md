# Requirements

## About a test environment

I used my home laptop with Linux to create this test. My recommended configuration for the learning.

### HW requirements

* OS: Linux (or Mac or Windows with WSL)
* Device: Laptop
* CPU: Intel i5-5500M
* Memory: 16 GB (4GB will need for Kubernetes environment and the demo)
* HDD:&#x20;
  * 2 GB free space (for the requirements)
  * and few MB for the code

Any other requirement does not matter from the deployment perspective.

### Software prerequisites

Please install the following components as pre-requisites

Optional: If you like the easiest way, just install Homebrew and install every requirements with it on Linux.\
Homebrew install guide: [https://docs.brew.sh/Homebrew-on-Linux](https://docs.brew.sh/Homebrew-on-Linux)

Mandatory components:

* Git client\
  Official install guide: [https://git-scm.com/book/en/v2/Getting-Started-Installing-Git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)
* Docker\
  Official install guide: [https://docs.docker.com/get-docker/](https://docs.docker.com/get-docker/)
* docker-compose\
  Official install guide [https://docs.docker.com/compose/install/](https://docs.docker.com/compose/install/)
* Minikube (Kubernetes in Docker)\
  Official install guide: [https://minikube.sigs.k8s.io/docs/start/](https://minikube.sigs.k8s.io/docs/start/)
* FluxCD CLI tool\
  Official install guide: [https://fluxcd.io/docs/installation/](https://fluxcd.io/docs/installation/)
* Helm CLI tool\
  Official install guide: [https://helm.sh/docs/intro/install/#through-package-managers](https://helm.sh/docs/intro/install/#through-package-managers)
* Kubectx and kubens\
  Official install guide: [https://github.com/ahmetb/kubectx](https://github.com/ahmetb/kubectx)
* K9s (terminal GUI tool for Kubernetes)\
  Official install guide: [https://k9scli.io/topics/install/](https://k9scli.io/topics/install/)

### Verification

Please check all of the command is available after the installation. If the version numbers are different (newer, than the examples, it is okay.)

1.  Git client

    ```bash
    git --version
    ```

    Sample command output:

    ```bash
    git version 2.17.1
    ```
2.  Docker

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
3.  Docker compose

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
4.  Minikube (Kubernetes in Docker)

    ```bash
     minikube version
    ```

    Sample command output:

    ```bash
    minikube version: v1.24.0
    commit: 76b94fb3c4e8ac5062daf70d60cf03ddcc0a741b
    ```
5.  FluxCD CLI tool

    ```bash
    flux --version
    ```

    Sample command output:

    ```bash
    flux version 0.24.1
    ```

##
