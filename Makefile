# terrame-goldens — reference outputs of the TerraME packages ca, sysdyn and logo

DOCKER_IMAGE ?= profsergiocosta/terrame-luccme:0.4.2
SEEDS ?= 50
JOBS ?= 2
VERSION ?= v0.1.0

.PHONY: help packages run-docker run-local build check

help:
	@echo "make packages        Clone the TerraME packages of packages.lock at their commits"
	@echo "make run-docker      Generate the raw goldens in Docker (build/)"
	@echo "make run-local       Same, with a TerraME installed here (TME_PATH)"
	@echo "make build GENERATOR='...'   Compress, hash and write manifest.json"
	@echo "make check           Verify checksums.sha256"

packages:
	bash scripts/fetch_packages.sh

run-docker:
	bash scripts/run_docker.sh $(DOCKER_IMAGE) $(SEEDS) $(JOBS)

run-local:
	bash scripts/run_local.sh build $(SEEDS) $(JOBS)

build:
	python3 scripts/build_goldens.py --version $(VERSION) --seeds $(SEEDS) --generator "$(GENERATOR)"

check:
	sha256sum -c --quiet checksums.sha256 && echo "checksums ok"
