# Vald Tensorflow Ingress Filter

<!-- introduction sentence -->

vald-tensorflow-ingress-filter is one of the official ingress filter components provided by Vald.

Its custom logic requires the input of the Tensorflow SavedModel as a request and outputs the result from the Tensorflow SavedModel as the request of the Vald Agent.

Using this component lets users vectorize various data such as text and images using the Tensorflow SavedModel only inside the Vald cluster without external APIs.

<div align="center">
    <img src="https://github.com/vdaas/vald/blob/main/assets/image/readme.svg" width="50%" />
</div>

[![latest Image](https://img.shields.io/docker/v/vdaas/vald-tensorflow-ingress-filter/latest?label=vald-tensorflow-ingress-filter)](https://hub.docker.com/r/vdaas/vald-tensorflow-ingress-filter/tags?page=1&name=latest)
[![License: Apache 2.0](https://img.shields.io/github/license/vdaas/vald.svg?style=flat-square)](https://opensource.org/licenses/Apache-2.0)
[![latest ver.](https://img.shields.io/github/release/vdaas/vald.svg?style=flat-square)](https://github.com/vdaas/vald/releases/latest)
[![Twitter](https://img.shields.io/badge/twitter-follow-blue?logo=twitter&style=flat-square)](https://twitter.com/vdaas_vald)

## Requirement

<!-- FIXME: If image has some requirements, describe here with :warning: emoji -->

<details><summary>linux/amd64</summary><br>

- Libraries: kubectl, Helm, grpcio, numpy, tensorflow, vald-client-python
- Others: Vald cluster

</details>

## Get Started

<!-- Get Started -->
<!-- Vald Agent NGT requires more chapter Agent Standalone -->

`vald-tensorflow-ingress-filter` is used for ingress filter component of the Vald cluster, which means it should be used on the Kubernetes cluster, not the local environment or Docker.

The steps are following:

1. Deploy vald-tensorflow-ingress-filter

   ```bash
   git clone https://github.com/vdaas/vald-tensorflow-ingress-filter.git
   kubectl apply -f vald-tensorflow-ingress-filter/k8s
   ```

   The official image only supports amd64.

   NOTE: The example manifest files use BERT from [Tensorflow Hub](https://www.tensorflow.org/hub) as the Tensorflow SavedModel. You can change the model by editing k8s/deployment.yaml.

   ```
   ...
     - |
       curl -L "https://tfhub.dev/tensorflow/bert_en_uncased_L-12_H-768_A-12/4?tf-hub-format=compressed" -o /model/sample.tar.gz  #FIXME
   ...
     env:
       - name: MODEL_PATH
         value: "/model"  #FIXME
       - name: INPUT_TENSOR_NAMES
         value: "name1 name2"  #FIXME
       - name: OUTPUT_TENSOR_NAME
         value: "name"  #FIXME
       - name: REQUEST_TYPE
         value: "int32"  #FIXME
   ```

1. Deploy the Vald cluster with filter gateway

   Please edit the [`example/helm/values.yaml`](https://github.com/vdaas/vald/blob/main/example/helm/values.yaml) in the Vald repository to make vald-filter-gateway available and use it for deployment.

   ```bash
   git clone https://github.com/vdaas/vald.git
   cd vald

   vim example/helm/values.yaml
   ---
   ...
   gateway:
   ...
       filter:
           enabled: true
   ...
   agent:
       ngt:
           dimension: 768
   ```

### Sample code with [vald-client-python](https://github.com/vdaas/vald-client-python)

```python
import grpc
import numpy as np
import tensorflow_hub as hub
import tensorflow_text as text
from vald.v1.payload import payload_pb2
from vald.v1.vald import (
    filter_pb2_grpc,
    search_pb2_grpc,
)

# preprocess
preprocess = hub.load('https://tfhub.dev/tensorflow/bert_en_uncased_preprocess/1')
token = preprocess(["TF Hub makes BERT easy!"])
sample = np.vstack([i for i in token.values()])

channel = grpc.insecure_channel("localhost:8081")

# Insert
stub = filter_pb2_grpc.FilterStub(channel)
resize_vector = payload_pb2.Object.ReshapeVector(
    object=sample.tobytes(),
    shape=[3, 128],
)
resize_vector = resize_vector.SerializeToString()

req = payload_pb2.Insert.ObjectRequest(
    object=payload_pb2.Object.Blob(
        id="0",
        object=resize_vector
    ),
    config=payload_pb2.Insert.Config(skip_strict_exist_check=False),
    vectorizer=payload_pb2.Filter.Target(
        host="vald-tensorflow-ingress-filter",
        port=8081,
    )
)
stub.InsertObject(req)
```

## Versions

| tag     |    linux/amd64     | linux/arm64 | description                                                                                                                 |
| :------ | :----------------: | :---------: | :-------------------------------------------------------------------------------------------------------------------------- |
| latest  | :white_check_mark: |     :x:     | the latest image is the same as the latest version of [vdaas/vald](https://github.com/vdaas/vald) repository version.       |
| nightly | :white_check_mark: |     :x:     | the nightly applies the main branch's source code of the [vdaas/vald](https://github.com/vdaas/vald) repository.            |
| vX.Y.Z  | :white_check_mark: |     :x:     | the vX.Y.Z image applies the source code of the [vdaas/vald](https://github.com/vdaas/vald) repository.                     |
| pr-XXX  | :white_check_mark: |     :x:     | the pr-X image applies the source code of the pull request X of the [vdaas/vald](https://github.com/vdaas/vald) repository. |

## Dockerfile

<!-- FIXME -->

The `Dockerfile` of this image is [here](https://github.com/vdaas/vald/blob/main/dockers/agent/core/ngt/Dockerfile).

## About Vald Project

<!-- About Vald Project -->
<!-- This chapter is static -->

The information about the Vald project, please refer to the following:

- [Official website](https://vald.vdaas.org)
- [GitHub](https://github.com/vdaas/vald)

## Contacts

We're love to support you!
Please feel free to contact us anytime with your questions or issue reports.

- [Official Slack WS](https://join.slack.com/t/vald-community/shared_invite/zt-db2ky9o4-R_9p2sVp8xRwztVa8gfnPA)
- [GitHub Issue](https://github.com/vdaas/vald/issues)

## License

This product is under the terms of the Apache License v2.0; refer [LICENSE](https://github.com/vdaas/vald/blob/main/LICENSE) file.
