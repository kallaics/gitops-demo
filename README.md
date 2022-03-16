# Introduction

It prepare for educational purpose about the GitOps methodology in the practice.

A little game to present a the GitOps. This not for production use, this is only learning purpose and to arouse the interest regarding to GitOps.

The plan to easy to understand and lean more about the GitOps.\
This will show, how can anybody create a simple flow with a simple app. The goal is to create a simple Dokuwiki with automated deployment.

GitOps are not equal with these softwares only. You can use your favorite solutions for git GitHub, Gitlab, BitBucket etc. You can use ArgoCD or Rancher instead of FluxCD. So lot of different solutions are on the internet to apply GitOps methodology on your system. In this current case we will use the `GitHub+FluxCD+Kubernetes+Helm` combination to present the GitOps.

If you have not GitHub account please create an account for yourself free on [GitHub signup page](https://github.com/join). If you prefer to use a different Git based code store, then some steps will be different later (for example: FluxCD bootstrap command).

Environment:

* GitHub (code store)
* Kubernetes with Kustomization (Minikube on local machine)

Used softwares to reach the goal:

* FluxCD
* Helm
* Kubernetes (Minikube)
* Kustomize
* kubectx + kubens
* k9s

The solution will work on this way.

User push the changes to the GitHub. FluxCD will be check it via the source controller\` FluxCD component. If it has a new commit try to apply it on the system. The Kustomization supported by Kubernetes default. The Kustomize controller will update the configuration on Kubernetes elements (Configmaps, Secrets, Deployments, Pods, Services etc.). The deployment with the new config will be done by Helm controller.

##
