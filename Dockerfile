FROM debian:stretch
MAINTAINER GFG SRE [grabpay.com]

# Steps done in one RUN layer:
# - Install packages
# - OpenSSH needs /var/run/sshd to run
# - Remove generic host keys, entrypoint generates unique keys
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
    openssh-server \
    automake \
    curl \
    build-essential \
    libfuse-dev libcurl4-openssl-dev \
    libtool \
    libxml2-dev mime-support \
    pkg-config libssl-dev \
    tar && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir -p /var/run/sshd && \
    rm -f /etc/ssh/ssh_host_*key*

COPY sshd_config /etc/ssh/sshd_config
COPY entrypoint /

# - add s3fs_fuse filesystem:

ENV VERSION=1.85 REGION=ap-southeast-1 S3_BUCKET_NAME=my-bucket dirPath=/home

RUN curl -L https://github.com/s3fs-fuse/s3fs-fuse/archive/v${VERSION}.tar.gz | tar zxv -C /usr/src
RUN cd /usr/src/s3fs-fuse-${VERSION} && ./autogen.sh && ./configure --prefix=/usr && make && make install

EXPOSE 22

ENTRYPOINT ["/entrypoint"]
