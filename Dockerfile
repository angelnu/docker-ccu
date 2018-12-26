FROM python as builder

#CCU2 firmware version to download
ARG CCU2_VERSION="2.41.5"

#CCU2 Serial Number
ARG CCU2_SERIAL="ccu2_docker"

#URL used by CCU2 to download firmware
ARG CCU2_FW_LINK="http://update.homematic.com/firmware/download?cmd=download&version=${CCU2_VERSION}&serial=${CCU2_SERIAL}&lang=de&product=HM-CCU2"

RUN echo "Downloading from $CCU2_FW_LINK " \
    && wget $CCU2_FW_LINK -O -|tar -xz rootfs.ubi

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

ARG QEMU_TGZ=https://github.com/multiarch/qemu-user-static/releases/download/v3.0.0/qemu-arm-static.tar.gz
RUN wget $QEMU_TGZ -O - |tar -xz -C ubi/*/root/usr/bin

FROM scratch
COPY --from=builder ubi/*/root /
COPY LICENSE entrypoint.sh /

CMD ["/entrypoint.sh"]
VOLUME /usr/local
EXPOSE 80 2001 8181
