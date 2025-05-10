#!/usr/bin/env python3
import os
import requests
import json
import argparse
import time

"""
This script sends an approval request notification via Firebase Cloud Messaging.
It supports both service account key file and environment variables for authentication.
"""

def send_approval_notification(service_account_path=None, device_token=None, topic=None, request_id="test-123"):
    # Get the access token, either from file or environment variables
    access_token = get_access_token(service_account_path)
    
    if not access_token:
        print("Failed to get access token")
        return False
    
    # Get project ID from service account or environment
    project_id = get_project_id(service_account_path)
    if not project_id:
        print("Failed to get project ID")
        return False
    
    # FCM API URL
    fcm_url = f"https://fcm.googleapis.com/v1/projects/{project_id}/messages:send"
    
    # Headers
    headers = {
        'Authorization': 'Bearer ' + access_token,
        'Content-Type': 'application/json'
    }
    
    # Message payload with approval request data
    message = {
        "notification": {
            "title": "New Approval Request",
            "body": "Please review the request from test@example.com"
        },
        "data": {
            "type": "approval_request",
            "requestId": request_id,
            "title": "Test Approval",
            "description": "This is a test approval request",
            "requesterEmail": "test@example.com",
            "createdAt": str(int(time.time())),
            "click_action": "FLUTTER_NOTIFICATION_CLICK"
        },
        "android": {
            "priority": "high",
            "notification": {
                "channel_id": "approver_channel"
            }
        },
        "apns": {
            "headers": {
                "apns-priority": "10"
            },
            "payload": {
                "aps": {
                    "alert": {
                        "title": "New Approval Request",
                        "body": "Please review the request from test@example.com"
                    },
                    "badge": 1,
                    "sound": "default"
                }
            }
        }
    }
    
    # Add either token or topic
    if device_token:
        message["token"] = device_token
    elif topic:
        message["topic"] = topic
    else:
        message["topic"] = "approval_requests"  # Default topic
    
    # Payload
    payload = {
        "message": message
    }
    
    # Send the request
    try:
        response = requests.post(fcm_url, headers=headers, data=json.dumps(payload))
        
        if response.status_code == 200:
            print("Approval notification sent successfully!")
            print(response.text)
            return True
        else:
            print("Failed to send notification")
            print(f"Status Code: {response.status_code}")
            print(response.text)
            return False
    except Exception as e:
        print(f"Error sending notification: {e}")
        return False

def get_access_token(service_account_path=None):
    """Gets an OAuth2 access token using either service account file or environment variables."""
    try:
        # Check if environment variables are set
        if os.environ.get('FIREBASE_PRIVATE_KEY') and os.environ.get('FIREBASE_CLIENT_EMAIL'):
            print("Using credentials from environment variables")
            # Create a temporary service account file from environment variables
            service_account_info = {
                "type": "service_account",
                "project_id": os.environ.get('FIREBASE_PROJECT_ID'),
                "private_key_id": os.environ.get('FIREBASE_PRIVATE_KEY_ID', "private_key_id"),
                "private_key": os.environ.get('FIREBASE_PRIVATE_KEY').replace('\\n', '\n'),
                "client_email": os.environ.get('FIREBASE_CLIENT_EMAIL'),
                "client_id": os.environ.get('FIREBASE_CLIENT_ID', "client_id"),
                "auth_uri": "https://accounts.google.com/o/oauth2/auth",
                "token_uri": "https://oauth2.googleapis.com/token",
                "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
                "client_x509_cert_url": os.environ.get('FIREBASE_CLIENT_X509_CERT_URL', "")
            }
        # Otherwise, use the service account file
        elif service_account_path:
            print(f"Using credentials from file: {service_account_path}")
            with open(service_account_path) as f:
                service_account_info = json.load(f)
        else:
            print("Error: No credentials provided. Either set environment variables or provide a service account file.")
            print("Required environment variables: FIREBASE_PRIVATE_KEY, FIREBASE_CLIENT_EMAIL, FIREBASE_PROJECT_ID")
            return None
        
        # Get the JWT token
        url = "https://oauth2.googleapis.com/token"
        payload = {
            "grant_type": "urn:ietf:params:oauth:grant-type:jwt-bearer",
            "assertion": create_jwt(service_account_info)
        }
        headers = {"Content-Type": "application/x-www-form-urlencoded"}
        
        response = requests.post(url, headers=headers, data=payload)
        
        if response.status_code == 200:
            return response.json()['access_token']
        else:
            print(f"Error getting access token: {response.text}")
            return None
    except Exception as e:
        print(f"Error reading credentials: {e}")
        return None

def create_jwt(service_account_info):
    """Creates a signed JWT using the service account credentials."""
    import time
    import jwt  # pip install PyJWT
    
    iat = int(time.time())
    exp = iat + 3600  # Token expires in 1 hour
    
    payload = {
        "iss": service_account_info["client_email"],
        "sub": service_account_info["client_email"],
        "aud": "https://oauth2.googleapis.com/token",
        "iat": iat,
        "exp": exp,
        "scope": "https://www.googleapis.com/auth/firebase.messaging"
    }
    
    private_key = service_account_info["private_key"]
    
    signed_jwt = jwt.encode(
        payload,
        private_key,
        algorithm="RS256"
    )
    
    return signed_jwt

def get_project_id(service_account_path=None):
    """Gets the project ID from the service account file or environment."""
    try:
        # Try environment variables first
        if os.environ.get('FIREBASE_PROJECT_ID'):
            return os.environ.get('FIREBASE_PROJECT_ID')
        
        # Otherwise use the service account file
        if service_account_path:
            with open(service_account_path) as f:
                service_account_info = json.load(f)
            return service_account_info["project_id"]
        
        print("Error: No project ID found. Set FIREBASE_PROJECT_ID or provide a service account file.")
        return None
    except Exception as e:
        print(f"Error reading project ID: {e}")
        return None

def print_env_var_instructions():
    """Prints instructions for setting environment variables."""
    print("\nTo use environment variables instead of a service account file, set the following:")
    print("  export FIREBASE_PROJECT_ID='your-project-id'")
    print("  export FIREBASE_PRIVATE_KEY='-----BEGIN PRIVATE KEY-----\\n...\\n-----END PRIVATE KEY-----\\n'")
    print("  export FIREBASE_CLIENT_EMAIL='firebase-adminsdk-xxxx@your-project.iam.gserviceaccount.com'")
    print("\nOptional environment variables:")
    print("  export FIREBASE_PRIVATE_KEY_ID='private-key-id'")
    print("  export FIREBASE_CLIENT_ID='client-id'")
    print("  export FIREBASE_CLIENT_X509_CERT_URL='cert-url'")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Send a test approval notification via Firebase Cloud Messaging')
    
    parser.add_argument('--service-account', '-s',
                        help='Path to the Firebase service account key file (JSON). Optional if using environment variables.')
    
    group = parser.add_mutually_exclusive_group()
    group.add_argument('--token', '-t', help='Device token to send the notification to')
    group.add_argument('--topic', '-o', help='Topic to send the notification to')
    
    parser.add_argument('--request-id', '-r', default="test-" + str(int(time.time())),
                       help='Custom request ID for the approval')
    
    parser.add_argument('--env-help', action='store_true', help='Show instructions for setting environment variables')
    
    args = parser.parse_args()
    
    if args.env_help:
        print_env_var_instructions()
        exit(0)
    
    send_approval_notification(args.service_account, args.token, args.topic, args.request_id) 