#!/bin/bash

# Project directory
PROJECT_DIR="/root/projects/reverse-proxy"

# Change to project directory
cd $PROJECT_DIR

# Renew certificates
docker-compose run --rm certbot renew

# Reload nginx if certificates were renewed
if [ $? -eq 0 ]; then
    docker-compose exec nginx nginx -s reload
    echo "$(date): SSL certificates renewed successfully" >> /var/log/ssl-renewal.log
else
    echo "$(date): Error renewing SSL certificates" >> /var/log/ssl-renewal.log
fi