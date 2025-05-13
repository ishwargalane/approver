#!/usr/bin/env python3
import os
import requests
import json
import argparse
import time
import firebase_admin
from firebase_admin import credentials, firestore

"""
Improved script for sending approval request notifications to the Approver app.
This script creates a proper Firestore document and sends a notification that will show action buttons.

Installation:
pip install firebase-admin requests PyJWT
"""

def send_approval_notification(service_account_path, device_token=None, topic=None):
    # Initialize Firebase Admin if not already initialized
    try:
        app = firebase_admin.get_app()
    except ValueError:
        cred = credentials.Certificate(service_account_path)
        app = firebase_admin.initialize_app(cred)
    
    # Create Firestore client
    db = firestore.client()
    
    # Generate a unique request ID
    request_id = "py-test-{}".format(int(time.time()))
    timestamp = firestore.SERVER_TIMESTAMP
    
    # Create the approval request document in Firestore
    print(f"Creating Firestore document with ID: {request_id}")
    request_data = {
        "title": "Test Approval",
        "description": "This is a test approval request created by the Python client",
        "requesterEmail": "test@example.com",
        "requesterId": "python-client",
        "createdAt": timestamp,
        "status": "pending"
    }
    
    try:
        # Add document with custom ID
        db.collection('approvals').document(request_id).set(request_data)
        print("✅ Firestore document created successfully")
    except Exception as e:
        print(f"❌ Error creating Firestore document: {e}")
        return False
    
    # Get the access token for FCM
    access_token = get_access_token(service_account_path)
    
    if not access_token:
        print("Failed to get access token")
        return False
    
    # FCM API URL
    fcm_url = "https://fcm.googleapis.com/v1/projects/{}/messages:send".format(
        get_project_id(service_account_path)
    )
    
    # Headers
    headers = {
        'Authorization': 'Bearer ' + access_token,
        'Content-Type': 'application/json'
    }
    
    # Message payload designed to match the old client format but with proper action support
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
                "channel_id": "approver_channel",
                "tag": request_id
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
                    "sound": "default",
                    "category": "APPROVAL_REQUEST",
                    "mutable-content": 1
                },
                "requestId": request_id,
                "type": "approval_request"
            }
        }
    }
    
    # Add either token or topic
    if device_token:
        message["token"] = device_token
        print(f"Sending to device token: {device_token}")
    elif topic:
        message["topic"] = topic
        print(f"Sending to topic: {topic}")
    else:
        message["topic"] = "approval_requests"  # Default topic
        print("Sending to default topic: approval_requests")
    
    # Payload
    payload = {
        "message": message
    }
    
    # Send the request
    try:
        response = requests.post(fcm_url, headers=headers, data=json.dumps(payload))
        
        if response.status_code == 200:
            print("\n✅ Notification sent successfully!")
            print(response.text)
            print(f"\nRequest ID: {request_id}")
            
            print("\n=== TESTING INSTRUCTIONS ===")
            print("1. A real document was created in Firestore with ID: " + request_id)
            print("2. The notification should show Approve/Reject buttons in the background")
            print("3. Tapping a button will update the document's status in Firestore")
            print("4. Check Firestore to verify the status changed after tapping a button")
            return True
        else:
            print("\n❌ Failed to send notification")
            print(f"Status Code: {response.status_code}")
            print(response.text)
            return False
    except Exception as e:
        print(f"\n❌ Error sending notification: {e}")
        return False

def get_access_token(service_account_path):
    """Gets an OAuth2 access token using the service account credentials."""
    try:
        service_account_info = json.load(open(service_account_path))
        
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
        print(f"Error reading service account file: {e}")
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

def get_project_id(service_account_path):
    """Gets the project ID from the service account file."""
    try:
        service_account_info = json.load(open(service_account_path))
        return service_account_info["project_id"]
    except Exception as e:
        print(f"Error reading project ID: {e}")
        return None

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Send an improved approval notification via Firebase Cloud Messaging')
    
    parser.add_argument('--service-account', '-s', required=True,
                        help='Path to the Firebase service account key file (JSON)')
    
    group = parser.add_mutually_exclusive_group()
    group.add_argument('--token', '-t', help='Device token to send the notification to')
    group.add_argument('--topic', '-o', help='Topic to send the notification to')
    
    args = parser.parse_args()
    
    send_approval_notification(args.service_account, args.token, args.topic) 