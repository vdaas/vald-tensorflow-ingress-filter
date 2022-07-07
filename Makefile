#
# Copyright (C) 2019-2022 vdaas.org vald team <vald@vdaas.org>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

ORG                             ?= vdaas
NAME                            = vald
TENSORFLOW_INGRESS_FILTER_IMAGE = $(NAME)-tensorflow-ingress-filter
TAG                             ?= latest
MAINTAINER                      = "$(ORG).org $(NAME) team <$(NAME)@$(ORG).org>"
DOCKER                          ?= docker
DOCKER_OPTS                     ?=
DISTROLESS_IMAGE                ?= gcr.io/distroless/python3-debian11
DISTROLESS_IMAGE_TAG            ?= nonroot

.PHONY: version
version:
	@cat VALD_TENSORFLOW_INGRESS_FILTER_VERSION

.PHONY: docker/platforms
docker/platforms:
	@echo "linux/amd64"

.PHONY: docker/name/tensorflow-ingress-filter
docker/name/tensorflow-ingress-filter:
	@echo "$(ORG)/$(TENSORFLOW_INGRESS_FILTER_IMAGE)"

.PHONY: docker/name/tag/version
docker/name/tag/version:
	@$(eval VERSION_TAG := `cat VALD_TENSORFLOW_INGRESS_FILTER_VERSION`)
	@echo "$(ORG)/$(TENSORFLOW_INGRESS_FILTER_IMAGE):$(VERSION_TAG)"

.PHONY: docker/build/tensorflow-ingress-filter
docker/build/tensorflow-ingress-filter:
	$(DOCKER) build \
	    $(DOCKER_OPTS) \
	    -f Dockerfile \
	    -t $(ORG)/$(TENSORFLOW_INGRESS_FILTER_IMAGE):$(TAG) . \
	    --build-arg DISTROLESS_IMAGE=$(DISTROLESS_IMAGE) \
	    --build-arg DISTROLESS_IMAGE_TAG=$(DISTROLESS_IMAGE_TAG) \
	    --build-arg MAINTAINER=$(MAINTAINER)

