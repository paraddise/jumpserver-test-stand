
CONTEXT=kind-jumpserver
NAMESPACE=infra-jumpserver

include template/Makefile

.ONESHELL: install-cilium deploy
.PHONY:

pull:
	@rm -rf ./cache
	@mkdir -p ./cache
	@helm pull --untar -d ./cache jumpserver --repo https://jumpserver.github.io/helm-charts
	@helm pull --untar -d ./cache oci://registry-1.docker.io/bitnamicharts/redis
	@helm pull --untar -d ./cache oci://registry-1.docker.io/bitnamicharts/postgresql

build:
	@make build-clear
	@make build-helm-init BUNDLE=01.jumpserver
	@make build-helm-render BUNDLE=01.jumpserver SOURCE=./cache/jumpserver
	@make build-helm-init BUNDLE=02.redis
	@make build-helm-render BUNDLE=02.redis SOURCE=./cache/redis
	@make build-helm-init BUNDLE=03.postgres
	@make build-helm-render BUNDLE=03.postgres SOURCE=./cache/postgresql
	@make build-helm-init BUNDLE=04.ko-token
	@make build-helm-render BUNDLE=04.ko-token SOURCE=./source/04.ko-token

configure-kubevirt:
	kubectl -n kubevirt patch kubevirt kubevirt --type=merge --patch '{"spec":{"configuration":{"developerConfiguration":{"useEmulation":true}}}}'
	kubectl -n kubevirt patch kubevirt kubevirt --type=merge --patch '{"spec":{"configuration":{"developerConfiguration":{"featureGates":["Root"]}}}}'

.ONESHELL: install-virtctl
install-virtctl:
	VERSION=$$(kubectl get kubevirt.kubevirt.io/kubevirt -n kubevirt -o=jsonpath="{.status.observedKubeVirtVersion}")
	ARCH=$$(uname -s | tr A-Z a-z)-$$(uname -m | sed 's/x86_64/amd64/') || windows-amd64.exe
	echo $${ARCH}
	curl -L -o virtctl https://github.com/kubevirt/kubevirt/releases/download/$${VERSION}/virtctl-$${VERSION}-$${ARCH}
	chmod +x virtctl
	sudo install virtctl /usr/local/bin

install-krew-virt:
	kubectl krew install virt

create-vms:
	kubectl apply -f https://kubevirt.io/labs/manifests/vm.yaml
	kubectl virt start testvm
	kubectl get vmis
	kubectl virt expose vmi testvm --port=22 --name=testvm-ssh

.ONESHELL:
install-cilium:
	helm install cilium cilium --version 1.16.3 --namespace kube-system --repo https://helm.cilium.io/

.ONESHELL: install-lpp
install-lpp:
	kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/v0.0.30/deploy/local-path-storage.yaml

.ONESHELL: install-ingress
install-ingress:
	helm upgrade \
		--install \
		-n infra-ingres-nginx \
		--create-namespace \
		ingress-nginx ingress-nginx \
		--repo https://kubernetes.github.io/ingress-nginx

