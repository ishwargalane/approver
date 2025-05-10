#!/usr/bin/env python3
import os
import argparse
from approval_client import ApprovalClient
import random
import datetime

# Sample data for generating requests
TITLES = [
    "Expense reimbursement",
    "Vacation request",
    "Equipment purchase",
    "Client meeting",
    "Project budget approval",
    "Training request",
    "Overtime approval",
    "Software license purchase",
    "Marketing campaign",
    "Contract renewal"
]

DESCRIPTIONS = [
    "Need approval for expenses incurred during client visit",
    "Requesting time off for personal vacation",
    "New laptop needed for development work",
    "Meeting with important clients requires pre-approval",
    "Project XYZ requires additional budget allocation",
    "Professional development course on machine learning",
    "Overtime hours for project completion",
    "Annual renewal of Adobe Creative Cloud",
    "Facebook ad campaign for new product launch",
    "Renewing service contract with vendor"
]

REQUESTER_IDS = [
    "user1",
    "user2",
    "user3",
    "user4",
    "user5"
]

REQUESTER_EMAILS = [
    "john.doe@example.com",
    "jane.smith@example.com",
    "alex.wong@example.com",
    "sarah.johnson@example.com",
    "mike.thompson@example.com"
]

def generate_test_requests(client, count=5):
    """
    Generate test approval requests
    
    Args:
        client: The ApprovalClient instance
        count: Number of test requests to generate
    """
    created_requests = []
    
    for i in range(count):
        title_index = random.randint(0, len(TITLES) - 1)
        desc_index = random.randint(0, len(DESCRIPTIONS) - 1)
        requester_index = random.randint(0, len(REQUESTER_IDS) - 1)
        
        title = TITLES[title_index]
        description = DESCRIPTIONS[desc_index]
        requester_id = REQUESTER_IDS[requester_index]
        requester_email = REQUESTER_EMAILS[requester_index]
        
        try:
            request_id = client.create_approval_request(
                title=title,
                description=description,
                requester_id=requester_id,
                requester_email=requester_email
            )
            created_requests.append(request_id)
            print(f"Created request {i+1}/{count}: {title}")
        except Exception as e:
            print(f"Error creating test request: {e}")
    
    return created_requests

def main():
    parser = argparse.ArgumentParser(description='Generate test approval requests')
    parser.add_argument('--credentials', default='./service-account-key.json', 
                        help='Path to Firebase credentials JSON file')
    parser.add_argument('--count', type=int, default=5, 
                        help='Number of test requests to generate')
    
    args = parser.parse_args()
    
    try:
        print(f"Initializing client with credentials from: {args.credentials}")
        client = ApprovalClient(args.credentials)
        
        print(f"Generating {args.count} test approval requests...")
        request_ids = generate_test_requests(client, args.count)
        
        print(f"Successfully created {len(request_ids)} test requests")
        print("Request IDs:")
        for i, request_id in enumerate(request_ids):
            print(f"{i+1}. {request_id}")
            
    except Exception as e:
        print(f"Error: {e}")
        return 1
    
    return 0

if __name__ == "__main__":
    exit(main()) 