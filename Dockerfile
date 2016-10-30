FROM scratch
ADD ubi.tgz /
RUN sed -i -e 's/mmd_bidcos/ttyAMA0/g' /etc/config_templates/rfd.conf
ADD entrypoint.sh /
CMD ["/entrypoint.sh"]
EXPOSE 80
EXPOSE 2001
