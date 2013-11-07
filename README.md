Build
-----

    mvn clean install

To build for 32 bit on a 64 bit machine:

    mvn clean install -Dos.arch=i386

To download libxml2 and compile/link against that version instead of the version you have installed
on your system, activate the profile `download-libxml2`. Do this if you are cross-compiling, or if
you are shipping libxml2 with liblouisutdml.

    mvn clean install -P download-libxml2 -Dos.arch=i386

To cross-compile for Windows using [MinGW](http://www.mingw.org/) ([Mac version](http://crossgcc.rts-software.org/doku.php)) or [MinGW-w64](http://mingw-w64.sourceforge.net/)
-- also requires [Wine](http://www.winehq.org/) ([Mac version](http://code.google.com/p/darwine-builds/downloads/list)) for testing:

    mvn clean install -P cross-compile,download-libxml2 -Dhost.os=mingw32 -Dos.arch=i386
    mvn clean install -P cross-compile,download-libxml2 -Dhost.os=w64-mingw32 -Dos.arch=x86_64
    mvn clean install -P cross-compile,download-libxml2 -Dhost.os=mingw32msvc -Dos.arch=i586

To install pkg-config on Mac OS X:

    brew install pkg-config
    sudo ln -s /usr/local/share/aclocal/pkg.m4 /usr/share/aclocal
Deploy
------

To deploy to Sonatype OSS, use the `sonatype-deploy` profile:

    mvn clean deploy -P sonatype-deploy
