# ==============================================================================
# Production Dockerfile for Drupal 11.x
# ==============================================================================
# Multi-stage build:
#   1. deps    : Resolve Composer dependencies securely
#   2. runtime : Hardened PHP-Apache runtime with pre-built codebase
# ==============================================================================

# Global build arguments — injected by docker-compose from .env
ARG PHP_VERSION
ARG DEBIAN_VERSION

# -----------------------------------------------------------------------------
# Stage 1: Dependencies
# -----------------------------------------------------------------------------
FROM php:${PHP_VERSION}-cli-${DEBIAN_VERSION} AS deps

# Re-declare args inside stage so they are available for LABEL/RUN if needed
ARG PHP_VERSION
ARG DEBIAN_VERSION

ENV COMPOSER_HOME=/composer
ENV COMPOSER_ALLOW_SUPERUSER=1

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    git \
    unzip \
    zip \
    libzip-dev \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libpng-dev \
    libwebp-dev \
    && docker-php-ext-configure gd \
        --with-freetype=/usr \
        --with-jpeg=/usr \
        --with-webp=/usr \
    && docker-php-ext-install -j$(nproc) gd \
    && rm -rf /var/lib/apt/lists/*

COPY --from=composer:2 /usr/bin/composer /usr/local/bin/composer

WORKDIR /src

# Copy dependency definitions first to maximize layer caching
COPY composer.json composer.lock ./

# Install production dependencies with hardened, optimized autoloader
RUN composer install \
    --no-dev \
    --no-interaction \
    --no-progress \
    --no-scripts \
    --optimize-autoloader \
    --apcu-autoloader \
    --prefer-dist \
    --no-cache \
    && rm -rf ~/.composer/cache

# -----------------------------------------------------------------------------
# Stage 2: Runtime
# -----------------------------------------------------------------------------
FROM php:${PHP_VERSION}-apache-${DEBIAN_VERSION} AS runtime

# Re-declare args inside stage so they are available for LABEL/RUN if needed
ARG PHP_VERSION
ARG DEBIAN_VERSION

LABEL maintainer="ops@example.com"
LABEL org.opencontainers.image.title="Drupal Production"
LABEL org.opencontainers.image.description="Hardened Drupal 11.x runtime on PHP-Apache"

ARG UID=33
ARG GID=33

ENV APACHE_RUN_USER=www-data
ENV APACHE_RUN_GROUP=www-data
ENV APACHE_LOG_DIR=/var/log/apache2
ENV APACHE_LOCK_DIR=/var/lock/apache2
ENV APACHE_PID_FILE=/var/run/apache2.pid

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    # Core runtime libraries
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libpng-dev \
    libwebp-dev \
    libzip-dev \
    libonig-dev \
    libxml2-dev \
    libxslt1-dev \
    libcurl4-openssl-dev \
    libicu-dev \
    # Security & utilities
    ca-certificates \
    netcat-openbsd \
    # Apache modules
    && a2enmod rewrite headers deflate expires ssl remoteip \
    # PHP extensions required by Drupal 11 core + common contrib modules
    && docker-php-ext-configure gd \
        --with-freetype=/usr \
        --with-jpeg=/usr \
        --with-webp=/usr \
    && docker-php-ext-install -j$(nproc) \
        gd \
        pdo_mysql \
        mysqli \
        zip \
        intl \
        bcmath \
        xsl \
        soap \
        sockets \
        exif \
    # Clean up build-only dev packages; DO NOT auto-remove so runtime
    # libraries (libpng16-16, libxslt1.1, libzip4, etc.) stay behind.
    && apt-get purge -y \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libpng-dev \
        libwebp-dev \
        libzip-dev \
        libonig-dev \
        libxml2-dev \
        libxslt1-dev \
        libcurl4-openssl-dev \
        libicu-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Copy production PHP overrides
COPY config/php/production.ini $PHP_INI_DIR/conf.d/99-production.ini

# Copy Apache virtual host with security headers + file protections
COPY config/apache/drupal.conf /etc/apache2/sites-available/000-default.conf
RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf

# Application directory
WORKDIR /var/www/html

# Copy codebase
COPY --chown=www-data:www-data . .
COPY --from=deps --chown=www-data:www-data /src/vendor ./vendor

# Entrypoint for pre-flight checks
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Ensure correct ownership and stripped permissions
RUN mkdir -p web/sites/default/files \
    web/sites/default/private \
    config/sync \
    && chown -R www-data:www-data web/sites/default/files \
    && chown -R www-data:www-data web/sites/default/private \
    && chmod 755 web/sites/default \
    && chmod 775 web/sites/default/files \
    && chmod 750 web/sites/default/private \
    && chmod -R go-w web/core web/modules web/profiles web/themes \
    && find web -type f -exec chmod go-w {} + \
    && find web -type d -exec chmod go-w {} +

# Healthcheck: Drupal bootstrap probe
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f -s -o /dev/null http://localhost:80/core/install.php || curl -f -s -o /dev/null http://localhost:80/index.php || exit 1

EXPOSE 80

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["apache2-foreground"]
