FROM alpine:3.18
LABEL Maintainer="Mathieu LESNIAK <mathieu@lesniak.fr>"\
    Description="Lightweight container with Nginx 1.24 & PHP-FPM 8.2 based on Alpine Linux. Full locales enabled"

ENV MUSL_LOCPATH="/usr/share/i18n/locales/musl"

RUN apk update && \
    apk add bash less geoip nginx nginx-mod-http-headers-more nginx-mod-http-geoip nginx-mod-stream nginx-mod-stream-geoip ca-certificates git tzdata zip \
    zlib-dev gmp-dev freetype-dev libjpeg-turbo-dev libpng-dev curl icu-data-full \
    php82-common php82-fpm php82-json php82-zlib php82-xml php82-xmlwriter php82-pdo php82-phar php82-openssl php82-fileinfo php82-pecl-imagick \
    php82-pdo_mysql php82-mysqli php82-sqlite3 php82-pdo_sqlite php82-session \
    php82-gd php82-iconv php82-gmp php82-zip \
    php82-curl php82-opcache php82-ctype php82-pecl-apcu php82-pecl-memcached php82-pecl-redis php82-pecl-yaml php82-exif \
    php82-intl php82-bcmath php82-dom php82-mbstring php82-simplexml php82-soap php82-tokenizer php82-xmlreader php82-xmlwriter php82-posix php82-pcntl php82-ftp && \
    apk add -u musl && \
    apk add msmtp && \
    apk add musl-locales musl-locales-lang && cd "$MUSL_LOCPATH" \
    && for i in *.UTF-8; do cp -a "$i" "${i%%.UTF-8}"; done && \
    mkdir /etc/nginx/server-override && \
    rm -rf /var/cache/apk/*

RUN { \
    echo '[mail function]'; \
    echo 'sendmail_path = "/usr/bin/msmtp -t"'; \
    } > /etc/php82/conf.d/msmtp.ini

# opcode recommended settings
RUN { \
    echo 'opcache.memory_consumption=256'; \
    echo 'opcache.interned_strings_buffer=64'; \
    echo 'opcache.max_accelerated_files=25000'; \
    echo 'opcache.revalidate_path=0'; \
    echo 'opcache.enable_file_override=1'; \
    echo 'opcache.max_file_size=0'; \
    echo 'opcache.max_wasted_percentage=5;' \
    echo 'opcache.revalidate_freq=120'; \
    echo 'opcache.fast_shutdown=1'; \
    echo 'opcache.enable_cli=0'; \ 
    echo 'opcache.jit_buffer_size=64M'; \
    echo 'opcache.jit=tracing';\ 
    } > /etc/php82/conf.d/opcache-recommended.ini

# limits settings
RUN { \
    echo 'memory_limit=256M'; \
    echo 'upload_max_filesize=128M'; \
    echo 'max_input_vars=5000'; \
    echo "date.timezone='Europe/Paris'"; \
    } > /etc/php82/conf.d/limits.ini

RUN sed -i "s/nginx:x:100:101:nginx:\/var\/lib\/nginx:\/sbin\/nologin/nginx:x:100:101:nginx:\/usr:\/bin\/bash/g" /etc/passwd && \
    sed -i "s/nginx:x:100:101:nginx:\/var\/lib\/nginx:\/sbin\/nologin/nginx:x:100:101:nginx:\/usr:\/bin\/bash/g" /etc/passwd- && \
    ln -s /usr/sbin/php-fpm8 /sbin/php-fpm && \
    ln -s /usr/bin/php82 /usr/bin/php

# Composer
RUN cd /tmp/ && \
    curl -sS https://getcomposer.org/installer | php && \
    mv composer.phar /usr/local/bin/composer && \
    composer self-update

ADD php-fpm.conf /etc/php82/
ADD nginx-site.conf /etc/nginx/nginx.conf

ADD entrypoint.sh /etc/entrypoint.sh
ADD ownership.sh /
RUN mkdir -p /var/www/public
COPY --chown=nobody src/ /var/www/public/


WORKDIR /var/www/
EXPOSE 80

# Configure a healthcheck to validate that everything is up&running
HEALTHCHECK --timeout=10s CMD curl --silent --fail http://127.0.0.1:80/fpm-ping

ENTRYPOINT ["sh", "/etc/entrypoint.sh"]

