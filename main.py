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

import argparse
import grpc
import numpy as np
import tensorflow as tf

from concurrent import futures
from vald.v1.payload import payload_pb2
from vald.v1.filter.ingress.ingress_filter_pb2_grpc import (
        FilterServicer,
        add_FilterServicer_to_server,
)

parser = argparse.ArgumentParser(description="Implementation of Tensorflow Ingress Filter")
parser.add_argument("--model_path", type=str, default="/path/to/model",
                    help="path to model directory")
parser.add_argument("--input_tensor_names", nargs="+", type=str, default=["name1", "name2"],
                    help="input tensor names")
parser.add_argument("--output_tensor_name", type=str, default="name",
                    help="output tensor names")
parser.add_argument("--request_type", type=str, default="int32",
                    help="request type")


class TensorflowFilterServicer(FilterServicer):

    def __init__(self, model_path, input_tensor_names, output_tensor_name, request_type):
        super().__init__()
        self.input_tensor_names = input_tensor_names
        self.output_tensor_name = output_tensor_name
        self.request_type = request_type
        self.loaded = tf.saved_model.load(model_path)
        assert "serving_default" in list(self.loaded.signatures.keys())
        self.infer = self.loaded.signatures["serving_default"]
        print("model path:", model_path)
        print("input tensor names:", input_tensor_names)
        print("output tensor name:", output_tensor_name)
        print("request type:", request_type)
        print("signatures keys:", list(self.loaded.signatures.keys()))
        print("inputs:", self.infer.inputs)
        print("outputs:", self.infer.structured_outputs)

    def GenVector(self, request, context):
        reshape_vector = payload_pb2.Object.ReshapeVector()
        reshape_vector.ParseFromString(request.object)

        if self.request_type == "int16":
            data = np.frombuffer(reshape_vector.object, dtype=np.int16)
        elif self.request_type == "int32":
            data = np.frombuffer(reshape_vector.object, dtype=np.int32)
        elif self.request_type == "int64":
            data = np.frombuffer(reshape_vector.object, dtype=np.int64)
        elif self.request_type == "float16":
            data = np.frombuffer(reshape_vector.object, dtype=np.float16)
        elif self.request_type == "float32":
            data = np.frombuffer(reshape_vector.object, dtype=np.float32)
        elif self.request_type == "float64":
            data = np.frombuffer(reshape_vector.object, dtype=np.float64)
        else:
            TypeError()
        data = data.reshape(reshape_vector.shape)
        assert len(self.input_tensor_names) == data.shape[0]
        inputs = {}
        for i, name in enumerate(self.input_tensor_names):
            inputs[name] = data[i:i+1, :]
        outputs = self.infer(**inputs)[self.output_tensor_name].numpy().flatten()

        vec = payload_pb2.Object.Vector(id=request.id, vector=outputs)
        return vec

    def FilterVector(self, request, context):
        return request


def main():
    args = parser.parse_args()

    # start gRPC server
    print("start server...")
    server = grpc.server(futures.ThreadPoolExecutor(max_workers=3))
    add_FilterServicer_to_server(
            TensorflowFilterServicer(
                args.model_path,
                args.input_tensor_names,
                args.output_tensor_name,
                args.request_type),
            server)
    server.add_insecure_port('[::]:8081')
    server.start()
    server.wait_for_termination()


if __name__ == "__main__":
    main()
