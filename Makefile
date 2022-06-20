MVN := mvn
COMPOSE := docker-compose
VERSION := 2.8.0-p1-SNAPSHOT

TARGET_NAR_LINUX_32 := $(addprefix target/nar/louisutdml-$(VERSION)-i386-Linux-gpp-,executable shared)
TARGET_NAR_LINUX_64 := $(addprefix target/nar/louisutdml-$(VERSION)-amd64-Linux-gpp-,executable shared)
TARGET_NAR_MAC_32   := $(addprefix target/nar/louisutdml-$(VERSION)-i386-MacOSX-gpp-,executable shared)
TARGET_NAR_MAC_64   := $(addprefix target/nar/louisutdml-$(VERSION)-x86_64-MacOSX-gpp-,executable shared)
TARGET_NAR_WIN_32   := $(addprefix target/nar/louisutdml-$(VERSION)-i686-w64-mingw32-gpp-,executable)
TARGET_NAR_WIN_64   := $(addprefix target/nar/louisutdml-$(VERSION)-x86_64-w64-mingw32-gpp-,executable)

all : compile-linux compile-macosx compile-windows

clean :
	$(MVN) clean

compile-linux : $(TARGET_NAR_LINUX_32) $(TARGET_NAR_LINUX_64)
compile-macosx : $(TARGET_NAR_MAC_64)
compile-windows : $(TARGET_NAR_WIN_32)

.PHONY : resolve-dependencies
resolve-dependencies :
	$(MVN) --settings settings.xml -DlocalRepository="$(CURDIR)/.m2/repository" \
	       "org.apache.maven.plugins:maven-dependency-plugin:3.1.1:resolve" \
	       "org.apache.maven.plugins:maven-dependency-plugin:3.1.1:resolve-plugins"
	$(MVN) --settings settings.xml -DlocalRepository="$(CURDIR)/.m2/repository" \
	       "org.apache.maven.plugins:maven-dependency-plugin:3.1.1:resolve" \
	       -Dclassifier=noarch

.PHONY : resolve-dependencies-linux-32
resolve-dependencies-linux-32 : resolve-dependencies
	$(MVN) --settings settings.xml -DlocalRepository="$(CURDIR)/.m2/repository" \
	       "org.apache.maven.plugins:maven-dependency-plugin:3.1.1:resolve" \
	       -Dclassifier=i386-Linux-gpp-executable
	$(MVN) --settings settings.xml -DlocalRepository="$(CURDIR)/.m2/repository" \
	       "org.apache.maven.plugins:maven-dependency-plugin:3.1.1:resolve" \
	       -Dclassifier=i386-Linux-gpp-shared

.PHONY : resolve-dependencies-linux-64
resolve-dependencies-linux-64 : resolve-dependencies
	$(MVN) --settings settings.xml -DlocalRepository="$(CURDIR)/.m2/repository" \
	       "org.apache.maven.plugins:maven-dependency-plugin:3.1.1:resolve" \
	       -Dclassifier=amd64-Linux-gpp-executable
	$(MVN) --settings settings.xml -DlocalRepository="$(CURDIR)/.m2/repository" \
	       "org.apache.maven.plugins:maven-dependency-plugin:3.1.1:resolve" \
	       -Dclassifier=amd64-Linux-gpp-shared

.PHONY : resolve-dependencies-windows
resolve-dependencies-windows : resolve-dependencies
	$(MVN) --settings settings.xml -DlocalRepository="$(CURDIR)/.m2/repository" \
	       "org.apache.maven.plugins:maven-dependency-plugin:3.1.1:resolve" \
	       -Dclassifier=i686-w64-mingw32-gpp-executable
	$(MVN) --settings settings.xml -DlocalRepository="$(CURDIR)/.m2/repository" \
	       "org.apache.maven.plugins:maven-dependency-plugin:3.1.1:resolve" \
	       -Dclassifier=i686-w64-mingw32-gpp-shared

$(TARGET_NAR_LINUX_32) : resolve-dependencies-linux-32
	$(COMPOSE) run debian $(MVN) test -Dos.arch=i386

$(TARGET_NAR_LINUX_64) : resolve-dependencies-linux-64
	$(COMPOSE) run debian $(MVN) test

$(TARGET_NAR_MAC_32) :
	[[ "$$(uname)" == Darwin ]]
	$(MVN) test -Dos.arch=i386

$(TARGET_NAR_MAC_64) :
	[[ "$$(uname)" == Darwin && "$$(uname -m)" == x86_64 ]]
	$(MVN) test

$(TARGET_NAR_WIN_32) : resolve-dependencies-windows
	$(COMPOSE) run debian $(MVN) --settings settings.xml -DlocalRepository="$(CURDIR)/.m2/repository" \
	                             test -Pcross-compile -Dhost.os=w64-mingw32 -Dos.arch=i686

snapshot :
	[[ $(VERSION) == *-SNAPSHOT ]]
	$(MVN) nar:nar-prepare-package nar:nar-package install:install deploy:deploy

release :
	[[ $(VERSION) != *-SNAPSHOT ]]
	$(MVN) nar:nar-prepare-package nar:nar-package jar:jar gpg:sign install:install \
	       org.sonatype.plugins:nexus-staging-maven-plugin:1.6.8:deploy \
	       -Psonatype-deploy \
	       -DnexusUrl=https://oss.sonatype.org/ \
	       -DserverId=sonatype-nexus-staging \
	       -DstagingDescription='$(VERSION)' \
	       -DkeepStagingRepositoryOnCloseRuleFailure=true

install :
	$(MVN) nar:nar-prepare-package nar:nar-package jar:jar install:install
