import firebase_admin
from firebase_admin import credentials, firestore
import argparse
import datetime
import os
import json

class ApprovalClient:
    def __init__(self, credentials_path=None):
        """
        Initialize the ApprovalClient with Firebase credentials.
        
        Args:
            credentials_path: Path to the Firebase service account JSON file.
                              If None, looks for FIREBASE_CREDENTIALS_PATH env variable.
        """
        if credentials_path is None:
            credentials_path = os.environ.get('FIREBASE_CREDENTIALS_PATH')
            if credentials_path is None:
                raise ValueError(
                    "Firebase credentials path not provided. Either pass it as an argument "
                    "or set the FIREBASE_CREDENTIALS_PATH environment variable."
                )
        
        try:
            cred = credentials.Certificate(credentials_path)
            firebase_admin.initialize_app(cred)
            self.db = firestore.client()
            print("Successfully connected to Firebase!")
        except Exception as e:
            print(f"Error initializing Firebase: {e}")
            raise
    
    def create_approval_request(self, title, description, requester_id, requester_email):
        """
        Create a new approval request in Firestore.
        
        Args:
            title: Title of the request
            description: Detailed description of the request
            requester_id: ID or identifier of the requester
            requester_email: Email of the requester
            
        Returns:
            ID of the created request
        """
        try:
            # Create the request document
            request_data = {
                'title': title,
                'description': description,
                'requesterId': requester_id,
                'requesterEmail': requester_email,
                'createdAt': firestore.SERVER_TIMESTAMP,
                'status': 'pending'
            }
            
            # Add to Firestore
            request_ref = self.db.collection('approvals').add(request_data)
            request_id = request_ref[1].id
            print(f"Successfully created approval request with ID: {request_id}")
            return request_id
        
        except Exception as e:
            print(f"Error creating approval request: {e}")
            raise
    
    def check_request_status(self, request_id):
        """
        Check the status of an approval request.
        
        Args:
            request_id: The ID of the request to check
            
        Returns:
            Status of the request (pending, approved, rejected)
        """
        try:
            request_doc = self.db.collection('approvals').document(request_id).get()
            
            if request_doc.exists:
                request_data = request_doc.to_dict()
                status = request_data.get('status', 'unknown')
                print(f"Request {request_id} status: {status}")
                return status
            else:
                print(f"Request with ID {request_id} not found")
                return None
        
        except Exception as e:
            print(f"Error checking request status: {e}")
            raise

def main():
    parser = argparse.ArgumentParser(description='Firebase Approval Request Client')
    parser.add_argument('--credentials', help='Path to Firebase credentials JSON file')
    
    subparsers = parser.add_subparsers(dest='command', help='Command to run')
    
    # Create request command
    create_parser = subparsers.add_parser('create', help='Create a new approval request')
    create_parser.add_argument('--title', required=True, help='Title of the request')
    create_parser.add_argument('--description', required=True, help='Description of the request')
    create_parser.add_argument('--requester-id', required=True, help='ID of the requester')
    create_parser.add_argument('--requester-email', required=True, help='Email of the requester')
    
    # Check status command
    check_parser = subparsers.add_parser('check', help='Check the status of an approval request')
    check_parser.add_argument('--request-id', required=True, help='ID of the request to check')
    
    args = parser.parse_args()
    
    try:
        client = ApprovalClient(args.credentials)
        
        if args.command == 'create':
            client.create_approval_request(
                args.title,
                args.description,
                args.requester_id,
                args.requester_email
            )
        elif args.command == 'check':
            client.check_request_status(args.request_id)
        else:
            parser.print_help()
    
    except Exception as e:
        print(f"Error: {e}")
        return 1
    
    return 0

if __name__ == "__main__":
    exit(main()) 