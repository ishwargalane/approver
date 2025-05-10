#!/usr/bin/env python3
import argparse
import time
import sys
from approval_client import ApprovalClient
import random

# Sample data for generating requests
TITLES = [
    "Expense reimbursement",
    "Vacation request",
    "Equipment purchase",
    "Client meeting",
    "Project budget approval",
    "Training request",
    "Overtime approval",
    "Software license purchase"
]

DESCRIPTIONS = [
    "Need approval for expenses incurred during client visit",
    "Requesting time off for personal vacation",
    "New laptop needed for development work",
    "Meeting with important clients requires pre-approval",
    "Project XYZ requires additional budget allocation",
    "Professional development course on machine learning",
    "Overtime hours for project completion",
    "Annual renewal of software licenses"
]

def create_and_watch_request(client, title=None, description=None, requester_id="test_user", 
                            requester_email="test@example.com", interval=5, timeout=600):
    """
    Create a request and watch it until status changes
    
    Args:
        client: The ApprovalClient instance
        title: Title of the request (random if None)
        description: Description of the request (random if None)
        requester_id: ID of the requester
        requester_email: Email of the requester
        interval: Polling interval in seconds
        timeout: Maximum time to wait in seconds
        
    Returns:
        Tuple of (request_id, final_status)
    """
    # Generate random title and description if not provided
    if title is None:
        title = random.choice(TITLES)
    if description is None:
        description = random.choice(DESCRIPTIONS)
    
    try:
        # Create the request
        print(f"Creating approval request: '{title}'")
        print(f"Description: '{description}'")
        print(f"Requester: {requester_email}")
        
        request_id = client.create_approval_request(
            title=title,
            description=description,
            requester_id=requester_id,
            requester_email=requester_email
        )
        
        if not request_id:
            print("Failed to create request")
            return None, None
            
        print(f"\n✅ Request created successfully with ID: {request_id}")
        print("Waiting for someone to approve or reject...")
        print("(Open your Approver app and take action on this request)")
        
        # Watch for status changes
        print(f"\nWatching request {request_id} for status changes...")
        print(f"Will check every {interval} seconds (timeout after {timeout} seconds)")
        
        # Get initial status
        initial_status = client.check_request_status(request_id)
        if initial_status is None:
            print("Request not found. Exiting.")
            return request_id, None
        
        print(f"Initial status: {initial_status.upper()}")
        print("Waiting for status to change...")
        
        start_time = time.time()
        elapsed = 0
        
        while elapsed < timeout:
            status = client.check_request_status(request_id)
            
            if status is None:
                print("Request not found. Exiting.")
                return request_id, None
                
            if status != 'pending':
                print(f"\n🎉 Request status changed to: {status.upper()}")
                return request_id, status
                
            # Calculate progress percentage
            progress = min(100, (elapsed / timeout) * 100)
            bar_length = 30
            filled_length = int(bar_length * progress // 100)
            bar = '█' * filled_length + '░' * (bar_length - filled_length)
            
            # Print progress bar
            sys.stdout.write(f"\rWaiting for approval [{bar}] {progress:.1f}% ({elapsed:.0f}s)")
            sys.stdout.flush()
            
            time.sleep(interval)
            elapsed = time.time() - start_time
        
        print("\n⏰ Timeout reached. Request is still pending.")
        return request_id, 'timeout'
        
    except Exception as e:
        print(f"Error creating or watching request: {e}")
        return None, None

def main():
    parser = argparse.ArgumentParser(description='Create and watch an approval request')
    parser.add_argument('--credentials', default='./service-account-key.json', 
                        help='Path to Firebase credentials JSON file')
    parser.add_argument('--title', 
                        help='Title of the request (random if not provided)')
    parser.add_argument('--description',
                        help='Description of the request (random if not provided)')
    parser.add_argument('--requester-id', default='test_user',
                        help='ID of the requester')
    parser.add_argument('--requester-email', default='test@example.com',
                        help='Email of the requester')
    parser.add_argument('--interval', type=int, default=5,
                        help='Polling interval in seconds')
    parser.add_argument('--timeout', type=int, default=600,
                        help='Maximum time to wait in seconds (default: 10 minutes)')
    
    args = parser.parse_args()
    
    try:
        print(f"Initializing client with credentials from: {args.credentials}")
        client = ApprovalClient(args.credentials)
        
        request_id, final_status = create_and_watch_request(
            client=client,
            title=args.title,
            description=args.description,
            requester_id=args.requester_id,
            requester_email=args.requester_email,
            interval=args.interval,
            timeout=args.timeout
        )
        
        if final_status == 'approved':
            print("✅ Request was APPROVED!")
            return 0
        elif final_status == 'rejected':
            print("❌ Request was REJECTED!")
            return 0
        else:
            print(f"⚠️ Monitoring ended without a final decision. Request ID: {request_id}")
            return 1
            
    except Exception as e:
        print(f"Error: {e}")
        return 1

if __name__ == "__main__":
    exit(main()) 