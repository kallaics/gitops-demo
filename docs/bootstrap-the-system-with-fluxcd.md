# Bootstrap the system with FluxCD

After we created the necessary objects for FluxCD, than here is the time to initialize it.

## Deploy FluxCD

1. Deploy the FluxCD requirements on Kubernetes

    ```bash
    kubectl create -k flux-init/
    ```

2. If you have multiple Kubernetes context please choose the minikube system.

    ```bash
    kubectx minikube
    kubens default
    ```

3. Bootstrap the FluxCD

    Create a connection between the FluxCD and the Git repository via SSH. If you are using GitHub, Gitlab or Bitbucket please see the [FluxCD documentation bootstrap section](https://fluxcd.io/docs/cmd/flux\_bootstrap/) about the possibilities.

    Some words about the parameters:

    * HTTPS will be used for the communication
    * Owner is your username every time
    * Repository cover your repository name (`"flux-demo"`)
    * Branch is your branch that you are already created above (`"demo1"`)
    * PATH will be define which environment is deployed here (`"clusters/dev"`)
    * Private means your repository will configured as public (and not private)
    * Personal define the owner is a user and not an organization
    * Namespace parameter is telling which namespace are prepared to flux (basically it is optional in this case, because all of the config file contains the namespace configuration)
    * Token auth parameter force the token based authentication method to GitHub

    ```bash
    flux bootstrap github \
      --owner=<your github username> \
      --repository=flux-demo \
      --branch=demo1 \
      --path=clusters/dev \
      --private=false \
      --personal=true \
      --namespace=flux-system \
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
    ► determining if source secret "flux-system/flux-system" exists
    ► generating source secret
    ► applying source secret "flux-system/flux-system"
    ✔ reconciled source secret
    ► generating sync manifests
    ✔ generated sync manifests
    ✔ committed sync manifests to "demo1" ("<git commit hash>")
    ► pushing sync manifests to "https://github.com/<your username>/flux-demo.git"
    ► applying sync manifests
    ✔ reconciled sync configuration
    ◎ waiting for Kustomization "flux-system/flux-system" to be reconciled
    ✔ Kustomization reconciled successfully
    ► confirming components are healthy
    ✔ helm-controller: deployment ready
    ✔ kustomize-controller: deployment ready
    ✔ notification-controller: deployment ready
    ✔ source-controller: deployment ready
    ✔ all components are healthy
    ```

4. We have a base FluxCD installation on Kubernetes.

    You can able to check it with k9s (the k9s documentation are linked above) or you can check it manually

    ```bash
    kubens flux-system
    kubectl get pods
    ```

    Sample results for the pods. When all the status is running looks fine this step.

    ```bash
    NAME                                      READY   STATUS    RESTARTS   AGE
    helm-controller-dfb4b5478-82qd2           1/1     Running   0          2m24s
    kustomize-controller-cd544c8f8-6q2z6      1/1     Running   0          2m24s
    notification-controller-d9cc9bf46-hrpbv   1/1     Running   0          2m24s
    source-controller-84bfd77bf8-qt4s6        1/1     Running   0          2m24s
    ```
