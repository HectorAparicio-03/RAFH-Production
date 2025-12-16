FROM php:8.3-fpm

# 1. Instalar dependencias del sistema y de PHP
RUN apt-get update && apt-get install -y \
    nginx \
    git \
    unzip \
    libpq-dev \
    libzip-dev \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install pdo pdo_pgsql zip gd bcmath pcntl

# 2. Instalar Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# 3. Establecer directorio de trabajo
WORKDIR /var/www/html

# 4. Copiar los archivos del proyecto
COPY . .

# 5. Instalar dependencias de Laravel
RUN composer install --no-dev --no-scripts --optimize-autoloader

# 6. Ajustar permisos de propietario
RUN chown -R www-data:www-data /var/www/html

# 7. Configuración de NGINX
RUN rm -f /etc/nginx/sites-enabled/default
COPY nginx.conf /etc/nginx/sites-available/app.conf
RUN ln -s /etc/nginx/sites-available/app.conf /etc/nginx/sites-enabled/app.conf

# 8. Permisos específicos para carpetas de escritura de Laravel
RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache
RUN chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache

# 9. Limpieza de caché preventiva (Mata-zombies)
RUN rm -rf bootstrap/cache/*.php

# 10. Comando de arranque simple
CMD php-fpm & nginx -g 'daemon off;'