FROM debian:stretch
RUN echo "deb     http://archive.debian.org/debian stretch main"                   >/etc/apt/sources.list
RUN echo "deb-src http://archive.debian.org/debian stretch main"                  >>/etc/apt/sources.list
RUN echo "deb     http://archive.debian.org/debian stretch-backports main"        >>/etc/apt/sources.list
RUN echo "deb     http://archive.debian.org/debian-security stretch/updates main" >>/etc/apt/sources.list
RUN echo "deb-src http://archive.debian.org/debian-security stretch/updates main" >>/etc/apt/sources.list
ARG TARGETARCH
RUN apt-get update && \
    apt-get install -y make \
                       autoconf \
                       automake \
                       libtool \
                       pkg-config \
                       texinfo \
                       openjdk-8-jdk \
                       maven \
                       git \
                       libxml2-dev && \
    if [ "${TARGETARCH}" = amd64 ]; then \
        dpkg --add-architecture i386 && \
        apt-get update && \
        apt-get install -y libicu-dev:i386 \
                           libxml2-dev:i386 \
                           wine32 && \
        ln /usr/lib/x86_64-linux-gnu/libxml2.so.2.9.4 /usr/lib/x86_64-linux-gnu/libxml2.so
    fi
