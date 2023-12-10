# Build Docker Image for Any Dev Env

While Anaconda is powerful enough for managing environments, it is too heavy to use for a product Docker image, especially when compared to more minimalistic Python environments. Therefore, this repo aims to help you build any dev/prod environment for a docker image in the fastest and lightest way. 

Currently, it supports the following configurations:

| parameters                          | info                                                                                                                                                                                        |
| ----------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| -bi, --baseimage                    | specify base docker image. For example: nvidia/cuda:11.7.0-cudnn8-runtime-ubuntu20.04; all valid CUDA and cuDNN base images can be found [here](https://hub.docker.com/r/nvidia/cuda/tags). |
| -cv, --cudaversion                  | specify to cuda version to use                                                                                                                                                              |
| -t, --tag                           | specify tag name for docker image                                                                                                                                                           |
| -ipex, --build-with-ipex            | specify to build with intel_extension_for_pytorch                                                                                                                                           |
| -py, --pythonversion                | specify to python version to use: Possible values: 3.8 3.9 3.10, 3.11                                                                                                                       |
| -torch, --torch_version             | specify pytorch version                                                                                                                                                                     |
| -torchvision, --torchvision_version | specify torch-vision version                                                                                                                                                                |
| -g, --gpu                           | specify to use gpu                                                                                                                                                                          |

- exposed port: 22, 8080
- username: `root`
- password: `root`
- Default Python path: `/home/venv/bin/python`

You can connect with the docker container through ssh in your favorite IDE.

## Quick Start

an example:

```bash
./docker/build_image.sh -g -cv cu121 -py 3.10 -torch 2.1.1 -torchvision 0.16.1
```

## Reference Link

- [torch-sever-github](https://github.com/sachanub/serve/blob/master/docker/README.md)