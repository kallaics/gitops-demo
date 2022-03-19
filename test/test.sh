#!/bin/bash

export GITHUB_TOKEN=
GIT_DIR=~/test/git
GIT_URL="https://github.com/kallaics/flux-demo.git"
GIT_BRANCH="test1"

echo "Verifying required softwares..."
echo

echo -n "Current path..."
pwd
echo -n "Checking Git..."
GIT_VERSION=$(git --version | awk '{print $3;}')
[[ $? -eq 0 ]] && echo "OK ($GIT_VERSION)" || echo "Git not found/not installed maybe"

echo -n "Checking Docker..."
DOCKER_VERSION=$(docker version | grep -i "^ Version:" | awk '{ print $2;}')
[[ $? -eq 0 ]] && echo "OK ($DOCKER_VERSION)" || echo "Docker not found/not installed maybe"

echo -n "Checking Minikube..."
MINIKUBE_VERSION=$(minikube version | grep -i "version:" | awk '{print $3;}')
[[ $? -eq 0 ]] && echo "OK ($MINIKUBE_VERSION)" || echo "Minikube not found/not installed maybe"

echo -n "Checking FluxCD..."
FLUXCD_VERSION=$(flux --version | awk '{print $3}')
[[ $? -eq 0 ]] && echo "OK ($FLUXCD_VERSION)" || echo "Error: Flux not found/not installed maybe"


echo
echo -n "Creating test directory..."
mkdir -p $GIT_DIR
[[ $? -eq 0 ]] && echo "OK ($GIT_DIR)" || exit 1

echo
echo "Preparing Minikube"
echo -n "  Creating cluster..."
minikube status >/dev/null
if [ $? -eq 0 ];then
    echo "OK (Already created)"
else
    minikube start --cpus 2 --memory 4096 >/dev/null 2>&1
    [[ $? -eq 0 ]] && echo "OK (minikube)" || echo "Error: Minikube cluster creation error!\nRun `minikube start --cpus 2 --memory 4096` command to check the error message "
fi

echo -n "  Enable 'metrics' plugin for Minikube..."
minikube addons enable metrics-server >/dev/null 2>&1
[[ $? -eq 0 ]] && echo "OK (metrics-server)" || echo "Error: Cannot enable `metrics-server` plugin for Minikube"

echo 
echo "Git repository"
echo -n "  Clone git 'flux-demo' repository..."
pushd $GIT_DIR >/dev/null 2>&1
if [ -d "flux-demo" ]; then
    echo "OK (Already cloned)"
else
    git clone $GIT_URL >/dev/null 2>&1
    [[ $? -eq 0 ]] && echo "OK (flux-demo)" || echo "Error: Cannot clone $GIT_URL"
fi

echo -n "  Switch test branch..."
GIT_BRANCH_STATUS=""
pushd flux-demo >/dev/null 2>&1
git branch | grep $GIT_BRANCH >/dev/null 2>&1
if [[ $? -eq 0 ]]; then
    git checkout master >/dev/null 2>&1
    git branch -D $GIT_BRANCH  >/dev/null 2>&1
    git push origin --delete $GIT_BRANCH  >/dev/null 2>&1
    git pull >/dev/null 2>&1
    GIT_BRANCH_STATUS="Recreated: "
fi
git checkout -b $GIT_BRANCH >/dev/null 2>&1
GIT_ERR=$?
git push >/dev/null 2>&1
if [[ $? -eq 0 ]];then 
    echo "OK (${GIT_BRANCH_STATUS}${GIT_BRANCH})"
else
    echo "Error: Cannot create git branch: $GIT_BRANCH"
fi

echo
echo "Flux preparation"
echo -n "  Preparing directories..."
mkdir -p apps/{base,prod,stg,dev} \
         clusters/{prod,stg,dev} \
         infrastructure/{base,prod,stg,dev} \
         flux-init/
[[ $? -eq 0 ]] && echo "OK" || echo "Error: Cannot create directory structure"

echo
echo -n "  Creating config file for 'flux-system' namespace..."
cat << EOF > flux-init/namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: flux-system
EOF
[[ $? -eq 0 ]] && echo "OK" || echo "Error: Cannot create config file for namespace"

echo -n "  Creating config file for 'flux-role' role..."
cat << EOF > flux-init/role.yaml
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
EOF
[[ $? -eq 0 ]] && echo "OK" || echo "Error: Cannot create config file for role"


echo -n "  Creating config file for role binding..."
cat << EOF > flux-init/role-binding.yaml
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
EOF
[[ $? -eq 0 ]] && echo "OK" || echo "Error: Cannot create config file for role binding"

echo -n "  Creating config file for cluster role..."
cat << EOF > flux-init/cluster-role.yaml
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
EOF
[[ $? -eq 0 ]] && echo "OK" || echo "Error: Cannot create config file for cluster role"

echo -n "  Creating config file for cluster role binding..."
cat << EOF > flux-init/cluster-role-binding.yaml
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
EOF
[[ $? -eq 0 ]] && echo "OK" || echo "Error: Cannot create config file for cluster role binding"

echo -n "  Creating config file for kustomization..."
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
[[ $? -eq 0 ]] && echo "OK" || echo "Error: Cannot create config file for kustomization"

echo -n "  Dry run result the flux init commands..."
kubectl apply -k flux-init/ --dry-run=client >/dev/null 2>&1
K_STATUS=$?
[[ $? -eq 0 ]] && echo "OK" || echo "Error: kubectl command dry run was failed"

echo -n "  Push changes to the git..."
if [[ "${K_STATUS}" -eq "0" ]];then 
    git push -u origin $GIT_BRANCH  >/dev/null 2>&1
    [[ $? -eq 0 ]] && echo "OK ($GIT_BRANCH)" || echo "Error: Cannot push your changes to git"
fi

echo
echo "FluxCD Bootstrapping"
echo -n "  Initialize FluxCD environment..."
kubectl get namespace flux-system >/dev/null 2>&1
if [[ $? -eq 0 ]]; then
    kubectl apply -k flux-init/ >/dev/null 2>&1
    [[ $? -eq 0 ]] && echo "OK (Already exist, refreshed)" || echo "Error: Cannot run kubectl command"
else
    kubectl create -k flux-init/ >/dev/null 2>&1
    [[ $? -eq 0 ]] && echo "OK" || echo "Error: Cannot run 'kubectl' command"
fi

echo -n "  Bootstrapping FluxCD..."
flux bootstrap github \
  --owner=kallaics \
  --repository=flux-demo \
  --branch=$GIT_BRANCH \
  --path=clusters/dev \
  --private=false \
  --personal=true \
  --namespace=flux-system \
  --token-auth \
  >/dev/null 2>&1
[[ $? -eq 0 ]] && echo "OK" || echo "Error: Cannot run 'flux bootstrap' command"

popd >/dev/null 2>&1
popd >/dev/null 2>&1
echo -n "Current path..."
pwd

echo
echo "Done"
