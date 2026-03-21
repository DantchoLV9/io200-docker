FROM php:8.2-apache

# 1. Install system deps + PHP extensions & clean up in one layer
RUN apt-get update && apt-get install -y \
    libpng-dev \
    libjpeg-dev \
    libwebp-dev \
    libfreetype6-dev \
    libonig-dev \
    libzip-dev \
    unzip curl \
    && docker-php-ext-install mysqli mbstring gd zip \
    && rm -rf /var/lib/apt/lists/*

# 2. Set up application directory
WORKDIR /var/www/html

# Download the installer and set strictly required permissions
# We set ownership to www-data so the web server can execute/write during install
RUN curl -L "https://www.service.io200.com/api/v1/download:installer" -o install.php \
    && chown www-data:www-data /var/www/html \
    && chown www-data:www-data install.php \
    && chmod 644 install.php

# 4. Apache & PHP Config
RUN a2enmod rewrite headers

RUN { \
    echo "file_uploads = On"; \
    echo "upload_max_filesize = 100M"; \
    echo "post_max_size = 100M"; \
    echo "memory_limit = 256M"; \
    } > /usr/local/etc/php/conf.d/io200.ini