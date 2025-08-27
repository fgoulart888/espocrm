# --- Dockerfile MAIS SIMPLES e CORRETO para Railway ---
# Usa a imagem oficial do EspoCRM já pronta (Apache + PHP)
FROM espocrm/espocrm:8.3.0-apache

# Ativa o mod_rewrite e configura o VirtualHost como a doc do Espo pede:
# - DocumentRoot em /public
# - Alias para /client
# - AllowOverride All (habilita .htaccess)
RUN a2enmod rewrite && \
  bash -lc 'cat >/etc/apache2/sites-available/000-default.conf << "EOF"
<VirtualHost *:80>
  ServerAdmin webmaster@localhost

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
EOF'
