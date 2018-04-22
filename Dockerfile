FROM scratch
ADD ubi.tgz /
ADD /LICENSE /

#Circumvention to avoid that rfd is updated
#symlink needed by cuxd plugging - https://github.com/angelnu/docker-ccu2/issues/18
RUN sed -i -e 's/^Improved/#Improved/g'      /etc/config_templates/rfd.conf && \
    sed -i -e 's/^#AccessFile/ AccessFile/g' /etc/config_templates/rfd.conf && \
    sed -i -e 's/^#ResetFile/ ResetFile/g'   /etc/config_templates/rfd.conf && \
    ln -s /lib/ld-linux.so.3 /lib/ld-linux-armhf.so.3

ADD entrypoint.sh /
CMD ["/entrypoint.sh"]

EXPOSE 80
EXPOSE 2001
