FROM alpine:3.12

# Ref: https://github.com/STJr/Kart-Public/releases
ARG SRB2KART_VERSION=1.6
ARG SRB2KART_USER=srb2kart
ENV SRB2KART_DIRECTORY=/usr/share/games/SRB2Kart
ENV SRB2KART_MODS_DIRECTORY=/home/${SRB2KART_USER}/.srb2kart/servermods
#Stupidly high as default value, assuming that people don't want a mod limit
ENV TOTAL_SERVER_MOD_QUOTA=128G

# Ref: https://aur.archlinux.org/cgit/aur.git/tree/PKGBUILD?h=srb2kart-data
RUN set -ex \
    && apk add --no-cache --virtual .build-deps curl \
    && mkdir -p /srb2kart-data \
    && curl -L -o /tmp/srb2kart-v${SRB2KART_VERSION//./}-Assets.zip https://github.com/STJr/Kart-Public/releases/download/v${SRB2KART_VERSION}/AssetsLinuxOnly.zip \
    && unzip -d /srb2kart-data /tmp/srb2kart-v${SRB2KART_VERSION//./}-Assets.zip \
    && find /srb2kart-data/mdls -type d -exec chmod 0755 {} \; \
    && mkdir -p /usr/share/games \
    && mv /srb2kart-data $SRB2KART_DIRECTORY \
    && apk del .build-deps

# Ref: https://aur.archlinux.org/cgit/aur.git/tree/PKGBUILD?h=srb2kart
RUN set -ex \
    && apk add --no-cache --virtual .build-deps \
        bash \
        curl-dev \
        curl-static \
        gcc \
        git \
        gzip \
        libc-dev \
        libpng-dev \
        libpng-static \
        make \
        nghttp2-static \
        openssl-libs-static \
        sdl2_mixer-dev \
        sdl2-dev \
        sdl2-static \
        upx \
        zlib-dev \
        zlib-static \
    && git clone --depth=1 -b v${SRB2KART_VERSION} https://github.com/STJr/Kart-Public.git /srb2kart \
    && (cd /srb2kart/src \
        && make -j$(nproc) LINUX64=1 NOHW=1 NOGME=1) \
    && cp /srb2kart/bin/Linux64/Release/lsdl2srb2kart /usr/bin/srb2kart \
    && apk del .build-deps \
    && rm -rf /srb2kart

RUN apk add --no-cache \
        coreutils \
        shadow \
        bash

# Add script that auto-loads mods from specific `servermods` folder, se SRB2KART_MODS_DIRECTORY
COPY ./start-srb2kart-server.sh /usr/bin/start-srb2kart-server.sh
RUN set -ex \
    && chmod a+x /usr/bin/start-srb2kart-server.sh

RUN mkdir -p /data

RUN apk add --no-cache \
        curl-dev \
        curl-static \
        libpng-dev \
        libpng-static \
        sdl2_mixer-dev \
        sdl2-dev \
        sdl2 \
        nginx \
        zip

# User setup
RUN adduser -D -u 10001 -g 10001 ${SRB2KART_USER} \
    && ln -s /data /home/${SRB2KART_USER}/.srb2kart \
    && chown -R ${SRB2KART_USER} /data


#TODO: Migrate direct download to separate download service..

# Direct download location definition
#COPY ./direct-download.conf /etc/nginx/conf.d/direct-download.conf
#RUN mkdir -p /var/www/html
#RUN chown -R root:www-data /etc/nginx/conf.d/direct-download.conf
#RUN ln -s /data/servermods /var/www/html/repo
#RUN chown -h ${SRB2KART_USER} /var/www/html/repo

# Disable nginx user and set up for use as non-root user
#RUN mkdir -p /var/cache/nginx && chown -R ${SRB2KART_USER} /var/cache/nginx && \
#    mkdir -p /var/log/nginx && chown -R ${SRB2KART_USER} /var/log/nginx && \
#    mkdir -p /var/lib/nginx && chown -R ${SRB2KART_USER} /var/lib/nginx && \
#    mkdir -p /run/nginx && touch /run/nginx/nginx.pid && chown -R ${SRB2KART_USER} /run/nginx/nginx.pid && \
#    chown -R ${SRB2KART_USER} /etc/nginx && \
#    chmod -R 777 /etc/nginx/conf.d

#RUN sed -i 's/user nginx;/#user nginx;/g' /etc/nginx/nginx.conf

# Don't forget to remove the default
#RUN rm /etc/nginx/conf.d/default.conf

# User context switch
USER ${SRB2KART_USER}
RUN mkdir -p ${SRB2KART_MODS_DIRECTORY}
WORKDIR ${SRB2KART_DIRECTORY}

# Port definition
EXPOSE 5029/udp

STOPSIGNAL SIGINT
ENTRYPOINT ["start-srb2kart-server.sh"]
CMD ["-dedicated"]
