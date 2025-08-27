# --- EspoCRM no Railway (simples e correto) ---
FROM espocrm/espocrm:8.3.0-apache

# Ativa mod_rewrite e cria um vhost apontando para /public com alias /client
RUN a2enmod rewrite && \
    cat >/etc/apache2/sites-available/espocrm.conf <<'EOF'
<VirtualHost *:80>
  ServerName localhost

  DocumentRoot /var/www/html/public
  Alias /client/ /var/www/html/client/

  <Directory /var/www/html/public/>
    AllowOverride All
    Require all granted
  </Directory>

  <Directory /var/www/html/client/>
    Require all granted
  </Directory>

  ErrorLog ${APACHE_LOG_DIR}/error.log
  CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOF

# Habilita o novo site e desabilita o default
RUN a2dissite 000-default && a2ensite espocrm

FROM ubuntu:22.04

RUN apt-get update && \
    apt-get install -y apache2 php php-cli php-common php-json php-curl \
    php-mbstring php-gd php-mysql php-zip php-xml libapache2-mod-php && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN a2enmod rewrite && a2enmod ssl

WORKDIR /var/www/html

COPY . .

RUN chown -R www-data:www-data /var/www/html && \
    chmod -R 755 /var/www/html

EXPOSE 80

CMD ["apache2ctl", "-D", "FOREGROUND"]
