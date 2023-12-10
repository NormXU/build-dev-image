# Build Docker Image for Any Dev Env
This repo helps you build docker image for any dev environment in the fastest way.

Currently, it supports the following configurations:

- `-bi, --baseimage`: specify base docker image. For example: `nvidia/cuda:11.7.0-cudnn8-runtime-ubuntu20.04`; all valid CUDA and cuDNN base images can be found [here](https://hub.docker.com/r/nvidia/cuda/tags).

- `-cv, --cudaversion` specify to cuda version to use

- `-t, --tag` specify tag name for docker image

- `-ipex, --build-with-ipex` specify to build with intel_extension_for_pytorch

- `-py, --pythonversion` specify to python version to use: Possible values: 3.8 3.9 3.10

- `-torch, --torch_version` specify pytorch version

- `-torchvision, --torchvision_version` specify pytorch-vision version
- `-g, --gpu` specify to use gpu

port 22 and port 8080 are exposed. 
## Quick Start
an example:
```bash
./docker/build_image.sh -g -cv cu121 -py 3.10 -torch 2.1.1 -torchvision 0.16.1
```



