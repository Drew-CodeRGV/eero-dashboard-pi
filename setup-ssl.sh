#!/bin/bash

# SSL Setup Script for Eero Dashboard
# Adds HTTPS support with self-signed certificates or Let's Encrypt

set -e

echo "🔒 Setting up SSL/HTTPS for Eero Dashboard"
echo "=========================================="

# Check if running as correct user
if [ "$USER" != "wifi" ]; then
    echo "⚠️  This script should be run as the 'wifi' user"
    echo "💡 Switch to wifi user: sudo su - wifi"
    exit 1
fi

# Configuration
DASHBOARD_DIR="/home/wifi/eero-dashboard"
SSL_DIR="$DASHBOARD_DIR/ssl"
CERT_FILE="$SSL_DIR/dashboard.crt"
KEY_FILE="$SSL_DIR/dashboard.key"

# Create SSL directory
mkdir -p "$SSL_DIR"

echo "🔧 Choose SSL certificate type:"
echo "1) Self-signed certificate (quick setup, browser warnings)"
echo "2) Let's Encrypt certificate (requires domain name)"
echo "3) Use existing certificate files"
read -p "Enter choice (1-3): " ssl_choice

case $ssl_choice in
    1)
        echo "📜 Creating self-signed certificate..."
        
        # Generate self-signed certificate
        openssl req -x509 -newkey rsa:4096 -keyout "$KEY_FILE" -out "$CERT_FILE" \
            -days 365 -nodes -subj "/C=US/ST=State/L=City/O=Organization/CN=eero-dashboard"
        
        chmod 600 "$KEY_FILE"
        chmod 644 "$CERT_FILE"
        
        echo "✅ Self-signed certificate created"
        ;;
        
    2)
        echo "🌐 Setting up Let's Encrypt certificate..."
        
        # Install certbot if not present
        if ! command -v certbot &> /dev/null; then
            echo "📦 Installing certbot..."
            sudo apt update
            sudo apt install -y certbot
        fi
        
        read -p "Enter your domain name (e.g., dashboard.yourdomain.com): " domain_name
        
        if [ -z "$domain_name" ]; then
            echo "❌ Domain name is required for Let's Encrypt"
            exit 1
        fi
        
        # Stop dashboard temporarily
        sudo systemctl stop eero-dashboard
        
        # Get certificate
        sudo certbot certonly --standalone -d "$domain_name" --non-interactive --agree-tos \
            --email "admin@$domain_name" || {
            echo "❌ Let's Encrypt certificate generation failed"
            sudo systemctl start eero-dashboard
            exit 1
        }
        
        # Copy certificates to dashboard directory
        sudo cp "/etc/letsencrypt/live/$domain_name/fullchain.pem" "$CERT_FILE"
        sudo cp "/etc/letsencrypt/live/$domain_name/privkey.pem" "$KEY_FILE"
        sudo chown wifi:wifi "$CERT_FILE" "$KEY_FILE"
        chmod 600 "$KEY_FILE"
        chmod 644 "$CERT_FILE"
        
        # Setup auto-renewal
        echo "0 12 * * * /usr/bin/certbot renew --quiet && systemctl restart eero-dashboard" | sudo crontab -
        
        echo "✅ Let's Encrypt certificate installed"
        ;;
        
    3)
        echo "📁 Using existing certificate files..."
        
        read -p "Enter path to certificate file (.crt or .pem): " existing_cert
        read -p "Enter path to private key file (.key): " existing_key
        
        if [ ! -f "$existing_cert" ] || [ ! -f "$existing_key" ]; then
            echo "❌ Certificate or key file not found"
            exit 1
        fi
        
        cp "$existing_cert" "$CERT_FILE"
        cp "$existing_key" "$KEY_FILE"
        chmod 600 "$KEY_FILE"
        chmod 644 "$CERT_FILE"
        
        echo "✅ Existing certificates copied"
        ;;
        
    *)
        echo "❌ Invalid choice"
        exit 1
        ;;
esac

# Update dashboard configuration
echo "🔧 Updating dashboard configuration for SSL..."

# Create SSL configuration file
cat > "$DASHBOARD_DIR/ssl_config.json" << EOF
{
    "ssl_enabled": true,
    "cert_file": "$CERT_FILE",
    "key_file": "$KEY_FILE",
    "ssl_port": 443,
    "redirect_http": true
}
EOF

echo "✅ SSL configuration created"
echo ""
echo "📋 Next steps:"
echo "1. 🔄 Restart dashboard: sudo systemctl restart eero-dashboard"
echo "2. 🌐 Access via HTTPS: https://$(hostname -I | awk '{print $1}')"
echo "3. 🔧 Configure network interface binding in admin panel"
echo ""
echo "⚠️  Note: Self-signed certificates will show browser warnings"
echo "💡 Add certificate exception in your browser to proceed"