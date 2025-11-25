#!/bin/bash

# Script to generate Android keystore for signing release builds
# This script will create a keystore file and display the information needed for GitHub Secrets

echo "========================================="
echo "Android Keystore Generation Script"
echo "========================================="
echo ""

# Prompt for keystore details
read -p "Enter keystore password (min 6 characters): " KEYSTORE_PASSWORD
read -p "Enter key alias (e.g., upload): " KEY_ALIAS
read -p "Enter key password (min 6 characters): " KEY_PASSWORD
read -p "Enter your name: " DNAME_CN
read -p "Enter your organization (optional): " DNAME_O
read -p "Enter your city: " DNAME_L
read -p "Enter your state/province: " DNAME_ST
read -p "Enter your country code (e.g., US, IN): " DNAME_C

echo ""
echo "Generating keystore..."
echo ""

# Generate the keystore
keytool -genkey -v \
  -keystore android/app/upload-keystore.jks \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias "$KEY_ALIAS" \
  -storepass "$KEYSTORE_PASSWORD" \
  -keypass "$KEY_PASSWORD" \
  -dname "CN=$DNAME_CN, O=$DNAME_O, L=$DNAME_L, ST=$DNAME_ST, C=$DNAME_C"

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Keystore generated successfully!"
    echo ""
    echo "========================================="
    echo "GitHub Secrets Configuration"
    echo "========================================="
    echo ""
    echo "Add these secrets to your GitHub repository:"
    echo "(Settings → Secrets and variables → Actions → New repository secret)"
    echo ""
    echo "1. KEYSTORE_PASSWORD"
    echo "   Value: $KEYSTORE_PASSWORD"
    echo ""
    echo "2. KEY_ALIAS"
    echo "   Value: $KEY_ALIAS"
    echo ""
    echo "3. KEY_PASSWORD"
    echo "   Value: $KEY_PASSWORD"
    echo ""
    echo "4. KEYSTORE_BASE64"
    echo "   Run this command to get the value:"
    echo "   base64 -w 0 android/app/upload-keystore.jks"
    echo ""
    echo "5. GOOGLE_SERVICES_JSON"
    echo "   Run this command to get the value:"
    echo "   cat android/app/google-services.json"
    echo ""
    echo "========================================="
    echo "⚠️  IMPORTANT: Keep these values secure!"
    echo "========================================="
    echo ""
    
    # Generate base64 for convenience
    echo "Generating base64 encoded keystore..."
    KEYSTORE_BASE64=$(base64 -w 0 android/app/upload-keystore.jks 2>/dev/null || base64 android/app/upload-keystore.jks)
    echo ""
    echo "KEYSTORE_BASE64 value (copy this):"
    echo "$KEYSTORE_BASE64"
    echo ""
else
    echo ""
    echo "❌ Failed to generate keystore"
    echo "Make sure you have keytool installed (comes with Java JDK)"
    exit 1
fi
