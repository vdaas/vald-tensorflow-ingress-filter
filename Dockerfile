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

ARG PYTHON_IMAGE=python
ARG PYTHON_IMAGE_TAG=3.9-slim
ARG DISTROLESS_IMAGE=gcr.io/distroless/python3-debian11
ARG DISTROLESS_IMAGE_TAG=nonroot
ARG MAINTAINER="vdaas.org vald team <vald@vdaas.org>"

FROM ${PYTHON_IMAGE}:${PYTHON_IMAGE_TAG} AS build

COPY requirements.txt /requirements.txt

RUN apt-get update \
    && apt-get install --no-install-suggests --no-install-recommends --yes \
      dumb-init \
      gcc \
      libpython3-dev \
    && pip install --upgrade pip \
    && pip install --disable-pip-version-check -r /requirements.txt

# Copy the site-pacakges into a distroless image
FROM ${DISTROLESS_IMAGE}:${DISTROLESS_IMAGE_TAG}
LABEL maintainer "${MAINTAINER}"

ENV APP_NAME tensorflow
ENV MODEL_PATH /path/to/saved_model
ENV INPUT_TENSOR_NAMES name1 name2
ENV OUTPUT_TENSOR_NAME name
ENV REQUEST_TYPE int32

USER nonroot:nonroot

COPY --from=build /usr/bin/dumb-init /usr/bin/dumb-init
COPY --from=build /usr/local/lib/python3.9/site-packages /usr/local/lib/python3.9/dist-packages
COPY entrypoint.sh /app/entrypoint.sh
COPY main.py /app/main.py

WORKDIR /app
ENTRYPOINT ["/usr/bin/dumb-init", "--"]
CMD ["/app/entrypoint.sh"]
