.POSIX:
.PHONY: *
.EXPORT_ALL_VARIABLES:

KUBECONFIG = $(shell pwd)/metal/kubeconfig.yaml
KUBE_CONFIG_PATH = $(KUBECONFIG)

SET_PROXY = export http_proxy=http://192.168.5.61:1082 && export https_proxy=http://192.168.5.61:1082

default: metal system external smoke-test post-install clean

configure:
	./scripts/configure
	git status

metal:
	make -C metal

system:
	make -C system

external:
	make -C external

smoke-test:
	make -C test filter=Smoke

post-install:
	@./scripts/hacks

tools:
	@$(SET_PROXY)
	@docker run \
		--rm \
		--interactive \
		--tty \
		--network host \
		--env "KUBECONFIG=${KUBECONFIG}" \
		--env "http_proxy=http://192.168.5.61:1082" \
		--env "https_proxy=http://192.168.5.61:1082" \
		--volume "/var/run/docker.sock:/var/run/docker.sock" \
		--volume $(shell pwd):$(shell pwd) \
		--volume ${HOME}/.ssh:/root/.ssh \
		--volume ${HOME}/.terraform.d:/root/.terraform.d \
		--volume homelab-tools-cache:/root/.cache \
		--volume homelab-tools-nix:/nix \
		--workdir $(shell pwd) \
		--entrypoint /bin/sh \
		docker.io/nixos/nix -c "\
		git config --global --add safe.directory $(shell pwd) && \
		nix --experimental-features 'nix-command flakes' develop"

test:
	make -C test

clean:
	docker compose --project-directory ./metal/roles/pxe_server/files down

docs:
	mkdocs serve

git-hooks:
	pre-commit install

set-proxy:
	@$(SET_PROXY)