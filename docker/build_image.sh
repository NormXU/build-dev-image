#!/bin/bash

set -o errexit -o nounset -o pipefail

MACHINE=cpu
DOCKER_TAG="norm_inui/lab:latest-cpu"
BUILD_TYPE="dev"
BASE_IMAGE="ubuntu:20.04"
USE_CUSTOM_TAG=false
CUDA_VERSION="cu117"
BUILD_WITH_IPEX=false
PYTHON_VERSION=3.9
TORCH_VER="2.0.0"
TORCH_VISION_VER="0.15.1"

for arg in "$@"
do
    case $arg in
        -h|--help)
          echo "options:"
          echo "-h, --help  show brief help"
          echo "-bi, --baseimage specify base docker image. Example: nvidia/cuda:11.7.0-cudnn8-runtime-ubuntu20.04 "
          echo "-cv, --cudaversion specify to cuda version to use"
          echo "-t, --tag specify tag name for docker image"
          echo "-g, --gpu specify to use gpu"
          echo "-ipex, --build-with-ipex specify to build with intel_extension_for_pytorch"
          echo "-py, --pythonversion specify to python version to use: Possible values: 3.8 3.9 3.10"
          echo "-torch, --torch_version specify pytorch version for docker image"
          echo "-torchvision, --torchvision_version specify pytorch vision version for docker image"
          exit 0
          ;;
        -bi|--baseimage)
          BASE_IMAGE="$2"
          shift
          shift
          ;;
        -g|--gpu)
          MACHINE=gpu
          DOCKER_TAG="norm_inui/lab:latest-gpu"
          BASE_IMAGE="nvidia/cuda:11.8.0-base-ubuntu20.04"
          CUDA_VERSION="cu117"
          shift
          ;;
        -t|--tag)
          CUSTOM_TAG="$2"
          USE_CUSTOM_TAG=true
          shift
          shift
          ;;
        -torch| --torch_version)
          TORCH_VER="$2"
          shift
          shift
          ;;
        -torchvision| --torchvision_version)
          TORCH_VISION_VER="$2"
          shift
          shift
          ;;
        -ipex|--build-with-ipex)
          BUILD_WITH_IPEX=true
          shift
          ;;
        -py|--pythonversion)
          PYTHON_VERSION="$2"
          if [[ $PYTHON_VERSION = 3.8 || $PYTHON_VERSION = 3.9 || $PYTHON_VERSION = 3.10 || $PYTHON_VERSION = 3.11 ]]; then
            echo "Valid python version"
          else
            echo "Valid python versions are 3.8, 3.9 3.10 and 3.11"
            exit 1
          fi
          shift
          shift
          ;;
        # With default ubuntu version 20.04
        -cv|--cudaversion)
          CUDA_VERSION="$2"
          if [ "${CUDA_VERSION}" == "cu121" ];
          then
            BASE_IMAGE="nvidia/cuda:12.1.0-base-ubuntu20.04"
          elif [ "${CUDA_VERSION}" == "cu118" ];
          then
            BASE_IMAGE="nvidia/cuda:11.8.0-base-ubuntu20.04"
          elif [ "${CUDA_VERSION}" == "cu117" ];
          then
            BASE_IMAGE="nvidia/cuda:11.7.1-base-ubuntu20.04"
          elif [ "${CUDA_VERSION}" == "cu116" ];
          then
            BASE_IMAGE="nvidia/cuda:11.6.0-cudnn8-runtime-ubuntu20.04"
          elif [ "${CUDA_VERSION}" == "cu113" ];
          then
            BASE_IMAGE="nvidia/cuda:11.3.0-cudnn8-runtime-ubuntu20.04"
          elif [ "${CUDA_VERSION}" == "cu102" ];
          then
            BASE_IMAGE="nvidia/cuda:10.2-cudnn8-runtime-ubuntu18.04"
          else
            echo "CUDA version not supported"
            exit 1
          fi
          shift
          shift
          ;;
    esac
done

if [ "${MACHINE}" == "gpu" ] && $BUILD_WITH_IPEX ;
then
  echo "--gpu and --ipex are mutually exclusive. Please select one of them."
  exit 1
fi


if [ "$USE_CUSTOM_TAG" = true ]
then
  DOCKER_TAG=${CUSTOM_TAG}
else
  DOCKER_TAG="norm_inui/lab:dev-$MACHINE"
fi

echo "DOCKER_TAG:${DOCKER_TAG}"
echo "MACHINE:${MACHINE}"
echo "CUDA_VERSION:${CUDA_VERSION}"
echo "PYTHON_VERSION:${PYTHON_VERSION}"
echo "BASE_IMAGE:${BASE_IMAGE}"
echo "TORCH_VER:${TORCH_VER}"
echo "TORCH_VISION_VER:${TORCH_VISION_VER}"

DOCKER_BUILDKIT=1 docker build --file docker/dev.Dockerfile --build-arg BASE_IMAGE="${BASE_IMAGE}" --build-arg USE_CUDA_VERSION="${CUDA_VERSION}" \
 --build-arg PYTHON_VERSION="${PYTHON_VERSION}" --build-arg BUILD_WITH_IPEX="${BUILD_WITH_IPEX}" \
  -t "${DOCKER_TAG}" --build-arg TORCH_VER="${TORCH_VER}" --build-arg TORCH_VISION_VER="${TORCH_VISION_VER}" --target dev-image .