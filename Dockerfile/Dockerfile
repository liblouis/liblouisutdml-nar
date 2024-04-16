FROM debian:stretch
RUN echo "deb     http://archive.debian.org/debian stretch main"                   >/etc/apt/sources.list
RUN echo "deb-src http://archive.debian.org/debian stretch main"                  >>/etc/apt/sources.list
RUN echo "deb     http://archive.debian.org/debian stretch-backports main"        >>/etc/apt/sources.list
RUN echo "deb     http://archive.debian.org/debian-security stretch/updates main" >>/etc/apt/sources.list
RUN echo "deb-src http://archive.debian.org/debian-security stretch/updates main" >>/etc/apt/sources.list
RUN apt-get update && \
    apt-get install -y make \
                       autoconf \
                       automake \
                       libtool \
                       pkg-config \
                       texinfo \
                       libc6-dev-i386 \
                       mingw-w64 \
                       openjdk-8-jdk \
                       maven \
                       git \
                       libxml2-dev
RUN dpkg --add-architecture i386 && \
    apt-get update && \
    apt-get install -y libicu-dev:i386 \
                       libxml2-dev:i386 \
                       wine32
RUN ln /usr/lib/x86_64-linux-gnu/libxml2.so.2.9.4 /usr/lib/x86_64-linux-gnu/libxml2.so
