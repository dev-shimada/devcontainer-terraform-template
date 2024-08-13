FROM debian:bookworm-slim

ARG TARGETARCH
ARG USERNAME=terraform
ARG GROUPNAME=terraform
ARG UID=1000
ARG GID=1000
ARG VERSION=1.9.4
ENV LANG C.UTF-8

WORKDIR /terraform
COPY . /terraform/

RUN apt-get update && apt-get install -y curl unzip zip && \
    groupadd -g $GID $GROUPNAME && \
    useradd -m -s /bin/bash -u $UID -g $GID $USERNAME && \
    chown -R ${USERNAME} /terraform && \ 
    chgrp -R ${GROUPNAME} /terraform

RUN curl -o terraform.zip https://releases.hashicorp.com/terraform/${VERSION}/terraform_${VERSION}_linux_${TARGETARCH}.zip && \
    unzip terraform.zip && \
    rm terraform.zip && \
    mv terraform /usr/local/bin/terraform && \
    chmod +x /usr/local/bin/terraform

USER ${USERNAME}

ENTRYPOINT ["terraform"]
