# Deploy required infrastructure elements

We will create files, and those will describe our software resources (like a Helm chart repositories),application Helm charts, application configuration.

## Nginx ingress controller

Nginx controller will be deployed from Helm chart. In first step need to be defined the Helm repository, after we can prepare the configuration for the nginx-controller Helm Chart and last step to define the Helm release.

Nginx ingress controller is an infrastructure related element and it will be serve our application ingresses. That is the reason, why we add it to the infrastructure directory instead of apps/base.

| Function place               | Path                              |
| ---------------------------- | --------------------------------- |
| Repository definition        | infrastructure/base/sources/      |
| Flux configuration           | cluster/`<env>`/                  |
| Configuration                | apps/`<env>`/                     |
| Helm release configuration   | apps/base/`<app name>`/           |
| Infrastructure Helm releases | infrastructure/base/`<app name>`/ |

### Prepare Helm repository configuration

1. Create directory for Helm chart `sources`:

    Note: The `"sources"` directory will contains the Helm chart repository definitions. I assume we will use all of the sources in all environment. If you would like to separate it, maybe possible to create a `"sources"` directory inside of each environment specific directory.

    ```bash
    mkdir infrastructure/base/sources
    ```

2. Add Bitnami as Helm repository as source of the Helm charts.

    ```bash
    cat << EOF > infrastructure/base/sources/bitnami.yaml
    apiVersion: source.toolkit.fluxcd.io/v1beta1
    kind: HelmRepository
    metadata:
      name: bitnami
      namespace: flux-system
    spec:
      interval: 30m
      url: https://charts.bitnami.com/bitnami
    EOF
    ```

3. Add Kustomization for sources.

    If you will to add more sources later, just define same way as above and add the file to tle list in kustomization.yaml

    ```bash
    cat << EOF > infrastructure/base/sources/kustomization.yaml
    apiVersion: kustomize.config.k8s.io/v1beta1
    kind: Kustomization
    namespace: flux-system
    resources:
      - bitnami.yaml
    EOF
    ```

4. Add Kustomization for the `dev` environment.

    If you will to add more sources later, just define same way as above and add the file to tle list in kustomization.yaml

    ```bash
    cat << EOF > infrastructure/dev/kustomization.yaml
    apiVersion: kustomize.config.k8s.io/v1beta1
    kind: Kustomization
    resources:
      - ../base/sources/
    EOF
    ```

5. Add Infrastructure definition for the FluxCD `dev` environment.

    ```bash
    cat << EOF > clusters/dev/infrastructure.yaml
    apiVersion: kustomize.toolkit.fluxcd.io/v1beta2
    kind: Kustomization
    metadata:
      name: infrastructure
      namespace: flux-system
    spec:
      timeout: 1m
      interval: 2m
      sourceRef:
        kind: GitRepository
        name: flux-system
      path: ./infrastructure/dev
      prune: true
    EOF
    ```

### Prepare configuration for deployment

1. Create `nginx-controller` directory in infrastructure

    ```bash
    mkdir infrastructure/base/nginx-controller
    ```

2. Create namespace for Nginx ingress controller

    ```bash
    cat << EOF > infrastructure/base/nginx-controller/namespace.yaml
    apiVersion: v1
    kind: Namespace
    metadata:
      name: nginx
    EOF
    ```

3. Create Nginx Helm release

    Helm chart values reference: [https://github.com/bitnami/charts/blob/master/bitnami/nginx-ingress-controller/values.yaml](https://github.com/bitnami/charts/blob/master/bitnami/nginx-ingress-controller/values.yaml)

    It will be configured the Helm to deploy the chart.

    ```bash
    cat << EOF > infrastructure/base/nginx-controller/release.yaml
    apiVersion: helm.toolkit.fluxcd.io/v2beta1
    kind: HelmRelease
    metadata:
      name: nginx
    spec:
      releaseName: nginx-ingress-controller
      chart:
        spec:
          chart: nginx-ingress-controller
          sourceRef:
            kind: HelmRepository
            name: bitnami
            namespace: flux-system
      interval: 5m
      install:
        remediation:
          retries: 3
      values:
        nameOverride: "nginx"
        fullnameOverride: "nginx"
        podSecurityPolicy:
          enabled: false
    EOF
    ```

4. Add Kustomization to prepare the Nginx controller deployment on Kubernetes.

    ```bash
    cat << EOF > infrastructure/base/nginx-controller/kustomization.yaml
    apiVersion: kustomize.config.k8s.io/v1beta1
    kind: Kustomization
    namespace: nginx
    resources:
      - namespace.yaml
      - release.yaml
    EOF
    ```

5. Add the nginx deployment to the existing Kustomization for the `dev` environment.

    If you will to add more sources later, just define same way as above and add the file to tle list in kustomization.yaml

    ```bash
    echo "  - ../base/nginx-controller/" >> infrastructure/dev/kustomization.yaml
    ```

    The result looks this:

    ```yaml
    apiVersion: kustomize.config.k8s.io/v1beta1
    kind: Kustomization
    resources:
      - ../base/sources/
      - ../base/nginx-controller/
    ```

### Deploy the configuration

In this case just commit all files and push it into the Git repository

```bash
git pull
git add .
git commit -m "Added Nginx ingress controller"
git push
```

### Verify the deployment

You have a choice all of the kubernetes command can be apply in K9s as well. Be careful, the K9s not changing context or namespace in your terminal. It is just happen inside the software.

If you have a kubectx and kubens command the next few step will be easier a bit. The original kubectl commands are also added to the documentation.

1. Go to the terminal

2. Configure the right Kubernetes context

    ```bash
    kubectx minikube
    ```

    or

    ```bash
    kubectl config use-context minikube
    ```

3. Get all namespaces

    ```bash
    kubectl get ns
    ```

    Sample result: You have to focus to the

    * `flux-system` - here hiding the FluxCD, it was created with the bootstrap command earlier
    * `nginx` - here is our nginx ingress controller resources

    ```bash
    NAME              STATUS   AGE
    default           Active   135m
    flux-system       Active   132m
    kube-node-lease   Active   135m
    kube-public       Active   135m
    kube-system       Active   135m
    nginx             Active   120m
    ```

4. Check the ingress controller is working well

   1. Expose the LoadBalancer IP (minikube works different then the normal Kubernetes)

       Get the existing services in `nginx` namespace

       ```bash
       kubectl get svc -n nginx
       ```

       Sample output:

       You will be see the `External-IP` is on `pending` state. If you are using minikube, it is normal. You can get the right external access with `minikube` command. The port mappings ae in this list that will be shown at minikube command output.

       ```bash
       NAME                    TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)                      AGE
       nginx                   LoadBalancer   10.100.54.208   <pending>     80:30308/TCP,443:32583/TCP   99m
       nginx-default-backend   ClusterIP      10.100.217.54   <none>        80/TCP                       99m
       ```

       Get external IP with minikube

       ```bash
       minikube service nginx -n nginx --url
       ```

       Sample result:

       ```bash
       http://192.168.1.2:30308   # this is pointing to port 80 in Kubernetes
       http://192.168.1.2:32583   # this is pointing to port 443 in Kubernetes
       ```

       Next step to test the URL-s above with curl. The command will get back just the HTTP response number like "200" or "404".

       ```bash
       curl -s -o /dev/null -I -w "%{http_code}" http://192.168.1.2:30308/healthz
       curl -s -o /dev/null -I -w "%{http_code}"http://192.168.1.2:30583/healthz
       ```

       First request will give HTTP 200 and the second will return HTTP error 400, that means our nginx ingress controller is working well, but no ingresses configured yet.

       Note: The ports at end of the URL will be changes anytime, if Nginx ingress controller will be redeployed by FluxCD .
