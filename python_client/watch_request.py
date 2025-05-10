#!/usr/bin/env python3
import argparse
import time
import sys
from approval_client import ApprovalClient

def watch_request(client, request_id, interval=5, timeout=300):
    """
    Watch an existing approval request until its status changes
    
    Args:
        client: The ApprovalClient instance
        request_id: ID of the request to watch
        interval: Polling interval in seconds
        timeout: Maximum time to wait in seconds
        
    Returns:
        Final status of the request or None if timed out
    """
    print(f"Watching request {request_id} for status changes...")
    print(f"Will check every {interval} seconds (timeout after {timeout} seconds)")
    
    # Get initial status
    initial_status = client.check_request_status(request_id)
    if initial_status is None:
        print("Request not found. Exiting.")
        return None
    
    if initial_status != 'pending':
        print(f"Request is already in {initial_status.upper()} state.")
        return initial_status
    
    print(f"Initial status: {initial_status.upper()}")
    print("Waiting for status to change...")
    
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

def main():
    parser = argparse.ArgumentParser(description='Watch an existing approval request')
    parser.add_argument('--credentials', default='./service-account-key.json', 
                        help='Path to Firebase credentials JSON file')
    parser.add_argument('--request-id', required=True,
                        help='ID of the request to watch')
    parser.add_argument('--interval', type=int, default=5,
                        help='Polling interval in seconds')
    parser.add_argument('--timeout', type=int, default=300,
                        help='Maximum time to wait in seconds')
    
    args = parser.parse_args()
    
    try:
        print(f"Initializing client with credentials from: {args.credentials}")
        client = ApprovalClient(args.credentials)
        
        final_status = watch_request(
            client=client,
            request_id=args.request_id,
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
            print("⚠️ Watching ended without a final decision")
            return 1
            
    except Exception as e:
        print(f"Error: {e}")
        return 1

if __name__ == "__main__":
    exit(main()) 