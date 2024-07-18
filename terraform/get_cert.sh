#!/bin/bash

# Параметры с дефолтными значениями
DOMAIN=${1:-letest.pam4.com}
EMAIL=${2:-CertAlert@pam4.com}
DISABLE_NGINX=${3:-false}

# Обновление системы и установка необходимых пакетов
sudo yum update -y

# Установка Nginx через Amazon Linux Extras
sudo amazon-linux-extras install -y nginx1

# Запуск и включение Nginx
sudo systemctl start nginx
sudo systemctl enable nginx

# Создание конфигурационного файла для Nginx
sudo bash -c "cat > /etc/nginx/conf.d/$DOMAIN.conf <<EOF
server {
    listen 80;
    server_name $DOMAIN;

    location / {
        root /usr/share/nginx/html;
        index index.html index.htm;
    }

    location /.well-known/acme-challenge/ {
        root /usr/share/nginx/html;
        allow all;
    }
}

server {
    listen 443 ssl;
    server_name $DOMAIN;

    ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;

    location / {
        root /usr/share/nginx/html;
        index index.html index.htm;
    }
}
EOF"

# Перезагрузка Nginx
sudo nginx -t && sudo systemctl reload nginx

# Установка epel-release через Amazon Linux Extras
sudo amazon-linux-extras install -y epel

# Установка Certbot
sudo yum install -y certbot

# Создание директории для webroot метода и добавление HTML файла
sudo mkdir -p /usr/share/nginx/html/.well-known/acme-challenge
sudo chown -R $USER:$USER /usr/share/nginx/html/.well-known
echo "Hello World" | sudo tee /usr/share/nginx/html/index.html

# Получение сертификата с помощью Certbot
sudo certbot certonly --webroot -w /usr/share/nginx/html -d $DOMAIN --non-interactive --agree-tos -m $EMAIL

# Перезагрузка Nginx для активации SSL сертификата
sudo nginx -t && sudo systemctl reload nginx

# Отключение Nginx, если DISABLE_NGINX установлено в true
if [ "$DISABLE_NGINX" = true ]; then
    sudo systemctl stop nginx
    sudo systemctl disable nginx
fi

# Создание копий сертификатов с расширением .crt
sudo cp /etc/letsencrypt/live/$DOMAIN/fullchain.pem /etc/letsencrypt/live/$DOMAIN/fullchain.crt
sudo cp /etc/letsencrypt/live/$DOMAIN/cert.pem /etc/letsencrypt/live/$DOMAIN/cert.crt

# Копирование новых сертификатов в каталог smsgate/cert
sudo mkdir -p ./smsgate/cert
sudo cp /etc/letsencrypt/live/$DOMAIN/fullchain.pem ./smsgate/cert/public.crt
sudo cp /etc/letsencrypt/live/$DOMAIN/privkey.pem ./smsgate/cert/private.key
sudo cp /etc/letsencrypt/live/$DOMAIN/chain.pem ./smsgate/cert/ca.crt

# Вывод информации о сертификате
echo "Информация о сертификате:"
sudo openssl x509 -in /etc/letsencrypt/live/$DOMAIN/fullchain.pem -noout -subject | grep 'CN'
sudo openssl x509 -in /etc/letsencrypt/live/$DOMAIN/fullchain.pem -noout -text | grep -A 1 'Subject Alternative Name'
sudo openssl x509 -in /etc/letsencrypt/live/$DOMAIN/fullchain.pem -noout -dates
