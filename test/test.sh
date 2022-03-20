#!/bin/bash

# Default settings
GIT_DIR=~/test/git
GIT_URL="https://github.com/kallaics/flux-demo.git"
GIT_BRANCH="test1"
# export GITHUB_TOKEN=

REQUIREMENTS_ERROR=0

# Colors
RED="\e[31m"
GREEN="\e[32m"
NO_COLOR="\e[0m"

function ok_msg() {
  [[ ! -z $1 ]] && msg=$1 || msg=""
  echo -e "${GREEN}OK${NO_COLOR} $msg"
}

function error_msg() {
  [[ ! -z $1 ]] && msg=$1 || msg=""
  echo -e "${RED}ERROR:${NO_COLOR} $msg"
}

echo "Verifying required softwares..."
echo

echo -n "Current path..."
pwd
echo -n "Checking Git..."
GIT_VERSION=$(git --version | awk '{print $3;}')
if [[ $? -eq 0 ]]; then
  ok_msg "($GIT_VERSION)"
else
  error_msg "Git not found or not installed maybe"
  REQUIREMENTS_ERROR=1
fi

echo -n "Checking Docker..."
DOCKER_VERSION=$(docker version | grep -i "^ Version:" | awk '{ print $2;}')
if [[ $? -eq 0 ]]; then
  ok_msg "($DOCKER_VERSION)"
else
  error_msg "Docker not found or not installed maybe"
  REQUIREMENTS_ERROR=1
fi

echo -n "Checking Minikube..."
MINIKUBE_VERSION=$(minikube version | grep -i "version:" | awk '{print $3;}')
if [[ $? -eq 0 ]]; then
  ok_msg "($MINIKUBE_VERSION)"
else
  error_msg "Minikube not found or not installed maybe"
  REQUIREMENTS_ERROR=1
fi

echo -n "Checking kubectx (optional)..."
kubectx --help >/dev/null 2>&1
[[ $? -eq 0 ]] && ok_msg || error_msg "Kubectx not found or not installed maybe"

echo -n "Checking kubens (optional)..."
kubens --help >/dev/null 2>&1
[[ $? -eq 0 ]] && ok_msg || error_msg "Kubens not found/not installed maybe"

echo -n "Checking k9s (optional)..."
K9S_VERSION=$(k9s version | grep -i "version:" | awk '{print $2;}' | sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]//g")
[[ $? -eq 0 ]] && ok_msg "($K9S_VERSION)" || error_msg "K9s not found or not installed maybe"

echo -n "Checking FluxCD..."
FLUXCD_VERSION=$(flux --version | awk '{print $3}')
if [[ $? -eq 0 ]]; then
  ok_msg "($FLUXCD_VERSION)"
else
  error_msg "Flux not found or not installed maybe"
  REQUIREMENTS_ERROR=1
fi

if [[ "${REQUIREMENTS_ERROR}" -eq "1" ]]; then
  error_msg "One or more of mandatory pre-requisites are missing. Exiting..."
  exit 1;
fi


echo
echo -n "Creating test directory..."
mkdir -p $GIT_DIR
if [[ $? -eq 0 ]]; then
  ok_msg "($GIT_DIR)"
else
  error_msg "Cannot create directory $GIT_DIR"
  exit 1
fi

echo
echo "Preparing Minikube"
echo -n "  Creating cluster..."
minikube status >/dev/null
if [ $? -eq 0 ];then
    ok_msg "(Already created)"
else
    minikube start --cpus 2 --memory 4096 >/dev/null 2>&1
    [[ $? -eq 0 ]] && ok_msg "(minikube)" || error_msg "Minikube cluster creation error!"
fi

echo -n "  Enable 'metrics' plugin for Minikube..."
minikube addons enable metrics-server >/dev/null 2>&1
[[ $? -eq 0 ]] && ok_msg "(metrics-server)" || error_msg "Error: Cannot enable 'metrics-server' plugin for Minikube"

echo 
echo "Git repository"
echo -n "  Clone git 'flux-demo' repository..."
pushd $GIT_DIR >/dev/null 2>&1
if [ -d "flux-demo" ]; then
    ok_msg "(Already cloned)"
else
    git clone $GIT_URL >/dev/null 2>&1
    [[ $? -eq 0 ]] && ok_msg "(flux-demo)" || error_msg "Cannot clone $GIT_URL"
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
    ok_msg "(${GIT_BRANCH_STATUS}${GIT_BRANCH})"
else
    error_msg "Cannot create git branch: $GIT_BRANCH"
fi

echo
echo "Flux preparation"
echo -n "  Preparing directories..."
mkdir -p apps/{base,prod,stg,dev} \
         clusters/{prod,stg,dev} \
         infrastructure/{base,prod,stg,dev} \
         flux-init/ \
         >/dev/null 2>&1
if [[ $? -eq 0 ]]; then 
  ok_msg
  echo -n "    Create '.gitkeep' files..."
  find . -type d \( -path "./infrastructure*" -o -path "./apps*" -o -path "./clusters*" \) -exec touch {}/.gitkeep \; >/dev/null 2>&1
  [[ $? -eq 0 ]] && ok_msg || error_msg "Cannot create .gitkeep files"
else
  error_msg "Cannot create directory structure"
fi

echo
echo -n "  Creating config file for 'flux-system' namespace..."
cat << EOF > flux-init/namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: flux-system
EOF
[[ $? -eq 0 ]] && ok_msg || error_msg "Cannot create config file for namespace"

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
[[ $? -eq 0 ]] && ok_msg || error_msg "Cannot create config file for role"


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
[[ $? -eq 0 ]] && ok_msg || error_msg "Cannot create config file for role binding"

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
[[ $? -eq 0 ]] && ok_msg || error_msg "Cannot create config file for cluster role"

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
[[ $? -eq 0 ]] && ok_msg || error_msg "Cannot create config file for cluster role binding"

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
[[ $? -eq 0 ]] && ok_msg || error_msg "Cannot create config file for kustomization"

echo -n "  Dry run result the flux init commands..."
kubectl apply -k flux-init/ --dry-run=client >/dev/null 2>&1
K_STATUS=$?
[[ $? -eq 0 ]] && ok_msg || error_msg "kubectl command dry run was failed"

echo -n "  Push changes to the git..."
if [[ "${K_STATUS}" -eq "0" ]];then
    git add . >/dev/null 2>&1
    git commit -m "Init structure for Flux" >/dev/null 2>&1
    git push -u origin $GIT_BRANCH >/dev/null 2>&1 
    [[ $? -eq 0 ]] && ok_msg "($GIT_BRANCH)" || error_msg "Cannot push your changes to git"
fi

echo
echo "FluxCD Bootstrapping"
echo -n "  Initialize FluxCD environment..."
kubectl get namespace flux-system >/dev/null 2>&1
if [[ $? -eq 0 ]]; then
    kubectl apply -k flux-init/ >/dev/null 2>&1
    [[ $? -eq 0 ]] && ok_msg "(Already exist, refreshed)" || error_msg "Cannot run kubectl command"
else
    kubectl create -k flux-init/ >/dev/null 2>&1
    [[ $? -eq 0 ]] && ok_msg || error_msg "Cannot run 'kubectl' command"
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
  --read-write-key=true \
  >/dev/null 2>&1
[[ $? -eq 0 ]] && ok_msg || error_msg "Cannot run 'flux bootstrap' command"

echo
echo "Deploy NGINX ingress controller"
echo -n "  Creating source file directory..."
mkdir -p infrastructure/base/sources
if [[ $? -eq 0 ]]; then
  ok_msg
else
  error_msg "Cannot create source directory 'infrastructure/base/sources'"
  exit 1
fi

echo -n "  Creating config file for Helm repository of Bitnami..."
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
[[ $? -eq 0 ]] && ok_msg || error_msg "Cannot create config file for Bitnami source"

echo -n "  Creating config file kustomization..."
cat << EOF > infrastructure/base/sources/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: flux-system
resources:
  - bitnami.yaml
EOF
[[ $? -eq 0 ]] && ok_msg || error_msg "Cannot create config file for source kustomization"


echo -n "  Creating config file infrastructure kustomization..."
cat << EOF > infrastructure/dev/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
- ../base/sources/
EOF
[[ $? -eq 0 ]] && ok_msg || error_msg "Cannot create config file for infrastructure kustomization"

echo -n "  Creating config file for infrastructure..."
cat << EOF > clusters/dev/infrastructure.yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1beta2
kind: Kustomization
metadata:
  name: infrastructure
  namespace: flux-system
spec:
  timeout: 1m0s
  interval: 5m0s
  sourceRef:
    kind: GitRepository
    name: flux-system
  path: ./infrastructure/dev
  prune: true
EOF
[[ $? -eq 0 ]] && ok_msg || error_msg "Cannot create config file for infrastructure"

echo -n "  Creating directory for NGINX controller..."
mkdir -p infrastructure/base/nginx-controller
if [[ $? -eq 0 ]]; then
  ok_msg
else
  error_msg "Cannot create source directory 'infrastructure/base/nginx-controller'"
  exit 1
fi

echo -n "  Creating config file for 'namespace'..."
cat << EOF > infrastructure/base/nginx-controller/namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: nginx
EOF
[[ $? -eq 0 ]] && ok_msg || error_msg "Cannot create config file for namespace"

echo -n "  Creating config file 'cluster role binding'..."
cat << EOF > infrastructure/base/nginx-controller/cluster-role-binding.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: flux-nginx-rb
  namespace: nginx
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
EOF
[[ $? -eq 0 ]] && ok_msg || error_msg "Cannot create config file for 'cluster role binding'"

echo -n "  Creating config file for 'Helm release'..."
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
  interval: 0h5m0s
  install:
    remediation:
      retries: 3
  values:
    nameOverride: "nginx"
    fullnameOverride: "nginx"
    podSecurityPolicy:
      enabled: false
EOF
[[ $? -eq 0 ]] && ok_msg || error_msg "Cannot create config file for 'Helm release'"

echo -n "  Creating config file 'kustomization'..."
cat << EOF > infrastructure/base/nginx-controller/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: nginx
resources:
- namespace.yaml
- cluster-role-binding.yaml
- release.yaml
EOF
[[ $? -eq 0 ]] && ok_msg || error_msg "Cannot create config file for 'kustomization'"

echo -n "  Add configuration to file 'kustomization'..."
echo "- ../base/nginx-controller/" > infrastructure/dev/kustomization.yaml
[[ $? -eq 0 ]] && ok_msg || error_msg "Cannot add configuration for file 'kustomization'"

echo "  Pushing files to git"
echo -n "    Adding files to Git commit..."
git pull >/dev/null 2>&1
git add . >/dev/null 2>&1
[[ $? -eq 0 ]] && ok_msg || error_msg "Cannot add files to Git commit"

echo -n "    Creating Git commit..."
git commit -m "Added Nginx ingress controller" >/dev/null 2>&1
[[ $? -eq 0 ]] && ok_msg || error_msg "Cannot commit to Git"

echo -n "    Pushing commit to Git..."
git push >/dev/null 2>&1
[[ $? -eq 0 ]] && ok_msg || error_msg "Cannot push to Git"

echo -n "  Get response from Nginx ingress controller (wait max. 30s)..."
for t in $(seq 1 30)
do
NGINX_SVC_URL=$(minikube service nginx -n nginx --url | head -n 1 >/dev/null)
[[ $? -eq 0 ]] && break
sleep 1;
done
for t in $(seq 1 30)
do
RESP=`curl -s -o /dev/null -I -w "%{http_code}" $NGINX_SVC_URL/healthz 2>/dev/null`
echo $RESP
[[ "${RESP}" -eq "404" ]] && break
sleep 1;
done
[[ "${RESP}" -eq "404" ]] && ok_msg || error_msg "Cannot create config file for source kustomization"

popd >/dev/null 2>&1
popd >/dev/null 2>&1
echo -n "Current path..."
pwd

echo
echo "Done"
