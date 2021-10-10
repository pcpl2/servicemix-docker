FROM adoptopenjdk:8u292-b10-jre-hotspot-focal

RUN apt-get update && apt-get upgrade -y && apt-get install -y unzip && apt-get autoremove -y

RUN groupadd --gid=1000 -r servicemix && \
    useradd -r -g servicemix --uid=1000 -m servicemix


ARG SERVICEMIX_SHA=4854243f6b1aaf3c9ff7c08183c769ab6878b285


RUN curl -fsSL https://dlcdn.apache.org/servicemix/servicemix-7/7.0.1/apache-servicemix-7.0.1.zip -o /tmp/apache-servicemix-7.0.1.zip \
  && echo "${SERVICEMIX_SHA} /tmp/apache-servicemix-7.0.1.zip" | sha1sum -c -

RUN cd /opt && \
    unzip /tmp/apache-servicemix-7.0.1.zip && \
    chown -R servicemix:servicemix apache-servicemix-7.0.1 && \
    ln -s apache-servicemix-7.0.1 servicemix && \
    mkdir -m 0750 /var/opt/servicemix && \
    mkdir -m 0750 /var/opt/servicemix/data && \
    mkdir -m 0770 /var/opt/servicemix/deploy && \
    mkdir -m 0750 /var/opt/servicemix/local && \
    mv servicemix/etc /var/opt/servicemix/ && \
    sed -i.orig \
        -e 's/\(karaf\.shutdown\.port\.file\)\s*=\s*.*\/\(.*\)/\1 = \/var\/opt\/servicemix\/\2/' \
        -e 's/\(karaf\.pid\.file\)\s*=\s*.*\/\(.*\)/\1 = \/var\/opt\/servicemix\/\2/' \
        /var/opt/servicemix/etc/config.properties && \
    sed -i.orig \
        's/\(felix\.fileinstall\.dir\)\s*=.*/\1 = \/var\/opt\/servicemix\/deploy/' \
        /var/opt/servicemix/etc/org.apache.felix.fileinstall-deploy.cfg && \
    sed -i.orig \
        '/# karaf.lock.dir=/a karaf.lock.dir = \/var\/opt\/servicemix' \
        /var/opt/servicemix/etc/system.properties && \
    chmod 0440 /var/opt/servicemix/etc/*.orig && \
    chown -R servicemix:servicemix /var/opt/servicemix && \
    rm -f /tmp/*.*

COPY --chown=servicemix:servicemix servicemix-entrypoint.sh /
RUN chmod +x servicemix-entrypoint.sh

ENV PS1="[\u@\h:\w]\n\$ " \
    KARAF_HOME="/opt/servicemix" \
    KARAF_DATA="/var/opt/servicemix/data" \
    KARAF_ETC="/var/opt/servicemix/etc" \
    KARAF_NOROOT="true" \
    KARAF_OPTS="-Dkaraf.instances=/var/opt/servicemix/instances" \
    MAVEN_REPO="/var/opt/servicemix/local"


VOLUME /var/opt/servicemix

# 8181 = OSGi HTTP service
# 8101 = Karaf shell (SSH)
# 44444 = Karaf RMI server
# 1099 = Karaf RMI registry
# 61616 = embedded ActiveMQ connector
EXPOSE 8181 8101 44444 1099 61616

USER servicemix
WORKDIR /var/opt/servicemix
CMD ["/servicemix-entrypoint.sh"]
