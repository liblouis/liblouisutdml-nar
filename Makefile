MVN := mvn
COMPOSE := docker-compose
VERSION := 2.7.1-SNAPSHOT

TARGET_NAR_LINUX_32 := $(addprefix target/nar/louisutdml-$(VERSION)-i386-Linux-gpp-,executable shared)
TARGET_NAR_LINUX_64 := $(addprefix target/nar/louisutdml-$(VERSION)-amd64-Linux-gpp-,executable shared)
TARGET_NAR_MAC_32   := $(addprefix target/nar/louisutdml-$(VERSION)-i386-MacOSX-gpp-,executable shared)
TARGET_NAR_MAC_64   := $(addprefix target/nar/louisutdml-$(VERSION)-x86_64-MacOSX-gpp-,executable shared)
TARGET_NAR_WIN_32   := $(addprefix target/nar/louisutdml-$(VERSION)-i686-w64-mingw32-gpp-,executable shared)
TARGET_NAR_WIN_64   := $(addprefix target/nar/louisutdml-$(VERSION)-x86_64-w64-mingw32-gpp-,executable shared)

all : compile-linux compile-macosx compile-windows

clean :
	$(MVN) clean

compile-linux : $(TARGET_NAR_LINUX_32) $(TARGET_NAR_LINUX_64)
compile-macosx : $(TARGET_NAR_MAC_64)
compile-windows : $(TARGET_NAR_WIN_32) $(TARGET_NAR_WIN_64)

resolve-dependencies :
	$(MVN) --settings settings.xml -DlocalRepository="$(CURDIR)/.m2/repository" \
	       "org.apache.maven.plugins:maven-dependency-plugin:3.1.1:resolve" \
	       "org.apache.maven.plugins:maven-dependency-plugin:3.1.1:resolve-plugins"

$(TARGET_NAR_LINUX_32) : resolve-dependencies
	$(COMPOSE) run debian $(MVN) test -Dos.arch=i386

$(TARGET_NAR_LINUX_64) : resolve-dependencies
	$(COMPOSE) run debian $(MVN) test

$(TARGET_NAR_MAC_32) :
	[[ "$$(uname)" == Darwin ]]
	$(MVN) test -Dos.arch=i386

$(TARGET_NAR_MAC_64) :
	[[ "$$(uname)" == Darwin && "$$(uname -m)" == x86_64 ]]
	$(MVN) test

$(TARGET_NAR_WIN_32) : resolve-dependencies
	$(COMPOSE) run debian $(MVN) --settings settings.xml -DlocalRepository="$(CURDIR)/.m2/repository" \
	                             test -Pcross-compile -Dhost.os=w64-mingw32 -Dos.arch=i686

$(TARGET_NAR_WIN_64) : resolve-dependencies
	$(COMPOSE) run debian $(MVN) --settings settings.xml -DlocalRepository="$(CURDIR)/.m2/repository" \
	                             test -Pcross-compile -Dhost.os=w64-mingw32 -Dos.arch=x86_64

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
