# Prepare FluxCD

## Create initial configuration for FluxCD

### Introduction

We will work only with the **`"dev"`** environment. Feel free to practice on the other environments.

If you prefer different editor feel free to use it.

### Create initial configuration

All of the command need to run in the git repo folder.\
Default: \~/.git/flux-demo

We are creating the Flux deployment for Kubernetes. These steps are presenting how can we build up our test systems. Most of the steps are will be create a Kubernetes objects. If you are beginner in Kubernetes you can follow the "kind:" lines, these are describing the object types and you find a bit more details in Kubernetes guides.

1. Create namespace configuration file

    ```bash
    cat << EOF > flux-init/namespace.yaml
    apiVersion: v1
    kind: Namespace
    metadata:
      name: flux-system
    EOF
    ```

2. Create service account

    This role will be guaranteed the access to the Kubernetes objects.

    ```bash
    cat << EOF > flux-init/cluster-role.yaml
    apiVersion: v1
    kind: ServiceAccount
    metadata:
      name: flux-engineering
      namespace: flux-engineering
    EOF
    ```

3. Create cluster role configuration

    This role will be guaranteed the access to the Kubernetes objects.

    ```bash
    cat << EOF > flux-init/cluster-role.yaml
    apiVersion: rbac.authorization.k8s.io/v1
    kind: ClusterRole
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
    EOF
    ```

4. Create cluster role-binding configuration

    This will be assign the role with the service account.

    ```bash
    cat << EOF > flux-init/cluster-role-binding.yaml
    apiVersion: rbac.authorization.k8s.io/v1
    kind: ClusterRoleBinding
    metadata:
      name: flux-sa-rb
      namespace: flux-system
    roleRef:
      apiGroup: rbac.authorization.k8s.io
      kind: ClusterRole
      name: flux-role
    subjects:
    - name: flux-sa
      namespace: flux-system
      kind: ServiceAccount
    EOF
    ```

5. Create kustomization configuration

    This will call the previous configuration in the defined order and apply it.

    ```bash
    cat << EOF > flux-init/kustomization.yaml
    apiVersion: kustomize.config.k8s.io/v1beta1
    kind: Kustomization
    resources:
    - role.yaml
    - role-binding.yaml
    - cluster-role.yaml
    - cluster-role-binding.yaml
    - namespace.yaml
    EOF
    ```

6. Verify your files are correct and ready to deploy them

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

7. Change all stages for git commit

    ```bash
    git add.
    git commit -m "Init FluxCD environment"
    ```

8. Push your code to the GitHub

    ```bash
    git push -u origin demo1
    ```
