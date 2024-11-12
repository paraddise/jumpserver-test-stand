define TEMPLATE_CHART
apiVersion: v2
name: bundle
version: 1.0.0
endef
export TEMPLATE_CHART

define TEMPLATE_RENDER
{{- range $$path, $$_ := .Files.Glob "render/**" }}
{{ $$.Files.Get $$path }}
---
{{- end }}
endef
export TEMPLATE_RENDER

.SHELLFLAGS = -ec
.ONESHELL:
.DEFAULT_GOAL := all

all: pull build

pull:

build:

project-init:
	@cp ./template/.editorconfig ./.editorconfig
	@cp ./template/.gitignore ./.gitignore

deploy:
	@BUNDLE=$$(cd ./bundle && find * -maxdepth 0 -type d | fzf)
	@[ ! -f ./bundle/$$BUNDLE/Chart.yaml ] && exit 1
	@RELEASE=$$(echo $$BUNDLE | cut -c4-)
	@echo "CONTEXT: $(CONTEXT)"
	@echo "NAMESPACE: $(NAMESPACE)"
	@echo "RELEASE: $$RELEASE"
	@read -p "PRESS ENTER TO CONTINUE" ENTER
	@kubectl ctx $(CONTEXT)
	@helm upgrade $(CONTEXT).$(NAMESPACE).$$RELEASE ./bundle/$$BUNDLE --install --create-namespace --namespace $(NAMESPACE)

pull-clear:
	@rm -rf ./cache

pull-helm:
	@helm pull $(CHART) --untar --destination ./cache --version $(VERSION) --repo $(REPO)

build-clear:
	@rm -rf ./bundle

build-helm-init:
	@mkdir -p ./bundle/$(BUNDLE)/templates
	@echo "$$TEMPLATE_CHART" > ./bundle/$(BUNDLE)/Chart.yaml
	@echo "$$TEMPLATE_RENDER" > ./bundle/$(BUNDLE)/templates/render.yaml

build-helm-render:
	@RELEASE=$$(echo $(BUNDLE) | cut -c4-)
	@helm template $$RELEASE --namespace $(NAMESPACE) $(SOURCE) --dependency-update --values ./source/$(BUNDLE)/values.yaml --output-dir ./bundle/$(BUNDLE)/render --debug

repo-add:
	@if ! helm repo list | grep -q $(REPO); then
		echo "INFO:  repo [$(REPO)] not found"
		read -p "Helm repo name: " NAME
		read -p "Enter username: " USERNAME
		read -p "Enter password: " PASSWORD
		helm repo add $$NAME $(REPO) --username=$$USERNAME --password=$$PASSWORD
		else
			echo "INFO: repo [$(REPO)] already exists with the same configuration, skipping"
		fi

helm-dep-build:
	@helm dependency build $(SOURCE)
