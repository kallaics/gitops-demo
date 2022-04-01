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

declare -ar functions=( verify_requirements prepare_environment flux_prepare flux_bootstrap deploy_ingress_controller deploy_wiki )
declare -a active_functions
declare -a removed_functions

function usage() {
  SCRIPT_NAME=$(basename $0)
  echo "--------------------------------------------------------------------------------------------------------------------"
  echo "$SCRIPT_NAME [options]"
  echo
  echo "Options:"
  echo "'true' will run the step, false will be skip the step. Only just one way can be forced. 'true' values are stronger"
  echo
  echo "  Option                          Values         Description"
  echo "  -v|--verify-requirements        true|false   - verification step configuration"
  echo "  -e|--prepare-environment        true|false   - environment preparation step configuration"
  echo "  -f|--prepare-flux               true|false   - FluxCD preparation steps configuration"
  echo "  -b|--flux-bootstrap             true|false   - FluxCD bootstrap step configuration"
  echo "  -i|--deploy-ingress-controller  true|false   - Nginx ingress controller configuration"
  echo "  -w|--deploy-wiki                true|false   - Wiki deployment configuration"
  echo "  -h|--help                            -       - Get usage"
  echo
  echo "Examples:"
  echo "Run only verification step:   $SCRIPT_NAME -v true"
  echo "Skip verification step:       $SCRIPT_NAME -v false"
  echo "Get help:                     $SCRIPT_NAME -h"
  echo "--------------------------------------------------------------------------------------------------------------------"
  exit 0;
}

function ok_msg() {
  [[ ! -z $1 ]] && msg=$1 || msg=""
  echo -e "${GREEN}OK${NO_COLOR} $msg"
}

function error_msg() {
  [[ ! -z $1 ]] && msg=$1 || msg=""
  echo -e "${RED}ERROR:${NO_COLOR} $msg"
}

function org_functions() {
[[ "$1" != "true" ]] && removed_functions+=( $2 ) || active_functions+=( $2 )
}

function main() {
declare -a out
if [[ ${active_functions[@]} ]]; then
  out=${active_functions[@]}
fi
if [[ ${removed_functions[@]} ]]; then
  for i in ${functions[@]}; do
      skip="false"
      for j in ${removed_functions[@]}; do
          [[ $i == $j ]] && { skip="true"; break; }  
      done
      [[ "$skip" == "false" ]] && out+=( "$i" )
  done
fi
if [[ ! ${out[@]} ]];then
  out=${functions[@]}
fi
# echo
# echo "Functions: ${out[@]}"
# echo

for func in ${out[@]}
do  
  eval ${func}
done
}

function verify_requirements() {
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
}

function prepare_environment() {
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
    minikube start --cpus 2 --memory 4096 --nodes 2 >/dev/null 2>&1
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
popd >/dev/null 2>&1
popd >/dev/null 2>&1
}

function flux_prepare() {
pushd $GIT_DIR/flux-demo >/dev/null 2>&1
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

echo -n "  Creating config file for 'flux-sa' service user..."
cat << EOF > flux-init/service-account.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: flux-sa
  namespace: flux-system
EOF
[[ $? -eq 0 ]] && ok_msg || error_msg "Cannot create service account for Flux"

echo -n "  Creating config file for cluster role 'flux-role'..."
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
[[ $? -eq 0 ]] && ok_msg || error_msg "Cannot create config cluster role"


echo -n "  Creating config file for role binding..."
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
[[ $? -eq 0 ]] && ok_msg || error_msg "Cannot create config file for role binding"

echo -n "  Creating config file for kustomization..."
cat << EOF > flux-init/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
- namespace.yaml
- service-account.yaml
- cluster-role.yaml
- cluster-role-binding.yaml
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
popd >/dev/null 2>&1
}

function flux_bootstrap() {
pushd $GIT_DIR/flux-demo >/dev/null 2>&1
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
popd >/dev/null 2>&1
}

function deploy_ingress_controller() {
pushd $GIT_DIR/flux-demo >/dev/null 2>&1
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
  - release.yaml
EOF
[[ $? -eq 0 ]] && ok_msg || error_msg "Cannot create config file for 'kustomization'"

echo -n "  Add configuration to file 'kustomization'..."
echo "- ../base/nginx-controller/" >> infrastructure/dev/kustomization.yaml
[[ $? -eq 0 ]] && ok_msg || error_msg "Cannot add configuration for file 'kustomization'"

echo "  Pushing files to git"
echo -n "    Adding files to Git commit..."
git pull >/dev/null 2>&1
git add . >/dev/null 2>&1
[[ $? -eq 0 ]] && ok_msg || error_msg "Cannot add files to Git commit"

echo -n "    Creating Git commit..."
GIT_DIFF=$(git diff --cached | wc -c)
if [[ $GIT_DIFF -eq 0 ]]; then
  ok_msg "(No changes, skipped)"
else
  git commit -m "Added Nginx ingress controller" >/dev/null 2>&1
  [[ $? -eq 0 ]] && ok_msg || error_msg "Cannot commit to Git"
fi

echo -n "    Pushing commit to Git..."
git push >/dev/null 2>&1
[[ $? -eq 0 ]] && ok_msg || error_msg "Cannot push to Git"

echo -n "  Get response from Nginx ingress controller (wait max. 120s)..."
for t in {1..120}
do
  RET_VAL=$(minikube service nginx -n nginx --url)
  if [[ ! -z "${RET_VAL}" ]]; then
    NGINX_SVC_URL=$(minikube service nginx -n nginx --url | head -n 1)
    break
  fi
  if [[ $t -eq 120 ]]; then 
    error_msg "NGINX service not in up state under 120s. Exiting..."
    exit 1
  fi
  sleep 1s
done

if [[ ! -z "${NGINX_SVC_URL}" ]]; then
  RESP=0
  for t in {1..60}
  do
  RESP=$(curl -s -o /dev/null -I -w "%{http_code}" $NGINX_SVC_URL/healthz)
  [[ "${RESP}" -eq "200" ]] && break
  sleep 1;
  done
  [[ "${RESP}" -eq "200" ]] && ok_msg || error_msg "No reply from $NGINX_SVC_URL"
else
  error_msg "Nginx URL not available. ($NGINX_SVC_URL)"
fi
popd >/dev/null 2>&1
}

function deploy_wiki() {
pushd $GIT_DIR/flux-demo >/dev/null 2>&1
echo -n "  Creating directory for DokuWiki..."
mkdir -p apps/base/dokuwiki
if [[ $? -eq 0 ]]; then
  ok_msg
else
  error_msg "Cannot create source directory 'apps/base/dokuwiki'"
  exit 1
fi

echo -n "  Creating config file for namespace 'wiki' ..."
cat << EOF > apps/base/dokuwiki/namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: wiki
EOF
[[ $? -eq 0 ]] && ok_msg || error_msg "Cannot create config file for namespace 'wiki'"

echo -n "  Creating config file for 'Helm release'..."
cat << EOF > apps/base/dokuwiki/release.yaml
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
EOF
[[ $? -eq 0 ]] && ok_msg || error_msg "Cannot create config file for 'Helm release'"

echo -n "  Creating config file 'kustomization'..."
cat << EOF > apps/base/dokuwiki/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: wiki
resources:
  - namespace.yaml
  - release.yaml
EOF
[[ $? -eq 0 ]] && ok_msg || error_msg "Cannot create config file for 'kustomization'"

echo -n "  Creating directory for DokuWiki..."
mkdir -p apps/dev/dokuwiki
if [[ $? -eq 0 ]]; then
  ok_msg
else
  error_msg "Cannot create source directory 'apps/dev/dokuwiki'"
  exit 1
fi

echo -n "  Add configuration to file 'kustomization'..."
cat << EOF > apps/dev/dokuwiki/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
name: dokuwiki
namespace: wiki
resources:
  - ../../base/dokuwiki/
EOF
[[ $? -eq 0 ]] && ok_msg || error_msg "Cannot add configuration for file 'kustomization'"

echo -n "  Creating config file 'kustomization'..."
cat << EOF > clusters/dev/dokuwiki.yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1beta2
kind: Kustomization
metadata:
  name: dokuwiki
  namespace: flux-system
spec:
  timeout: 1m0s
  interval: 5m0s
  sourceRef:
    kind: GitRepository
    name: flux-system
  path: ./apps/dev/dokuwiki
  prune: true
EOF
[[ $? -eq 0 ]] && ok_msg || error_msg "Cannot create config file for 'kustomization'"

echo "  Pushing files to git"
echo -n "    Adding files to Git commit..."
git pull >/dev/null 2>&1
git add . >/dev/null 2>&1
[[ $? -eq 0 ]] && ok_msg || error_msg "Cannot add files to Git commit"

echo -n "    Creating Git commit..."
GIT_DIFF=$(git diff --cached | wc -c)
if [[ $GIT_DIFF -eq 0 ]]; then
  ok_msg "(No changes, skipped)"
else
  git commit -m "Added Dokuwiki" >/dev/null 2>&1
  [[ $? -eq 0 ]] && ok_msg || error_msg "Cannot commit to Git"
fi

echo -n "    Pushing commit to Git..."
git push >/dev/null 2>&1
[[ $? -eq 0 ]] && ok_msg || error_msg "Cannot push to Git"

echo -n "  Get response from DokuWiki (wait max. 120s)..."
for t in {1..120}
do
  RET_VAL=$(minikube service dokuwiki -n wiki --url)
  if [[ ! -z "${RET_VAL}" ]]; then
    WIKI_SVC_PORT=$(minikube service dokuwiki -n wiki --url | head -n 1 | cut -d':' -f3)
    WIKI_SVC_URL="http://dokuwiki.local:${WIKI_SVC_PORT}"
    break
  fi
  if [[ $t -eq 120 ]]; then 
    error_msg "Dokuwiki is not in up state under 120s. Exiting..."
    exit 1
  fi
  sleep 1s
done

if [[ ! -z "${WIKI_SVC_URL}" ]]; then
  RESP=0
  for t in {1..60}
  do
  RESP=$(curl -s -o /dev/null -I -w "%{http_code}" $WIKI_SVC_URL)
  [[ "${RESP}" -eq "200" ]] && break
  sleep 1;
  done
  [[ "${RESP}" -eq "200" ]] && ok_msg || error_msg "No reply from $WIKI_SVC_URL"
else
  error_msg "Dokuwiki URL is not ready. ($WIKI_SVC_URL)"
fi

if [[ "${RESP}" -eq "200" ]]; then
  echo
  echo "  Dokuwiki URL: ${WIKI_SVC_URL}"
  echo "  Login: admin/wikiadmin"
fi

popd >/dev/null 2>&1
}

# process_switches
while [[ $# -gt 0 ]]; do
  case $1 in
    -v|--verify-requirements)
      org_functions $2 "verify_requirements"
      shift # past argument
      shift # past value
      ;;
    -e|--prepare-environment)
      org_functions $2 "prepare_environment"
      shift # past argument
      shift # past value
      ;;
    -f|--prepare-flux)
      org_functions $2 "flux_prepare"
      shift # past argument
      shift # past value
      ;;
    -b|--flux-bootstrap)
      org_functions $2 "flux_bootstrap"
      shift # past argument
      shift # past value
      ;;
    -i|--deploy-ingress-controller)
      org_functions $2 "deploy_ingress_controller"
      shift # past argument
      shift # past value
      ;;
    -w|--deploy-wiki)
      org_functions $2 "deploy_wiki"
      shift # past argument
      shift # past value
      ;;
    -h|--help)
      usage
      shift # past argument
      ;;
    -*|--*)
      echo "Unknown option $1"
      exit 1
      ;;
    *)
      shift # past argument
      ;;
  esac
done

main

echo
echo "Done"
