FROM php:8.2-apache

# Install system deps + PHP extensions
RUN apt-get update && apt-get install -y \
    libpng-dev \
    libjpeg-dev \
    libwebp-dev \
    libfreetype6-dev \
    libonig-dev \
    unzip curl \
    && docker-php-ext-install mysqli mbstring gd zip

# Enable Apache modules
RUN a2enmod rewrite headers

# PHP config
RUN { \
    echo "file_uploads = On"; \
    echo "upload_max_filesize = 100M"; \
    echo "post_max_size = 100M"; \
    echo "memory_limit = 256M"; \
    } > /usr/local/etc/php/conf.d/io200.ini

# Download IO200
WORKDIR /var/www/html

RUN curl -L https://www.io200.com/download/latest.zip -o io200.zip \
    && unzip io200.zip \
    && rm io200.zip \
    && chown -R www-data:www-data /var/www/html

RUN chmod -R 755 /var/www/html