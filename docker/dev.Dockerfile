# syntax = docker/dockerfile:experimental
#
# This file can build images for cpu and gpu env. By default it builds image for CPU.
# Use following option to build image for cuda/GPU: --build-arg BASE_IMAGE=nvidia/cuda:10.1-cudnn7-runtime-ubuntu18.04
# Here is complete command for GPU/cuda -
# $ DOCKER_BUILDKIT=1 docker build --file Dockerfile --build-arg BASE_IMAGE=nvidia/cuda:10.1-cudnn7-runtime-ubuntu18.04 -t torchserve:latest .
#
# Following comments have been shamelessly copied from https://github.com/pytorch/pytorch/blob/master/Dockerfile
#
# NOTE: To build this you will need a docker version > 18.06 with
#       experimental enabled and DOCKER_BUILDKIT=1
#
#       If you do not use buildkit you are not going to have a good time
#
#       For reference:
#           https://docs.docker.com/develop/develop-images/build_enhancements/


ARG BASE_IMAGE=ubuntu:rolling

# Note:
# Define here the default python version to be used in all later build-stages as default.
# ARG and ENV variables do not persist across stages (they're build-stage scoped).
# That is crucial for ARG PYTHON_VERSION, which otherwise becomes "" leading to nasty bugs,
# that don't let the build fail, but break current version handling logic and result
# in images with wrong python version. To fix that, we will restate the ARG PYTHON_VERSION
# on each build-stage.
ARG PYTHON_VERSION=3.9

FROM ${BASE_IMAGE} AS compile-image
ARG BASE_IMAGE=ubuntu:rolling
ARG PYTHON_VERSION
ENV PYTHONUNBUFFERED TRUE
ADD docker/pip.conf /etc/pip.conf

RUN --mount=type=cache,id=apt-dev,target=/var/cache/apt \
    apt-get update && \
    apt-get upgrade -y && \
    apt-get install software-properties-common -y && \
    add-apt-repository -y ppa:deadsnakes/ppa && \
    apt remove python-pip  python3-pip && \
    DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
        ca-certificates \
        g++ \
        python3-distutils \
        python$PYTHON_VERSION \
        python$PYTHON_VERSION-dev \
        python$PYTHON_VERSION-venv \
        openjdk-17-jdk \
        curl \
        git \
    && rm -rf /var/lib/apt/lists/*

# Make the virtual environment and "activating" it by adding it first to the path.
# From here on the python$PYTHON_VERSION interpreter is used and the packages
# are installed in /home/venv which is what we need for the "runtime-image"
RUN python$PYTHON_VERSION -m venv /home/venv
ENV PATH="/home/venv/bin:$PATH"

RUN python -m pip install -U pip setuptools

# This is only useful for cuda env
RUN export USE_CUDA=1

ARG CUDA_VERSION=""
ARG TORCH_VER=""
ARG TORCH_VISION_VER=""

RUN if [ "$TORCH_VER" = "" ] || [ $TORCH_VISION_VER = "" ] ; then \
        TORCH_VER=$(curl --silent --location https://pypi.org/pypi/torch/json | python -c "import sys, json, pkg_resources; releases = json.load(sys.stdin)['releases']; print(sorted(releases, key=pkg_resources.parse_version)[-1])"); \
        TORCH_VISION_VER=$(curl --silent --location https://pypi.org/pypi/torchvision/json | python -c "import sys, json, pkg_resources; releases = json.load(sys.stdin)['releases']; print(sorted(releases, key=pkg_resources.parse_version)[-1])"); \
    else \
        TORCH_VER=$TORCH_VER; \
        TORCH_VISION_VER=$TORCH_VISION_VER; \
    fi && \
    # Specify TORCH_VER and TORCH_VISION_VER
    if echo "$BASE_IMAGE" | grep -q "cuda:"; then \
        # Install CUDA version specific binary when CUDA version is specified as a build arg
        if [ "$CUDA_VERSION" ]; then \
            pip install --no-cache-dir torch==$TORCH_VER+$CUDA_VERSION torchvision==$TORCH_VISION_VER+$CUDA_VERSION -f https://download.pytorch.org/whl/torch_stable.html; \
        # Install the binary with the latest CUDA version support
        else \
            pip install --no-cache-dir torch torchvision; \
        fi \
    # Install the CPU binary
    else \
        pip install --no-cache-dir torch==$TORCH_VER+cpu torchvision==$TORCH_VISION_VER+cpu -f https://download.pytorch.org/whl/torch_stable.html; \
    fi

COPY all_requirements.txt all_requirements.txt
COPY requirements requirements
RUN pip install --no-cache-dir -r all_requirements.txt && rm -rf all_requirements.txt  && rm -rf requirements

#Final image for developer Docker image
FROM ${BASE_IMAGE} as dev-image
MAINTAINER norm_inui
# Re-state ARG PYTHON_VERSION to make it active in this build-stage (uses default define at the top)
ARG PYTHON_VERSION
ARG BUILD_WITH_IPEX
ARG IPEX_VERSION=1.11.0
ARG IPEX_URL=https://software.intel.com/ipex-whl-stable
ENV PYTHONUNBUFFERED TRUE
RUN --mount=type=cache,target=/var/cache/apt \
    apt-get update && \
    apt-get upgrade -y && \
    apt-get install software-properties-common -y && \
    add-apt-repository -y ppa:deadsnakes/ppa && \
    DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
    fakeroot \
    ca-certificates \
    dpkg-dev \
    tmux \
    sudo \
    g++ \
    git \
    python$PYTHON_VERSION \
    python$PYTHON_VERSION-dev \
    python3-distutils \
    python$PYTHON_VERSION-venv \
    # using openjdk-17-jdk due to circular dependency(ca-certificates) bug in openjdk-17-jre-headless debian package
    # https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=1009905
    openjdk-17-jdk \
    build-essential \
    openssh-server \
    ffmpeg \
    wget \
    screen \
    libsm6 \
    libxext6 \
    curl \
    vim \
    numactl \
    && if [ "$BUILD_WITH_IPEX" = "true" ]; then apt-get update && apt-get install -y libjemalloc-dev libgoogle-perftools-dev libomp-dev && ln -s /usr/lib/x86_64-linux-gnu/libjemalloc.so /usr/lib/libjemalloc.so && ln -s /usr/lib/x86_64-linux-gnu/libtcmalloc.so /usr/lib/libtcmalloc.so && ln -s /usr/lib/x86_64-linux-gnu/libiomp5.so /usr/lib/libiomp5.so; fi \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/run/sshd
RUN echo 'root:root' | chpasswd
RUN sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
RUN echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config

# SSH login fix. Otherwise user is kicked off after login
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd
ENV NOTVISIBLE "in users profile"
RUN echo "export VISIBLE=now" >> /etc/profile

COPY --from=compile-image /home/venv /home/venv
ENV PATH="/home/venv/bin:$PATH"

EXPOSE 22 8080
ENV TZ Asia/Shanghai

WORKDIR /home/workspace
ENV TEMP=/home/workspace/tmp

CMD /usr/sbin/sshd -D