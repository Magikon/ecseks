ARG DIGEST="sha256:027ffb620da90fc79e1b62843b846400ac50b9bc8d87c53d7ba6d6b92b6f2b1d"
ARG DISTRO_VERSION="3.13"
ARG FUNCTION_DIR="/app"
ARG GLIBC_VER="2.31-r0"
ARG RUNTIME_VERSION="3.9.4"
ARG HELM_VERSION="v3.9.0"
ARG USER="ekscontainer"

FROM python:${RUNTIME_VERSION}-alpine${DISTRO_VERSION}@${DIGEST} AS compiler

RUN apk update && \
    apk upgrade && \
    apk add --no-cache \
    libstdc++ \
    binutils \
    curl \
    gzip

FROM compiler AS builder
ARG FUNCTION_DIR
WORKDIR ${FUNCTION_DIR}

RUN apk add --no-cache \
    build-base \
    libtool \
    autoconf \
    automake \
    libexecinfo-dev \
    make \
    cmake \
    libcurl

RUN python3 -m pip install --target ${FUNCTION_DIR} \
    awslambdaric \
    boto3 \
    jinja2 \
    pylint \
    crhelper

COPY app/ ${FUNCTION_DIR}

FROM compiler
ARG FUNCTION_DIR
ARG GLIBC_VER
ARG USER
ARG HELM_VERSION
WORKDIR $FUNCTION_DIR

RUN curl -sLO https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz && tar zxf helm-${HELM_VERSION}-linux-amd64.tar.gz && mv ./linux-amd64/helm /usr/local/bin/helm && \
    curl -sL https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub -o /etc/apk/keys/sgerrand.rsa.pub && \
    curl -sLO https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${GLIBC_VER}/glibc-${GLIBC_VER}.apk && \
    curl -sLO https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${GLIBC_VER}/glibc-bin-${GLIBC_VER}.apk && \
    curl -sLO https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${GLIBC_VER}/glibc-i18n-${GLIBC_VER}.apk && \
    apk add --no-cache \
        glibc-${GLIBC_VER}.apk \
        glibc-bin-${GLIBC_VER}.apk \
        glibc-i18n-${GLIBC_VER}.apk && \
    /usr/glibc-compat/bin/localedef -i en_US -f UTF-8 en_US.UTF-8 && \
    curl -sL https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o awscliv2.zip && \
    unzip awscliv2.zip && \
    aws/install && \
    curl -sL "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp && \
    mv /tmp/eksctl /usr/local/bin && \
    curl -sLO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl && \
    mv ./kubectl /usr/local/bin/kubectl && \
    chmod a+x /usr/local/bin/kubectl && \
    adduser -D ${USER} && \
    rm -rf \
        linux-amd64 \
        awscliv2.zip \
        aws \
        /usr/local/aws-cli/v2/*/dist/aws_completer \
        /usr/local/aws-cli/v2/*/dist/awscli/data/ac.index \
        /usr/local/aws-cli/v2/*/dist/awscli/examples \
        glibc-*.apk && \
    apk --no-cache del && \
    rm -rf /var/cache/apk/*

COPY --from=builder ${FUNCTION_DIR} ${FUNCTION_DIR}

CMD [ "app1.handler" ]
ENTRYPOINT ["/usr/local/bin/python", "-m", "awslambdaric"]