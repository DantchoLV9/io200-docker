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

# 3. Download and extract (combined to save space)
RUN curl -L https://www.io200.com/download/latest.zip -o io200.zip \
    && unzip io200.zip \
    && rm io200.zip \
    && chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html

# 4. Apache & PHP Config
RUN a2enmod rewrite headers

RUN { \
    echo "file_uploads = On"; \
    echo "upload_max_filesize = 100M"; \
    echo "post_max_size = 100M"; \
    echo "memory_limit = 256M"; \
    } > /usr/local/etc/php/conf.d/io200.ini