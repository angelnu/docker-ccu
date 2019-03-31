FROM python as builder

#CCU firmware version to download
ARG CCU_VERSION="3.41.11"

#CCU Serial Number
ARG CCU_SERIAL="ccu_docker"

#QEMU version (allows running build and CCU on x86)
ARG QEMU_VERSION="v3.0.0"

RUN export CCU_FW_LINK="http://update.homematic.com/firmware/download?cmd=download&version=${CCU_VERSION}&serial=${CCU_SERIAL}&lang=de&product=HM-CCU${CCU_VERSION%%.*}" \
    && echo "Downloading from $CCU_FW_LINK " \
    && wget --no-verbose $CCU_FW_LINK -O -|tar -xzO rootfs.ext4.gz|gunzip>rootfs.ext4

RUN folders=$(debugfs -R ls rootfs.ext4| sed -e 's/)/)\n/g' | egrep -i "[[:alpha:]]" | awk '{print $1}') \
    && mkdir extracted \
    && for f in $folders; do echo $f; debugfs -R "rdump /$f extracted/" rootfs.ext4; done

#Delete some rests (etc/config/shadow) from /usr/local so ssh works again
RUN rm -rf extracted/usr/local/*

ARG QEMU_TGZ=https://github.com/multiarch/qemu-user-static/releases/download/${QEMU_VERSION}/qemu-arm-static.tar.gz
RUN wget --no-verbose $QEMU_TGZ -O - |tar -xz -C extracted/usr/bin

#If the branch is not available we take the latest
RUN git clone --depth 1 --single-branch --branch ${CCU_VERSION} https://github.com/jens-maus/occu.git \
    || git clone --depth 1 --single-branch https://github.com/jens-maus/occu.git

RUN \
    # Need firmware for other adapters such as HmIP USB
    cp -avu /occu/firmware/* extracted/firmware \
    # Need legacy HMServer for the case no HmIP is plugged
    && mkdir -p extracted/opt/HMServer \
    && cp -avu /occu/HMserver/opt/HMServer/HMServer.jar extracted/opt/HMServer/

# This is in order to generate patches with `diff original/etc current/etc
RUN ln -s / extracted/current \
    && mkdir -p extracted/original \
    && cp -a extracted/etc extracted/original/

COPY additions /additions

RUN cp -av --remove-destination /additions/files/* /extracted/

RUN cd extracted/ \
    && cat /additions/patches/*|patch -p1


FROM scratch
COPY --from=builder extracted /
COPY LICENSE entrypoint.sh /

CMD ["/entrypoint.sh"]
VOLUME /usr/local
EXPOSE 80 22 2001 8181
