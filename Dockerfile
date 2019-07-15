FROM alpine:3.10 as base

# set this with shell variables at build-time.
# If they aren't set, then not-set will be default.
ARG CREATED_DATE=not-set
ARG SOURCE_COMMIT=not-set

# Environments
ENV USER_HOME /var/www
ENV TIMEZONE  Europe/Paris
## copied from original Composer install
ENV COMPOSER_ALLOW_SUPERUSER 1
ENV COMPOSER_HOME /tmp
ENV COMPOSER_VERSION 1.8.6

# labels from https://github.com/opencontainers/image-spec/blob/master/annotations.md
LABEL org.opencontainers.image.authors=blackmorth@gmail.com
LABEL org.opencontainers.image.created=$CREATED_DATE
LABEL org.opencontainers.image.revision=$SOURCE_COMMIT
LABEL org.opencontainers.image.title="Satisfy and Satis as services"
LABEL org.opencontainers.image.url=https://hub.docker.com/r/blackmorth/docker-satis
LABEL org.opencontainers.image.source=https://github.com/quentin-boulard/docker-satis
LABEL org.opencontainers.image.licenses=MIT

RUN apk add --upgrade ca-certificates \
    nginx \
    python3 \
    openssl \
    openssh-client \
    wget \
    git \
    curl \
    unzip \
    libmcrypt-dev \
    php7 \
    php7-json \
    php7-dom \
    php7-simplexml \
    php7-tokenizer \
    php7-tidy \
    php7-cli \
    php7-common \
    php7-curl \
    php7-intl \
    php7-fpm \
    php7-zip \
    php7-apcu \
    php7-xml \
    php7-mbstring \
    php7-phar \
    php7-openssl \
    php7-xmlwriter \
    php7-iconv \
    sudo \
    && apk add tzdata \
    && cp /usr/share/zoneinfo/${TIMEZONE} /etc/localtime \
    && echo "${TIMEZONE}" > /etc/timezone \
    && apk del tzdata \
    && rm -rf /var/cache/apk/*

RUN sed -i "s/;date.timezone =.*/date.timezone = Europe\/Paris/" /etc/php7/php.ini \
	&& echo "daemon off;" >> /etc/nginx/nginx.conf \
	&& sed -i -e "s/;daemonize\s*=\s*yes/daemonize = no/g" /etc/php7/php-fpm.conf \
	&& sed -i "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" /etc/php7/php.ini

# Install Site
COPY nginx/default   /etc/nginx/sites-available/default

# Install ssh key
RUN mkdir -p $USER_HOME/.ssh/ && touch $USER_HOME/.ssh/known_hosts


RUN pip3 install --upgrade pip && pip3 install supervisor

COPY supervisor/supervisord.conf /etc/supervisord.conf
COPY supervisor/0-install.conf /etc/supervisor/conf.d/0-install.conf
COPY supervisor/1-cron.conf /etc/supervisor/conf.d/1-cron.conf
COPY supervisor/2-nginx.conf /etc/supervisor/conf.d/2-nginx.conf
COPY supervisor/3-php.conf /etc/supervisor/conf.d/3-php.conf

# Install Composer

RUN curl --silent --fail --location --retry 3 --output /tmp/installer.php --url https://raw.githubusercontent.com/composer/getcomposer.org/cb19f2aa3aeaa2006c0cd69a7ef011eb31463067/web/installer \
    && php -r " \
    \$signature = '48e3236262b34d30969dca3c37281b3b4bbe3221bda826ac6a9a62d6444cdb0dcd0615698a5cbe587c3f0fe57a54d8f5'; \
    \$hash = hash('sha384', file_get_contents('/tmp/installer.php')); \
    if (!hash_equals(\$signature, \$hash)) { \
      unlink('/tmp/installer.php'); \
      echo 'Integrity check failed, installer is either corrupt or worse.' . PHP_EOL; \
      exit(1); \
    }" \
    && php /tmp/installer.php --no-ansi --install-dir=/usr/bin --filename=composer --version=${COMPOSER_VERSION} \
    && composer --ansi --version --no-interaction \
    && rm -f /tmp/installer.php \
    && find /tmp -type d -exec chmod -v 1777 {} +

RUN composer global require hirak/prestissimo

# Install satisfy
RUN git clone https://github.com/ludofleury/satisfy.git

RUN cd /satisfy \
    && composer install --no-suggest --no-interaction \
    && chmod -R 777 /satisfy

COPY scripts /app/scripts

COPY scripts/crontab /etc/cron.d/satis-cron
COPY config/ /satisfy/config

RUN chmod 0644 /etc/cron.d/satis-cron \
	&& touch /var/log/satis-cron.log \
	&& chmod +x /app/scripts/startup.sh


WORKDIR /app

EXPOSE 80 443

STOPSIGNAL SIGTERM

CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisord.conf"]

