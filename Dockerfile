# PHP with Apache

FROM php:8.3-apache

# Enable Apache mod_rewrite for clean URLs
RUN a2enmod rewrite headers

# Install common PHP extensions
# Each extension has its own system dependencies
RUN apt-get update && apt-get install -y \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libzip-dev \
    libicu-dev \
    libpq-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) \
    gd \
    zip \
    intl \
    pdo \
    pdo_mysql \
    pdo_pgsql \
    opcache \
    && rm -rf /var/lib/apt/lists/*

# Configure PHP for production
COPY php-production.ini /usr/local/etc/php/conf.d/production.ini

# Configure Apache virtual host
COPY apache-vhost.conf /etc/apache2/sites-available/000-default.conf

# Copy application code
COPY . /var/www/html/

# Set proper ownership
RUN chown -R www-data:www-data /var/www/html

EXPOSE 80

HEALTHCHECK --interval=15s --timeout=5s --retries=3 \
    CMD curl -f http://localhost/health.php || exit 1