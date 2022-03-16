# Prepare FluxCD

## Create initial configuration for FluxCD

### Introduction

We will work only with the **`"dev"`** environment. Feel free to practice on the other environments.

Hints for file exiting. It will be used **vi** and after every commands need to be hit the Enter key.

If you prefer different editor feel free to use it.

### Create initial configuration

All of the command need to run in the git repo folder.\
Default: \~/.git/flux-demo

We are creating the Flux deployment for Kubernetes. These steps are presenting how can we build up our test systems. Most of the steps are will be create a Kubernetes objects. If you are beginner in Kubernetes you can follow the "kind:" lines, these are describing the object types and you find a bit more details in Kubernetes guides.&#x20;

1.  Create namespace configuration file

    ```bash
    vi flux-init/namespace.yaml
    ```

    Enable file edit with `insert` key or `i` key

    Add the following content to the file

    ```yaml
    apiVersion: v1
    kind: Namespace
    metadata:
      name: flux-system
    ```

    Save file with `:wq`
2.  Create role configuration

    This role will be guaranteed the access to the Kubernetes objects.

    ```bash
    vi flux-init/role.yaml
    ```

    Enable file edit with `insert` key or `i` key

    Add the following content to the file

    ```yaml
    apiVersion: rbac.authorization.k8s.io/v1
    kind: Role
    metadata:
      name: flux-role
      namespace: flux-system
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
3.  Create role-binding configuration

    This will be assign the role with the service account.

    ```bash
    vi flux-init/role-binding.yaml
    ```

    Enable file edit with `insert` key or `i` key

    Add the following content to the file

    ```yaml
    apiVersion: rbac.authorization.k8s.io/v1
    kind: RoleBinding
    metadata:
      name: flux-sa-rb
      namespace: flux-system
    roleRef:
      apiGroup: rbac.authorization.k8s.io
      kind: Role
      name: flux-role
    subjects:
    - name: flux-sa
      namespace: flux-system
      kind: ServiceAccount
    ```

    Save file with `:wq`
4.  Create cluster role configuration

    This role will describe the right to the cluster.

    ```bash
    vi flux-init/cluster-role.yaml
    ```

    Enable file edit with `insert` key or `i` key

    Add the following content to the file

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
5.  Create cluster role binding configuration

    This will assign the cluster role with the service account.

    ```bash
    vi flux-init/cluster-role-binding.yaml
    ```

    Enable file edit with `insert` key or `i` key

    Add the following content to the file

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
      namespace: flux-system
      kind: ServiceAccount
    ```

    Save file with `:wq`
6.  Create kustomization configuration

    This will call the previous configuration in the defined order and apply it.

    ```bash
    vi flux-init/kustomization.yaml
    ```

    Enable file edit with `insert` key or `i` key

    Add the following content to the file

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
7.  Verify your files are correct and ready to deploy them

    ```bash
    kubectl apply -k flux-init/ --dry-run=client
    ```

    Sample output:

    ```bash
    namespace/flux-system configured (dry run)
    role.rbac.authorization.k8s.io/flux-role configured (dry run)
    clusterrole.rbac.authorization.k8s.io/flux-cr configured (dry run)
    rolebinding.rbac.authorization.k8s.io/flux-sa-rb configured (dry run)
    clusterrolebinding.rbac.authorization.k8s.io/flux-crb configured (dry run)
    ```
8.  Push your code to the GitHub

    ```bash
    git push -u origin demo1
    ```

