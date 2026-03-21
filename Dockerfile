# --- Stage 1: Build (Compile Extensions) ---
FROM php:8.2-apache AS builder

# Install build-essential tools and -dev headers
RUN apt-get update && apt-get install -y --no-install-recommends \
    libpng-dev libjpeg-dev libwebp-dev libfreetype6-dev \
    libonig-dev libzip-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp \
    && docker-php-ext-install -j$(nproc) mysqli pdo_mysql mbstring gd zip

# --- Stage 2: Production (The Actual Image) ---
FROM php:8.2-apache

# Install only the runtime libraries (Security Best Practice)
RUN apt-get update && apt-get install -y --no-install-recommends \
    libpng16-16 libjpeg62-turbo libwebp7 libfreetype6 \
    libonig5 libzip4 curl \
    && rm -rf /var/lib/apt/lists/*

# Copy compiled extensions from builder
COPY --from=builder /usr/local/lib/php/extensions /usr/local/lib/php/extensions
COPY --from=builder /usr/local/etc/php/conf.d /usr/local/etc/php/conf.d

# Enable Apache modules for clean URLs
RUN a2enmod rewrite headers

# Security: Use production PHP settings and hide PHP version
RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini" \
    && sed -i 's/expose_php = On/expose_php = Off/' "$PHP_INI_DIR/php.ini"

# Custom PHP limits for IO200
RUN { \
    echo "file_uploads = On"; \
    echo "upload_max_filesize = 100M"; \
    echo "post_max_size = 100M"; \
    echo "memory_limit = 256M"; \
    } > /usr/local/etc/php/conf.d/io200-limits.ini

WORKDIR /var/www/html

# Download the installer and set strictly required permissions
# We set ownership to www-data so the web server can execute/write during install
RUN curl -L "https://www.service.io200.com/api/v1/download:installer" -o install.php \
    && chown www-data:www-data /var/www/html \
    && chown www-data:www-data install.php \
    && chmod 644 install.php

# Standard Apache entrypoint is inherited from the base image