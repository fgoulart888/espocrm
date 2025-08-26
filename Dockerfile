# --- Dockerfile (EspoCRM no Apache + PHP 8.2) ---
FROM php:8.2-apache

# Pacotes e extensões PHP necessárias
RUN apt-get update && apt-get install -y \
    unzip git libpng-dev libjpeg-dev libfreetype6-dev libzip-dev libicu-dev cron \
 && docker-php-ext-configure gd --with-freetype --with-jpeg \
 && docker-php-ext-install gd intl zip pdo pdo_mysql mysqli \
 && a2enmod rewrite headers && rm -rf /var/lib/apt/lists/*

# Ajustes PHP (uploads e performance)
RUN { \
  echo "memory_limit=512M"; \
  echo "upload_max_filesize=64M"; \
  echo "post_max_size=64M"; \
  echo "max_execution_time=120"; \
} > /usr/local/etc/php/conf.d/uploads.ini

WORKDIR /var/www/html

# Baixar release oficial do EspoCRM (estável)
ARG ESPO_VERSION=8.3.0
RUN curl -L -o espo.zip "https://github.com/espocrm/espocrm/releases/download/$ESPO_VERSION/EspoCRM-$ESPO_VERSION.zip" \
 && unzip espo.zip && rm espo.zip \
 && mv EspoCRM-$ESPO_VERSION/* . && rmdir EspoCRM-$ESPO_VERSION || true

# Pastas graváveis pelo app
RUN mkdir -p data custom extensions \
 && chown -R www-data:www-data /var/www/html

# Permitir .htaccess (rewrite)
RUN printf '<Directory /var/www/html>\n  AllowOverride All\n  Require all granted\n</Directory>\n' \
    > /etc/apache2/conf-available/espocrm.conf \
 && a2enconf espocrm

# Cron do EspoCRM (tarefas agendadas a cada minuto)
RUN echo "* * * * * www-data php /var/www/html/cron.php > /dev/null 2>&1" > /etc/cron.d/espocrm \
 && chmod 0644 /etc/cron.d/espocrm && crontab /etc/cron.d/espocrm

# Sobe cron e Apache
CMD service cron start && apache2-foreground
