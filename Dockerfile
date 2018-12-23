FROM python as builder

#CCU firmware version to download
ARG CCU_VERSION="2.35.16"

#CCU Serial Number
ARG CCU_SERIAL="ccu_docker"

#QEMU version (allows running build and CCU on x86)
ARG QEMU_VERSION="v3.0.0"

#URL used by the CCU to download the firmware
ARG CCU_FW_LINK="http://update.homematic.com/firmware/download?cmd=download&version=${CCU_VERSION}&serial=${CCU_SERIAL}&lang=de&product=HM-CCU2"

RUN echo "Downloading from $CCU_FW_LINK " \
    && wget $CCU_FW_LINK -O -|tar -xz rootfs.ubi

RUN apt update \
  && apt install -y gcc liblzo2-dev openssl

#https://github.com/jrspruitt/ubi_reader
RUN pip install ubi_reader python-lzo

RUN ubireader_extract_files -k rootfs.ubi -o ubi

#Circumvention to avoid that rfd is updated
RUN sed -i -e 's/^Improved/#Improved/g'      ubi/*/root/etc/config_templates/rfd.conf && \
    sed -i -e 's/^#AccessFile/ AccessFile/g' ubi/*/root/etc/config_templates/rfd.conf && \
    sed -i -e 's/^#ResetFile/ ResetFile/g'   ubi/*/root/etc/config_templates/rfd.conf && \
    #Reduce the timeout to wait for HMIPServer
    sed -i -e 's/600/5/g'   ubi/*/root/etc/init.d/S62HMServer

ARG QEMU_TGZ=https://github.com/multiarch/qemu-user-static/releases/download/${QEMU_VERSION}/qemu-arm-static.tar.gz
RUN wget $QEMU_TGZ -O - |tar -xz -C ubi/*/root/usr/bin

FROM scratch
COPY --from=builder ubi/*/root /
COPY LICENSE entrypoint.sh /

CMD ["/entrypoint.sh"]
VOLUME /usr/local
EXPOSE 80 2001 8181
