FROM php:7.4.6-fpm
MAINTAINER waterchestnut "lingbinmeng@hotmail.com"

COPY php.ini /usr/local/etc/php/php.ini

# install librdkafka(rdkafka的依赖项)
RUN set -ex; \
    apt-get update; \
    apt-get install -y --no-install-recommends librdkafka-dev

# install the PHP extensions
RUN set -ex; \
	\
	savedAptMark="$(apt-mark showmanual)"; \
	\
	apt-get update; \
	apt-get install -y --no-install-recommends \
		libfreetype6-dev \
		libjpeg62-turbo-dev \
		libpng-dev \
		libzip-dev \
		zip \
	; \
	\
	# 7.4: --with-png-dir has been removed. libpng is required.--with-freetype-dir becomes --with-freetype.--with-jpeg-dir becomes --with-jpeg.
	docker-php-ext-configure gd --with-freetype=/usr/include/ --with-jpeg=/usr/include/ ; \
	docker-php-ext-install gd mysqli pdo_mysql opcache zip; \
	pecl install redis; \
	docker-php-ext-enable redis; \
	pecl install rdkafka; \
	docker-php-ext-enable rdkafka; \
	\
    # reset apt-mark's "manual" list so that "purge --auto-remove" will remove all build dependencies
	apt-mark auto '.*' > /dev/null; \
	apt-mark manual $savedAptMark; \
	ldd "$(php -r 'echo ini_get("extension_dir");')"/*.so \
		| awk '/=>/ { print $3 }' \
		| sort -u \
		| xargs -r dpkg-query -S \
		| cut -d: -f1 \
		| sort -u \
		| xargs -rt apt-mark manual; \
	\
	apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
	rm -rf /var/lib/apt/lists/*

VOLUME /wwwroot

EXPOSE 9000
CMD ["php-fpm"]