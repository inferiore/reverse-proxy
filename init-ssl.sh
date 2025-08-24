#!/bin/bash

echo "🔐 Setting up SSL with Let's Encrypt..."

# Stop nginx temporarily
docker-compose down

# Create temporary certificates to avoid nginx errors
mkdir -p letsencrypt/live/survey.ederbarrios.online
mkdir -p letsencrypt/live/library.ederbarrios.online

openssl req -x509 -nodes -days 1 -newkey rsa:2048 \
    -keyout letsencrypt/live/survey.ederbarrios.online/privkey.pem \
    -out letsencrypt/live/survey.ederbarrios.online/fullchain.pem \
    -subj "/CN=survey.ederbarrios.online"

openssl req -x509 -nodes -days 1 -newkey rsa:2048 \
    -keyout letsencrypt/live/library.ederbarrios.online/privkey.pem \
    -out letsencrypt/live/library.ederbarrios.online/fullchain.pem \
    -subj "/CN=library.ederbarrios.online"

# Start nginx
docker-compose up -d nginx

# Generate real certificates
echo "Generating real SSL certificates..."
docker-compose run --rm certbot

# Reload nginx with real certificates
docker-compose exec nginx nginx -s reload

# Setup automatic renewal
./setup-cron.sh

echo "✅ SSL configured successfully!"
echo "🔄 Automatic renewal configured every 90 days"