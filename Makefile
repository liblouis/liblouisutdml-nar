MVN := mvn
DOCKER := docker
VERSION := $(shell xmllint --xpath "/*/*[local-name()='version']/text()" pom.xml)

TARGET_NAR_LINUX_32  := $(addprefix target/nar/louisutdml-$(VERSION)-i386-Linux-gpp-,executable shared)
TARGET_NAR_LINUX_64  := $(addprefix target/nar/louisutdml-$(VERSION)-amd64-Linux-gpp-,executable shared)
TARGET_NAR_MAC_X64   := $(addprefix target/nar/louisutdml-$(VERSION)-x86_64-MacOSX-gpp-,executable shared)
TARGET_NAR_MAC_ARM64 := $(addprefix target/nar/louisutdml-$(VERSION)-aarch64-MacOSX-gpp-,executable shared)
TARGET_NAR_WIN_32    := $(addprefix target/nar/louisutdml-$(VERSION)-i686-w64-mingw32-gpp-,executable)
TARGET_NAR_WIN_64    := $(addprefix target/nar/louisutdml-$(VERSION)-x86_64-w64-mingw32-gpp-,executable)

.PHONY : all
all : compile-linux compile-windows
compile-linux : $(TARGET_NAR_LINUX_32) $(TARGET_NAR_LINUX_64)
compile-windows : $(TARGET_NAR_WIN_32)

ifeq ($(shell uname -s),Darwin)
all : compile-macosx
ifeq ($(shell uname -m),x86_64)
compile-macosx : $(TARGET_NAR_MAC_X64)
else
compile-macosx : $(TARGET_NAR_MAC_ARM64)
endif
endif

.PHONY : clean
clean :
	$(MVN) clean

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

DOCKER_IMAGE := liblouisutdml-nar_debian

.PHONY : docker-image
docker-image :
	if ! $(DOCKER) images | grep $(DOCKER_IMAGE); then \
		$(DOCKER) buildx create --use --name=mybuilder \
		                        --driver docker-container \
		                        --driver-opt image=moby/buildkit:buildx-stable-1 && \
		$(DOCKER) buildx build --platform linux/amd64 \
		                       -t $(DOCKER_IMAGE) \
		                       --load \
		                       Dockerfile; \
		$(DOCKER) buildx rm mybuilder; \
	fi

mvn-on-linux-amd64 = $(MAKE) docker-image && \
	$(DOCKER) run --platform linux/amd64 \
	              --rm \
	              -v "$(CURDIR):/root/src" \
	              -v "$(CURDIR)/.m2/repository:/root/.m2/repository" \
	              -w "/root/src" \
	              -it $(DOCKER_IMAGE) \
	              mvn $1

$(TARGET_NAR_LINUX_32) : resolve-dependencies-linux-32
	$(call mvn-on-linux-amd64, test -Dos.arch=i386)

$(TARGET_NAR_LINUX_64) : resolve-dependencies-linux-64
	$(call mvn-on-linux-amd64, test)

$(TARGET_NAR_MAC_X64) :
	[[ "$$(uname -s)" == Darwin && "$$(uname -m)" == x86_64 ]]
	$(MVN) test

$(TARGET_NAR_MAC_ARM64) :
	[[ "$$(uname)" == Darwin && "$$(uname -m)" == arm64 ]]
	$(MVN) test

$(TARGET_NAR_WIN_32) : resolve-dependencies-windows
	$(call mvn-on-linux-amd64, --settings settings.xml -DlocalRepository="$(CURDIR)/.m2/repository" \
	                           test -Pcross-compile -Dhost.os=w64-mingw32 -Dos.arch=i686)

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
