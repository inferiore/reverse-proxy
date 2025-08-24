#!/bin/bash

echo "🔐 Setting up SSL with Let's Encrypt..."

# Stop nginx temporarily
docker-compose down

# Clean existing certificates
echo "Cleaning existing SSL certificates..."
rm -rf letsencrypt/live
rm -rf letsencrypt/archive
rm -rf letsencrypt/renewal

# Create directories
mkdir -p letsencrypt webroot

# Step 1: Use HTTP-only config for certificate generation
echo "Step 1: Starting HTTP-only nginx for certificate challenge..."
cp nginx-initial.conf nginx.conf
docker-compose up -d nginx

# Wait for nginx to start
sleep 5

# Step 2: Generate certificates
echo "Step 2: Generating SSL certificates..."
docker-compose run --rm certbot

# Step 3: Switch to HTTPS config
echo "Step 3: Switching to HTTPS configuration..."
cp nginx-ssl.conf nginx.conf
docker-compose restart nginx

# Setup automatic renewal
./setup-cron.sh

echo "✅ SSL configured successfully!"
echo "🔄 Automatic renewal configured every 90 days"
echo "🌐 Visit: https://survey.ederbarrios.online"
echo "🌐 Visit: https://library.ederbarrios.online"