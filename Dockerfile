FROM alpine:edge

ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONPATH=${HOME}/python-hpedockerplugin:/root/python-hpedockerplugin


RUN apk add --no-cache --update \
    py-pip \
    py-setuptools \
    python \
    sysfsutils \
    multipath-tools \
    device-mapper \
    util-linux \
    open-iscsi \
    sg3_utils\
    eudev \
    libssl1.0 \
	sudo \
 && apk update \
 && apk upgrade \
 && apk add e2fsprogs ca-certificates \ 
 && pip install --upgrade pip \
    setuptools \
 && rm -rf /var/cache/apk/*

COPY . /python-hpedockerplugin
#COPY ./iscsiadm /usr/bin/
COPY ./cleanup.sh /usr/bin


RUN apk add --virtual /tmp/.temp --no-cache --update \
    build-base \
    g++ \
    gcc \
    libffi-dev \
    linux-headers \
    open-iscsi \
    make \
    openssl \
	openssh-client \
	openssl-dev \
    python-dev \


# build and install hpedockerplugin
 && cd /python-hpedockerplugin \
 && pip install --upgrade . \
 && python setup.py install \

# apk Cleanups
 && apk del /tmp/.temp \
 && rm -rf /var/cache/apk/*

# We need to have a link to mkfs so that our fileutil module does not error when 
# importing mkfs from the sh module. e2fsprogs does not this by default.
# TODO: Should be a way to fix in our python module
#RUN ln -s /sbin/mkfs.ext4 /sbin/mkfs

# create known_hosts file for ssh
RUN mkdir -p /root/.ssh
RUN touch /root/.ssh/known_hosts
RUN chown -R root:root /root/.ssh
RUN chmod 0600 /root/.ssh/known_hosts
RUN mkdir -p /opt/hpe/data
#RUN chmod u+x /usr/bin/iscsiadm
RUN chmod u+x /usr/bin/cleanup.sh

RUN rm /usr/lib/python2.7/site-packages/os_brick/initiator/connectors/iscsi.pyc
COPY ./patch_os_bricks/iscsi.py /usr/lib/python2.7/site-packages/os_brick/initiator/connectors

WORKDIR /python-hpedockerplugin
ENTRYPOINT ["/bin/sh", "-c", "./plugin-start"]

# Update version.py
ARG TAG
ARG GIT_SHA
ARG BUILD_DATE
RUN sed -i \
    -e "s|{TAG}|$TAG|" \
    -e "s/{GIT_SHA}/$GIT_SHA/" \
    -e "s/{BUILD_DATE}/$BUILD_DATE/" \
    /python-hpedockerplugin/hpedockerplugin/version.py

ENV TAG $TAG
ENV GIT_SHA $GIT_SHA
ENV BUILD_DATE $BUILD_DATE

