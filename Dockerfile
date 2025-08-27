# --- Dockerfile EspoCRM (PHP 8.2 + Apache + Cron) ---
FROM php:8.2-apache

# Instalar pacotes e extensões necessárias
# Inclui: tar e ca-certificates (evita erro ao baixar .tar.gz via HTTPS)
RUN apt-get update && apt-get install -y --no-install-recommends \
    unzip curl ca-certificates tar \
    libpng-dev libjpeg-dev libfreetype6-dev libzip-dev libicu-dev cron \
 && update-ca-certificates \
 && docker-php-ext-configure gd --with-freetype --with-jpeg \
 && docker-php-ext-install gd intl zip pdo pdo_mysql mysqli \
 && a2enmod rewrite headers \
 && rm -rf /var/lib/apt/lists/*

# Configurações PHP
RUN { \
  echo "memory_limit=512M"; \
  echo "upload_max_filesize=64M"; \
  echo "post_max_size=64M"; \
  echo "max_execution_time=120"; \
} > /usr/local/etc/php/conf.d/uploads.ini

# Definir diretório de trabalho
WORKDIR /var/www/html

# Baixar release oficial do EspoCRM e extrair direto na raiz
ARG ESPO_VERSION=8.3.0
RUN curl -L -o espo.tar.gz "https://github.com/espocrm/espocrm/releases/download/${ESPO_VERSION}/EspoCRM-${ESPO_VERSION}.tar.gz" \
 && tar -xzf espo.tar.gz --strip-components=1 -C /var/www/html \
 && rm espo.tar.gz

# Criar pastas graváveis
RUN mkdir -p data custom extensions \
 && chown -R www-data:www-data /var/www/html

# Permitir uso de .htaccess (rewrite)
RUN printf '<Directory /var/www/html>\n  AllowOverride All\n  Require all granted\n</Directory>\n' \
    > /etc/apache2/conf-available/espocrm.conf \
 && a2enconf espocrm

# Cron do EspoCRM (tarefas a cada minuto)
RUN echo "* * * * * www-data php /var/www/html/cron.php > /dev/null 2>&1" > /etc/cron.d/espocrm \
 && chmod 0644 /etc/cron.d/espocrm && crontab /etc/cron.d/espocrm

# Iniciar cron + apache
CMD service cron start && apache2-foreground
