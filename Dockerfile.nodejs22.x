FROM scratch
ADD x86_64/37847fcfda2e335ac1b83561d1b861f7bbef98f7c5ae611c912b4ad5783e2f47.tar.xz /
ADD x86_64/420d12616fd9451b4252b931f266ef329c37d74d1933d24bf477246cce422a24.tar.xz /
ADD x86_64/50a29d5effa42d8713fc73fdcde7b87068a92311b463f402769856b3379d74bf.tar.xz /
ADD x86_64/76ef84a33a499a44f3cea3fb8b5e10899fb5302e14be6d7d5480733c6fcec767.tar.xz /
ADD x86_64/9c1944d708e2e937df596d78f6009f1d663ad69778ca84e221c8013e11cfb95e.tar.xz /
ADD x86_64/d9adbccb6a84b4169863f2c915f12ae6e604eea13a60437337a83ac5b0d41e40.tar.xz /

ENV LANG=en_US.UTF-8
ENV TZ=:/etc/localtime
ENV PATH=/var/lang/bin:/usr/local/bin:/usr/bin/:/bin:/opt/bin

ENV LD_LIBRARY_PATH=/var/lang/lib:/lib64:/usr/lib64:/var/runtime:/var/runtime/lib:/var/task:/var/task/lib:/opt/lib
ENV LAMBDA_TASK_ROOT=/var/task
ENV LAMBDA_RUNTIME_DIR=/var/runtime

WORKDIR /var/task

ENTRYPOINT ["/lambda-entrypoint.sh"]

ENV PATH=/var/lang/bin:$PATH \
  LD_LIBRARY_PATH=/var/lang/lib:$LD_LIBRARY_PATH \
  AWS_EXECUTION_ENV=AWS_Lambda_nodejs22.x \
  NODE_PATH=/opt/nodejs/node22/node_modules:/opt/nodejs/node_modules:/var/runtime/node_modules

RUN dnf remove -y microdnf-dnf && \
  microdnf install -y dnf

RUN dnf groupinstall -y development && \
  dnf install -y \
  tar \
  gzip \
  unzip \
  python3 \
  jq \
  grep \
  make \
  rsync \
  binutils \
  gcc-c++ \
  procps \
  gmp-devel \
  zlib-devel \
  libmpc-devel \
  python3-devel \
  && dnf clean all

# Install AWS CLI
ARG AWS_CLI_ARCH
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-$AWS_CLI_ARCH.zip" -o "awscliv2.zip" && unzip awscliv2.zip && ./aws/install && rm awscliv2.zip && rm -rf ./aws

# Install SAM CLI from native installer
ARG SAM_CLI_VERSION
# need to redefine since ARG is not available after FROM tag: https://docs.docker.com/engine/reference/builder/#understand-how-arg-and-from-interact
ARG IMAGE_ARCH
RUN curl -L "https://github.com/aws/aws-sam-cli/releases/download/v$SAM_CLI_VERSION/aws-sam-cli-linux-$IMAGE_ARCH.zip" -o "samcli.zip" && \
  unzip samcli.zip -d sam-installation && ./sam-installation/install && \
  rm samcli.zip && rm -rf sam-installation && sam --version

# Prepare virtualenv for lambda builders
RUN python3 -m venv --without-pip /usr/local/opt/lambda-builders
RUN curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
RUN LD_LIBRARY_PATH= /usr/local/opt/lambda-builders/bin/python3 get-pip.py
# Install lambda builders in a dedicated Python virtualenv
# Nodejs22 uses a different version (3.1.3) of OpenSSL. This caused an error when Python (installed via dnf) tries to use the ssl module.
# Temporarily set LD_LIBRARY_PATH to empty for python and pip to pick up the right OpenSSL version
RUN AWS_LB_VERSION=$(curl -sSL https://raw.githubusercontent.com/aws/aws-sam-cli/v$SAM_CLI_VERSION/requirements/base.txt | grep aws_lambda_builders | cut -d= -f3) && \
  LD_LIBRARY_PATH= /usr/local/opt/lambda-builders/bin/pip3 --no-cache-dir install "aws-lambda-builders==$AWS_LB_VERSION"

ENV PATH=$PATH:/usr/local/opt/lambda-builders/bin

ENV LANG=en_US.UTF-8

# Wheel is required by SAM CLI to build libraries like cryptography. It needs to be installed in the system
# Python for it to be picked up during `sam build`
RUN LD_LIBRARY_PATH= pip3 install wheel

COPY ATTRIBUTION.txt /

# Compatible with initial base image
ENTRYPOINT []
CMD ["/bin/bash"]