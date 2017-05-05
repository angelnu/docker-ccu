FROM scratch
ADD ubi.tgz /
ADD /LICENSE /

#Circumvention to avoid that rfd is updated
RUN sed -i -e 's/^Improved/#Improved/g'      /etc/config_templates/rfd.conf && \
    sed -i -e 's/^#AccessFile/ AccessFile/g' /etc/config_templates/rfd.conf && \
    sed -i -e 's/^#ResetFile/ ResetFile/g'   /etc/config_templates/rfd.conf

ADD entrypoint.sh /
CMD ["/entrypoint.sh"]

EXPOSE 80
EXPOSE 2001
