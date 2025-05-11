import 'package:flutter/material.dart';
import 'package:approver/models/approval_request.dart';
import 'package:intl/intl.dart';

class RequestCard extends StatelessWidget {
  final ApprovalRequest request;
  final VoidCallback onTap;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  const RequestCard({
    super.key,
    required this.request,
    required this.onTap,
    this.onApprove,
    this.onReject,
  });

  String _getStatusColor() {
    switch (request.status) {
      case ApprovalStatus.pending:
        return 'orange';
      case ApprovalStatus.approved:
        return 'green';
      case ApprovalStatus.rejected:
        return 'red';
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('MMM d, yyyy • h:mm a').format(request.createdAt);
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      request.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor() == 'orange'
                          ? Colors.orange.shade100
                          : _getStatusColor() == 'green'
                              ? Colors.green.shade100
                              : _getStatusColor() == 'red'
                                  ? Colors.red.shade100
                                  : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      request.status.toString().split('.').last.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor() == 'orange'
                            ? Colors.orange.shade800
                            : _getStatusColor() == 'green'
                                ? Colors.green.shade800
                                : _getStatusColor() == 'red'
                                    ? Colors.red.shade800
                                    : Colors.grey.shade800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                request.description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'From: ${request.requesterEmail}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formattedDate,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (onApprove != null && onReject != null)
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.check_circle,
                            color: Colors.green.shade600,
                          ),
                          onPressed: onApprove,
                          tooltip: 'Approve',
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.cancel,
                            color: Colors.red.shade600,
                          ),
                          onPressed: onReject,
                          tooltip: 'Reject',
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
} 