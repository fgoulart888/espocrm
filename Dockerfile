# --- Dockerfile EspoCRM (PHP 8.2 + Apache + Cron) ---
FROM php:8.2-apache

# Pacotes e extensões necessários
RUN apt-get update && apt-get install -y --no-install-recommends \
    unzip curl ca-certificates findutils \
    libpng-dev libjpeg-dev libfreetype6-dev libzip-dev libicu-dev cron \
 && update-ca-certificates \
 && docker-php-ext-configure gd --with-freetype --with-jpeg \
 && docker-php-ext-install gd intl zip pdo pdo_mysql mysqli \
 && a2enmod rewrite headers \
 && rm -rf /var/lib/apt/lists/*

# Ajustes PHP
RUN { \
  echo "memory_limit=512M"; \
  echo "upload_max_filesize=64M"; \
  echo "post_max_size=64M"; \
  echo "max_execution_time=120"; \
} > /usr/local/etc/php/conf.d/uploads.ini

# Evitar warning de ServerName no Apache
RUN printf "ServerName localhost\n" > /etc/apache2/conf-available/servername.conf \
 && a2enconf servername

# Diretório da app
WORKDIR /var/www/html

# Baixar release oficial (ZIP) e extrair para o webroot
ARG ESPO_VERSION=8.3.0
RUN set -eux; \
  curl -L -o /tmp/espo.zip "https://github.com/espocrm/espocrm/releases/download/${ESPO_VERSION}/EspoCRM-${ESPO_VERSION}.zip"; \
  unzip -q /tmp/espo.zip -d /tmp; \
  espo_dir="$(find /tmp -maxdepth 1 -type d -name 'EspoCRM-*' | head -n1)"; \
  mv "${espo_dir}"/* /var/www/html/; \
  rm -rf /tmp/espo.zip "${espo_dir}"

# Pastas graváveis e permissões
RUN mkdir -p data custom extensions \
 && chown -R www-data:www-data /var/www/html

# Permitir .htaccess (rewrite)
RUN printf '<Directory /var/www/html>\n  AllowOverride All\n  Require all granted\n</Directory>\n' \
    > /etc/apache2/conf-available/espocrm.conf \
 && a2enconf espocrm

# Cron do Espo (a cada minuto)
RUN echo "* * * * * www-data php /var/www/html/cron.php > /dev/null 2>&1" > /etc/cron.d/espocrm \
 && chmod 0644 /etc/cron.d/espocrm && crontab /etc/cron.d/espocrm

# Healthcheck simples
HEALTHCHECK --interval=30s --timeout=5s --retries=5 CMD curl -fsS http://127.0.0.1/ >/dev/null || exit 1

# Iniciar cron + apache
CMD service cron start && apache2-foreground
