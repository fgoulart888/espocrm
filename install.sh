#!/bin/bash

# Copiar arquivos para o diretório web
cp -r /app/. /var/www/html/

# Configurar permissões
chown -R www-data:www-data /var/www/html/
chmod -R 755 /var/www/html/

# Configurar Apache
a2enmod rewrite
a2enmod ssl
echo 'ServerName localhost' >> /etc/apache2/apache2.conf

# Iniciar Apache
apache2-foreground
