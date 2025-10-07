#!/bin/bash

set -e  # Exit on any error

echo "🔐 Setting up SSL with Let's Encrypt..."

# Function to check if certificates exist
check_certificates() {
    if [ -f "letsencrypt/live/survey.ederbarrios.online/fullchain.pem" ]; then
        echo "✅ SSL certificates found"
        return 0
    else
        echo "❌ SSL certificates not found"
        return 1
    fi
}

# Function to test domain connectivity
test_domain_connectivity() {
    local domain=$1
    echo "🌐 Testing connectivity to $domain..."
    
    if curl -I -m 10 http://$domain 2>/dev/null | head -n 1 | grep -q "HTTP"; then
        echo "✅ $domain is reachable"
        return 0
    else
        echo "❌ $domain is not reachable"
        return 1
    fi
}

# Stop nginx temporarily
echo "🛑 Stopping existing containers..."
docker-compose down

# Clean existing certificates
echo "🧹 Cleaning existing SSL certificates..."
rm -rf letsencrypt/live
rm -rf letsencrypt/archive
rm -rf letsencrypt/renewal

# Create directories
mkdir -p letsencrypt webroot

# Step 1: Use HTTP-only config for certificate generation
echo "📋 Step 1: Starting HTTP-only nginx for certificate challenge..."
cp nginx-initial.conf nginx.conf
docker compose up -d nginx

# Wait for nginx to start
echo "⏳ Waiting for nginx to start..."
sleep 10

# Check if nginx is running
if ! docker compose ps | grep -q "nginx.*Up"; then
    echo "❌ Nginx failed to start. Check logs:"
    docker compose logs nginx
    exit 1
fi

# Test domain connectivity
echo "🌐 Testing domain connectivity..."
DOMAINS=("survey.ederbarrios.online" "library.ederbarrios.online" "apilibrary.ederbarrios.online" "cv.ederbarrios.online" "store.ederbarrios.online")
failed_domains=()

for domain in "${DOMAINS[@]}"; do
    if ! test_domain_connectivity "$domain"; then
        failed_domains+=("$domain")
    fi
done

if [ ${#failed_domains[@]} -gt 0 ]; then
    echo "⚠️  Some domains are not reachable:"
    printf '   - %s\n' "${failed_domains[@]}"
    echo "💡 Please check DNS records and firewall settings"
    
    read -p "🤔 Continue with SSL generation anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "❌ Aborting SSL setup. Staying with HTTP configuration."
        echo "💡 Fix connectivity issues and run: ./init-ssl.sh"
        exit 0
    fi
fi

# Step 2: Generate certificates
echo "🔐 Step 2: Generating SSL certificates..."
if docker-compose run --rm certbot; then
    echo "✅ Certbot completed successfully"
else
    echo "❌ Certbot failed. Staying with HTTP configuration."
    echo "📋 Current configuration: HTTP-only"
    echo "💡 To retry later: ./init-ssl.sh"
    exit 1
fi

# Verify certificates were created
if ! check_certificates; then
    echo "❌ Certificates were not created properly. Staying with HTTP."
    echo "📋 Current configuration: HTTP-only"
    exit 1
fi

# Step 3: Switch to HTTPS config only if certificates exist
echo "🔒 Step 3: Switching to HTTPS configuration..."
cp nginx-ssl.conf nginx.conf

if docker-compose restart nginx; then
    echo "✅ Nginx restarted with HTTPS configuration"
else
    echo "❌ Nginx failed to restart with HTTPS. Rolling back..."
    cp nginx-initial.conf nginx.conf
    docker-compose restart nginx
    echo "📋 Rolled back to HTTP configuration"
    exit 1
fi

# Wait and verify nginx is still running
sleep 5
if ! docker-compose ps | grep -q "nginx.*Up"; then
    echo "❌ Nginx failed with HTTPS config. Rolling back..."
    cp nginx-initial.conf nginx.conf
    docker-compose restart nginx
    echo "📋 Rolled back to HTTP configuration"
    exit 1
fi

# Setup automatic renewal
echo "🔄 Setting up automatic renewal..."
./setup-cron.sh

echo "✅ SSL configured successfully!"
echo "🔄 Automatic renewal configured every 90 days"
echo "🌐 Your sites are now available at:"
echo "   - https://survey.ederbarrios.online"
echo "   - https://library.ederbarrios.online"
echo "   - https://apilibrary.ederbarrios.online"
echo "   - https://cv.ederbarrios.online"