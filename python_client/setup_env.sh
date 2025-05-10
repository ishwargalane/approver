#!/bin/bash
# This script helps set up environment variables from a service account key file

echo "Setting up environment variables for Firebase authentication"
echo "============================================================"

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 path/to/service-account-key.json"
    exit 1
fi

SERVICE_ACCOUNT_FILE=$1

if [ ! -f "$SERVICE_ACCOUNT_FILE" ]; then
    echo "Error: File $SERVICE_ACCOUNT_FILE not found"
    exit 1
fi

# Extract values from JSON
PROJECT_ID=$(cat $SERVICE_ACCOUNT_FILE | grep -o '"project_id": "[^"]*' | cut -d'"' -f4)
PRIVATE_KEY_ID=$(cat $SERVICE_ACCOUNT_FILE | grep -o '"private_key_id": "[^"]*' | cut -d'"' -f4)
CLIENT_EMAIL=$(cat $SERVICE_ACCOUNT_FILE | grep -o '"client_email": "[^"]*' | cut -d'"' -f4)
CLIENT_ID=$(cat $SERVICE_ACCOUNT_FILE | grep -o '"client_id": "[^"]*' | cut -d'"' -f4)
CLIENT_X509_CERT_URL=$(cat $SERVICE_ACCOUNT_FILE | grep -o '"client_x509_cert_url": "[^"]*' | cut -d'"' -f4)

# Private key requires special handling due to newlines
PRIVATE_KEY=$(cat $SERVICE_ACCOUNT_FILE | python3 -c "import sys, json; print(json.load(sys.stdin)['private_key'])")

# Output export commands
echo ""
echo "Add the following to your ~/.bashrc or ~/.zshrc file:"
echo "----------------------------------------------------"
echo "export FIREBASE_PROJECT_ID='$PROJECT_ID'"
echo "export FIREBASE_PRIVATE_KEY='$PRIVATE_KEY'"
echo "export FIREBASE_CLIENT_EMAIL='$CLIENT_EMAIL'"
echo "export FIREBASE_PRIVATE_KEY_ID='$PRIVATE_KEY_ID'"
echo "export FIREBASE_CLIENT_ID='$CLIENT_ID'"
echo "export FIREBASE_CLIENT_X509_CERT_URL='$CLIENT_X509_CERT_URL'"
echo ""

# Give option to set them immediately
echo "Would you like to set these environment variables for the current session? (y/n)"
read answer

if [ "$answer" = "y" ] || [ "$answer" = "Y" ]; then
    export FIREBASE_PROJECT_ID="$PROJECT_ID"
    export FIREBASE_PRIVATE_KEY="$PRIVATE_KEY"
    export FIREBASE_CLIENT_EMAIL="$CLIENT_EMAIL"
    export FIREBASE_PRIVATE_KEY_ID="$PRIVATE_KEY_ID"
    export FIREBASE_CLIENT_ID="$CLIENT_ID"
    export FIREBASE_CLIENT_X509_CERT_URL="$CLIENT_X509_CERT_URL"
    
    echo "Environment variables have been set for this session."
    echo "To test, run: python3 test_notifications.py --topic approval_requests"
else
    echo "Environment variables were not set."
    echo "You can manually set them using the export commands above."
fi 