#!/usr/bin/env python3
import argparse
import time
from approval_client import ApprovalClient
import sys

def monitor_request_status(client, request_id, interval=5, timeout=300):
    """
    Monitor the status of an approval request until it changes from 'pending'
    
    Args:
        client: The ApprovalClient instance
        request_id: ID of the request to monitor
        interval: Polling interval in seconds
        timeout: Maximum time to wait in seconds
        
    Returns:
        Final status of the request or None if timed out
    """
    print(f"Monitoring request {request_id} for status changes...")
    print(f"Will check every {interval} seconds (timeout after {timeout} seconds)")
    
    start_time = time.time()
    elapsed = 0
    
    while elapsed < timeout:
        status = client.check_request_status(request_id)
        
        if status is None:
            print("Request not found. Exiting.")
            return None
            
        if status != 'pending':
            print(f"\n🎉 Request status changed to: {status.upper()}")
            return status
            
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
    return 'timeout'

def create_and_monitor_request(client, title, description, requester_id, requester_email, 
                              interval=5, timeout=300):
    """
    Create a new approval request and monitor its status
    
    Args:
        client: The ApprovalClient instance
        title: Title of the request
        description: Description of the request
        requester_id: ID of the requester
        requester_email: Email of the requester
        interval: Polling interval in seconds
        timeout: Maximum time to wait in seconds
        
    Returns:
        Tuple of (request_id, final_status)
    """
    try:
        # Create the request
        request_id = client.create_approval_request(
            title=title,
            description=description,
            requester_id=requester_id,
            requester_email=requester_email
        )
        
        if not request_id:
            print("Failed to create request")
            return None, None
            
        print(f"Request created successfully with ID: {request_id}")
        print("Waiting for someone to approve or reject...")
        print("(Open your Approver app and take action on this request)")
        
        # Monitor the request status
        final_status = monitor_request_status(
            client=client,
            request_id=request_id,
            interval=interval,
            timeout=timeout
        )
        
        return request_id, final_status
        
    except Exception as e:
        print(f"Error creating or monitoring request: {e}")
        return None, None

def main():
    parser = argparse.ArgumentParser(description='Create and monitor an approval request')
    parser.add_argument('--credentials', default='./service-account-key.json', 
                        help='Path to Firebase credentials JSON file')
    parser.add_argument('--title', default='Urgent Approval Needed',
                        help='Title of the request')
    parser.add_argument('--description', default='This is a test request that needs your approval',
                        help='Description of the request')
    parser.add_argument('--requester-id', default='test_user',
                        help='ID of the requester')
    parser.add_argument('--requester-email', default='test@example.com',
                        help='Email of the requester')
    parser.add_argument('--interval', type=int, default=5,
                        help='Polling interval in seconds')
    parser.add_argument('--timeout', type=int, default=300,
                        help='Maximum time to wait in seconds')
    
    args = parser.parse_args()
    
    try:
        print(f"Initializing client with credentials from: {args.credentials}")
        client = ApprovalClient(args.credentials)
        
        request_id, final_status = create_and_monitor_request(
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
            print("⚠️ Monitoring ended without a final decision")
            return 1
            
    except Exception as e:
        print(f"Error: {e}")
        return 1

if __name__ == "__main__":
    exit(main()) 