# Deploy first app

The good news we are prepared our system and ready to our first application deployment.&#x20;

## Deploy DokuWiki&#x20;

### Description

&#x20;Dokuwiki will be deployed by FluxCD and Nginx ingress controller will be take care of the incoming traffic to Dokuwiki.

Incoming traffic: Client -- http traffic --> Nginx ingress controller -> Dokuwiki service -> Dokuwiki pod

Dokuwiki structure, that will be apply below:

* New namespace: `wiki`
* New clusterrolebinding for the new namespace (FluxCD will get access to the new namespace)
* 1 pod, with one container for dokuwiki, based on the official Bitnami image
* 1 service for the pod
* Added deployment to the Kustomization

Notes:

* New source not need to define, because we will use the existing Bitnami Helm chart repository.
* Ingress will be defined at the Helm release
* Service will be defined at the Helm release

Workdir: apps/base/dokuwiki

### Prepare the code for deployment

1. Create `dokuwiki` directory in apps/base

    ```bash
    mkdir apps/base/dokuwiki
    ```

2. Create namespace for Nginx ingress controller

    ```bash
    vi apps/base/dokuwiki/namespace.yaml
    ```

    Enable file edit with `insert` key or `i` key

    Add the following content to the file

    ```yaml
    apiVersion: v1
    kind: Namespace
    metadata:
      name: wiki
    ```

    Save file with `:wq`
3. Create cluster role binding

    It gives access to Flux to deploy in this namespace.

    ```bash
    vi apps/base/dokuwiki/cluster-role-binding.yaml
    ```

    Enable file edit with `insert` key or `i` key

    Add the following content to the file

    ```yaml
    apiVersion: rbac.authorization.k8s.io/v1
    kind: RoleBinding
    metadata:
      name: flux-dokuwiki-rb
      namespace: wiki
    roleRef:
      apiGroup: rbac.authorization.k8s.io
      kind: ClusterRole
      name: flux-cr
    subjects:
      - kind: ServiceAccount
        name: flux-sa
        namespace: flux-system
      - apiGroup: rbac.authorization.k8s.io
        kind: Group
        name: system:serviceaccounts
    ```

    Save file with `:wq`
4. Create Dokuwiki Helm release

    Helm chart guide for Dokuwiki: [https://github.com/bitnami/charts/tree/master/bitnami/dokuwiki](https://github.com/bitnami/charts/tree/master/bitnami/dokuwiki)

    You can define the values override in the `values` section of release definition.

    It will be configured the Helm to deploy the chart.

    ```bash
    vi apps/base/dokuwiki/release.yaml
    ```

    Enable file edit with `insert` key or `i` key

    Add the following content to the file

    ```yaml
    apiVersion: helm.toolkit.fluxcd.io/v2beta1
    kind: HelmRelease
    metadata:
      name: dokuwiki
    spec:
      releaseName: dokuwiki
      chart:
        spec:
          chart: dokuwiki
          sourceRef:
            kind: HelmRepository
            name: bitnami
            namespace: flux-system
      interval: 1m
      install:
        remediation:
          retries: 3
      values:
        dokuwikiUsername: "admin"
        dokuwikiPassword: "wikiadmin"
        dokuwikiEmail: "user@example.com"
        dokuwikiFullName: "Wiki User"
        dokuwikiWikiName: "My Wiki page deployed by Flux"
        volumePermissions:
          enabled: true
        podSecurityPolicy:
          enabled: false
        metrics:
          enabled: false
        ingress:
          enabled: true
          ingressClassName: "nginx"
          path: /
          hostname: dokuwiki.local
    ```

    Save file with `:wq`
5.  Add Kustomization to prepare the Dokuwiki deployment on Kubernetes.

    ```bash
    vi apps/base/dokuwiki/kustomization.yaml
    ```

    Enable file edit with `insert` key or `i` key

    Add the following content to the file

    ```yaml
    apiVersion: kustomize.config.k8s.io/v1beta1
    kind: Kustomization
    namespace: wiki
    resources:
    - namespace.yaml
    - cluster-role-binding.yaml
    - release.yaml
    ```

    Save file with `:wq`
6.  Define the Dokuwiki deployment to the Kustomization for the `dev` environment.

    If you will to add more sources later, just define same way as above and add the file to tle list in kustomization.yaml

    ```bash
    vi apps/dev/kustomization.yaml
    ```

    Enable file edit with `insert` key or `i` key

    Create file with this content:

    ```yaml
    apiVersion: kustomize.config.k8s.io/v1beta1
    kind: Kustomization
    namespace: wiki
    resources:
    - ../base/dokuwiki/
    ```

    Save file with `:wq`
7.  Define the Dokuwiki deployment for Flux on the `dev` environment.

    The Nginx ingress controller should be deployed before the Dokuwiki, becaus it will take care of the incoming traffic. It can define via `dependsOn` option in `spec` section (see the config below).

    Open file for edit:

    ```bash
    vi clusters/dev/dokuwiki.yaml
    ```

    Enable file edit with `insert` key or `i` key

    Add this content to file:

    ```yaml
    apiVersion: kustomize.toolkit.fluxcd.io/v1beta2
    kind: Kustomization
    metadata:
      name: dokuwiki
      namespace: flux-system
    spec:
      dependsOn:
        - name: infrastructure
      timeout: 1m0s
      interval: 5m0s
      sourceRef:
        kind: GitRepository
        name: flux-system
      path: ./apps/dev
      prune: true
    ```

    Save file with `:wq`

### Deploy the code

In this case just commit all files and push it into the Git repository

```bash
git add .
git commit -m "Added Dokuwiki deployment"
git push
```

Flux will be deploy the Dokuwiki automatically. You have to wait max. 1 minutes for Kustomization, and 5 minutes for the beginning of the Helm chart deployment. In worst case you have a new Dokuwiki deployment soon. You can decrease the reconcilation periods, but can be generate a huge load and pending Helm releases.

### Verify deployment

You have a choice all of the kubernetes command can be apply in K9s as well. Be careful, the K9s not changing context or namespace in your terminal. It is just happen inside the software.

If you have a kubectx and kubens command the next few step will be easier a bit. The original kubectl commands are also added to the documentation.

1. Go to the terminal
2.  Configure the right Kubernetes context

    ```bash
    kubectx minikube
    ```

    or

    ```bash
    kubectl config use-context minikube
    ```
3.  Get all namespaces

    ```bash
    kubectl get ns
    ```

    Sample result: You have to focus to the `wiki` namespace - here are our Dokuwiki resources

    ```bash
    NAME              STATUS   AGE
    default           Active   135m
    flux-system       Active   132m
    kube-node-lease   Active   135m
    kube-public       Active   135m
    kube-system       Active   135m
    nginx             Active   120m
    wiki              Active   100m
    ```
4. Check the ingress definition is there.
   1.  Get the existing ingress in `wiki` namespace

       ```bash
       kubectl get ingress -n wiki
       ```

       Sample output:

       You can configure the domain in values section at the Helm release: apps/base/dokuwiki/release.yaml

       ```bash
       NAME       CLASS   HOSTS            ADDRESS        PORTS   AGE
       dokuwiki   nginx   dokuwiki.local   192.168.1.2   80      41m
       ```
   2.  Add temporary entry to your /etc/hosts file:

       Open file for edit:

       ```bash
       sudo vi /etc/hosts
       ```

       Enable file edit with `insert` key or `i` key

       Add this line to the `hosts` file:\
       Note: IP will be different on your device, so please your machine IP, that are presented in address column by the previous command.

       ```bash
       192.168.1.2 dokuwiki.local
       ```

       Add this content to file:

       ```bash
       127.0.0.1 localhost

       # Dokuwiki domain
       192.168.1.2 dokuwiki.local
       ```

       Save file with `:wq`
   3.  Get external URL with minikube

       ```bash
       minikube service nginx -n nginx --url
       ```

       Sample result:\
       Note: IP will be different on your device, so please your machine IP, that are presented in address column by the previous command.

       ```bash
       http://192.168.1.2:30308   # this is pointing to port 80 in Kubernetes
       http://192.168.1.2:32583   # this is pointing to port 443 in Kubernetes
       ```

       Next step to test the URL-s above with curl

       ```bash
       curl -I http://dokuwiki.local:30308
       curl -I http://dokuwiki.local

       You will be get HTTP response code 200, that means the Dokuwiki is available and ready to use.

       Note: The ports at end of the URL will be changes anytime, if Nginx ingress controller will be redeployed by FluxCD.
       ```
