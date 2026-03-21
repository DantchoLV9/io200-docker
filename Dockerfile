# --- Stage 1: Build ---
FROM php:8.2-apache AS builder

# Install build dependencies
RUN apt-get update && apt-get install -y \
    libpng-dev libjpeg-dev libwebp-dev libfreetype6-dev \
    libonig-dev libzip-dev unzip curl \
    && docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp \
    && docker-php-ext-install -j$(nproc) mysqli mbstring gd zip pdo_mysql

# --- Stage 2: Production ---
FROM php:8.2-apache

# Install ONLY runtime libraries (smaller, more secure)
RUN apt-get update && apt-get install -y \
    libpng16-16 libjpeg62-turbo libwebp7 libfreetype6 \
    libonig5 libzip4 curl unzip \
    && rm -rf /var/lib/apt/lists/*

# Copy compiled extensions from the builder stage
COPY --from=builder /usr/local/lib/php/extensions /usr/local/lib/php/extensions
COPY --from=builder /usr/local/etc/php/conf.d /usr/local/etc/php/conf.d

# Enable Apache modules
RUN a2enmod rewrite headers

# Use the official Production PHP config as a base
RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"

# Custom PHP settings
COPY <<EOF /usr/local/etc/php/conf.d/io200-limits.ini
file_uploads = On
upload_max_filesize = 100M
post_max_size = 100M
memory_limit = 256M
expose_php = Off
EOF

WORKDIR /var/www/html

# Download and secure the app
RUN curl -L https://io200.com -o io200.zip \
    && unzip -q io200.zip \
    && rm io200.zip \
    && chown -R www-data:www-data /var/www/html \
    && find /var/www/html -type d -exec chmod 755 {} \; \
    && find /var/www/html -type f -exec chmod 644 {} \;

# Run as a non-privileged user for security (Optional, depends on IO200 needs)
# USER www-data 