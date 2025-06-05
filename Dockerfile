# SimpleTuner needs CU141
FROM nvidia/cuda:12.4.1-cudnn-devel-ubuntu22.04

# /workspace is the default volume for Runpod & other hosts
WORKDIR /workspace

# Update apt-get
RUN apt-get update -y

# Prevents different commands from being stuck by waiting
# on user input during build
ENV DEBIAN_FRONTEND=noninteractive

# Install libg dependencies
RUN apt install libgl1-mesa-glx -y
RUN apt-get install 'ffmpeg'\
    'libsm6'\
    'libxext6'  -y

# Install misc unix libraries
RUN apt-get install -y --no-install-recommends openssh-server \
                                               openssh-client \
                                               git \
                                               git-lfs \
                                               wget \
                                               curl \
                                               tmux \
                                               tldr \
                                               nvtop \
                                               vim \
                                               rsync \
                                               net-tools \
                                               less \
                                               iputils-ping \
                                               7zip \
                                               zip \
                                               unzip \
                                               htop \
                                               inotify-tools

# Set up git to support LFS, and to store credentials; useful for Huggingface Hub
RUN git config --global credential.helper store && \
    git lfs install

# Install Python VENV
RUN apt-get install -y python3.10-venv

# Ensure SSH access. Not needed for Runpod but is required on Vast and other Docker hosts
EXPOSE 22/tcp

# Python
RUN apt-get update -y && apt-get install -y python3 python3-pip
RUN python3 -m pip install pip --upgrade

# HF
# ENV HF_HOME=/workspace/huggingface

ENV POETRY_REQUESTS_MAX_RETRIES=3
ENV POETRY_REQUESTS_TIMEOUT=150

RUN pip3 install "huggingface_hub[cli]"

# WanDB
RUN pip3 install wandb

# Clone SimpleTuner
RUN git clone https://github.com/FabioLddo/SimpleTuner.git --branch release
# RUN git clone https://github.com/FabioLddo/SimpleTuner.git --branch main # Uncomment to use latest (possibly unstable) version

# Install SimpleTuner
RUN pip3 install poetry
RUN cd SimpleTuner && python3 -m venv .venv && poetry install --no-root && poetry add einops_exts
RUN chmod +x SimpleTuner/train.sh

# Copy start script with exec permissions
COPY --chmod=755 docker-start.sh /start.sh

# Dummy entrypoint
# ENTRYPOINT [ "/start.sh" ]

# docker run --gpus all --rm -it -v $(pwd):/workspace -e WANDB_API_KEY=$WANDB_API_KEY -e HF_TOKEN=$HUGGING_FACE_HUB_TOKEN -p 7007:7007 floddo/simpletuner:latest bash
# docker run --gpus all --rm -it -e WANDB_API_KEY=$WANDB_API_KEY -e HF_TOKEN=$HUGGING_FACE_HUB_TOKEN -p 7007:7007 floddo/simpletuner:v1.3.0 bash
# docker run --gpus all -e WANDB_API_KEY=$WANDB_API_KEY -e HF_TOKEN=$HUGGING_FACE_HUB_TOKEN -p 22:22 simpletuner
# docker run --gpus all --rm -it -e WANDB_API_KEY=$WANDB_API_KEY -e HF_TOKEN=$HUGGING_FACE_HUB_TOKEN floddo/simpletuner
