Build
-----

To build for all platforms at once:

    docker-compose build debian
    make clean all

This requires [Docker](https://www.docker.com). Mac binaries will only
be build if the host platform is Mac OS.

To install pkg-config on Mac OS X:

    brew install pkg-config
    sudo ln -s /usr/local/share/aclocal/pkg.m4 /usr/share/aclocal

To install libxml2 on Mac OS X:

    brew install libxml2

Deploy
------

To deploy a snapshot to Sonatype OSS:

    make snapshot

To make a release:

    make release
