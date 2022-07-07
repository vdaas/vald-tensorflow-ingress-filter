# vald-tensorflow-ingress-filter

[![Snyk](https://img.shields.io/snyk/vulnerabilities/github/vdaas/vald-tensorflow-ingress-filter)](https://snyk.io/test/github/vdaas/vald-tensorflow-ingress-filter)
[![docker image](https://img.shields.io/docker/pulls/vdaas/vald-tensorflow-ingress-filter?label=vdaas%2Fvald-tensorflow-ingress-filter&logo=docker&style=flat-square)](https://hub.docker.com/r/vdaas/vald-tensorflow-ingress-filter)

vald-tensorflow-ingress-filter is one of the official ingress filter components provided by Vald.

Its custom logic requires the input of the Tensorflow SavedModel as a request and outputs the result from the Tensorflow SavedModel as the request of the Vald Agent.

Using this component lets users vectorize various data such as text and images using the Tensorflow SavedModel only inside the Vald cluster without external APIs.

## Usage

### Deploy vald-tensorflow-ingress-filter

```
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

### Deploy Vald cluster with filter gateway

Please edit the example/helm/values.yaml in the Vald repository to make vald-filter-gateway available and use it for deployment.

```
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

## Sample code with [vald-client-python](https://github.com/vdaas/vald-client-python)

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
