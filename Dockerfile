FROM scratch
ADD ubi.tgz /

#Use GPIO
RUN sed -i -e 's/mmd_bidcos/ttyAMA0/g' /etc/config_templates/rfd.conf && \ 
    sed -i -e 's/\/dev\/ccu2-ic200/\/sys\/class\/gpio\/gpio18\/value/g' /etc/config_templates/rfd.conf
#Circumvention to avoid that rfd is updated
RUN sed -i -e 's/^Improved/#Improved/g'      /etc/config_templates/rfd.conf && \
    sed -i -e 's/^#AccessFile/ AccessFile/g' /etc/config_templates/rfd.conf && \
    sed -i -e 's/^#ResetFile/ ResetFile/g'   /etc/config_templates/rfd.conf

ADD entrypoint.sh /
CMD ["/entrypoint.sh"]

EXPOSE 80
EXPOSE 2001
