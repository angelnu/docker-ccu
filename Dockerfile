FROM scratch
ADD ubi.tgz /
ADD entrypoint.sh /
#ADD usr_local.tgz /usr/local
#VOLUME /usr/local
CMD ["/entrypoint.sh"]
EXPOSE 80
EXPOSE 2001
