#!/usr/bin/env python3
import os
import requests
import json
import argparse
import time

"""
Improved script for sending approval request notifications to the Approver app.
This script sends a notification that is compatible with the action buttons feature.
"""

def send_approval_notification(service_account_path, device_token=None, topic=None):
    # Get the access token
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
    
    # Generate a unique request ID
    request_id = "py-test-{}".format(int(time.time()))
    
    # Message payload designed to work with the notification action buttons
    message = {
        "notification": {
            "title": "New Approval Request",
            "body": "Please review and approve or reject this request"
        },
        "data": {
            "type": "approval_request",  # Important for action button detection
            "requestId": request_id,     # Required for action buttons
            "title": "Python Client Request",
            "description": "This request was sent from the improved Python client",
            "requesterEmail": "python-client@example.com",
            "createdAt": str(int(time.time())),
            "click_action": "FLUTTER_NOTIFICATION_CLICK"
        },
        "android": {
            "priority": "high",
            "notification": {
                "channel_id": "approver_channel",
                "click_action": "FLUTTER_NOTIFICATION_CLICK"
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
                        "body": "Please review and approve or reject this request"
                    },
                    "badge": 1,
                    "sound": "default",
                    "category": "APPROVAL_REQUEST"  # For iOS action handling
                },
                "request_id": request_id  # Include in custom data for iOS
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
    
    # Print request for debugging
    print("\nSending FCM request:")
    print(json.dumps(payload, indent=2))
    
    # Send the request
    try:
        response = requests.post(fcm_url, headers=headers, data=json.dumps(payload))
        
        if response.status_code == 200:
            print("\nNotification sent successfully!")
            print(response.text)
            print(f"\nRequest ID for reference: {request_id}")
            
            # Print Firebase Cloud Messaging testing instructions
            print("\n=== TESTING INSTRUCTIONS ===")
            print("1. This notification should appear with Approve/Reject buttons")
            print("2. Try tapping the Approve or Reject button while app is in background")
            print("3. Check Firebase Console to see if status was updated")
            return True
        else:
            print("\nFailed to send notification")
            print(f"Status Code: {response.status_code}")
            print(response.text)
            return False
    except Exception as e:
        print(f"\nError sending notification: {e}")
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