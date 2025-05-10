import 'package:flutter/material.dart';
import 'package:approver/models/approval_request.dart';
import 'package:approver/services/database_service.dart';
import 'package:intl/intl.dart';

class RequestDetailsScreen extends StatelessWidget {
  final ApprovalRequest request;
  final DatabaseService _databaseService = DatabaseService();

  RequestDetailsScreen({super.key, required this.request});

  Future<void> _updateRequestStatus(BuildContext context, ApprovalStatus status) async {
    try {
      await _databaseService.updateApprovalStatus(request.id, status);
      if (context.mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating request: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('MMMM d, yyyy').format(request.createdAt);
    final formattedTime = DateFormat('h:mm a').format(request.createdAt);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title section
            Text(
              request.title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Status indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: request.status == ApprovalStatus.pending
                    ? Colors.orange.shade100
                    : request.status == ApprovalStatus.approved
                        ? Colors.green.shade100
                        : Colors.red.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                request.status.toString().split('.').last.toUpperCase(),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: request.status == ApprovalStatus.pending
                      ? Colors.orange.shade800
                      : request.status == ApprovalStatus.approved
                          ? Colors.green.shade800
                          : Colors.red.shade800,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Details section
            const Text(
              'Request Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 0,
              color: Colors.grey.shade100,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  request.description,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Requester info
            const Text(
              'Requester Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
                backgroundColor: Colors.blue,
                child: Icon(
                  Icons.person,
                  color: Colors.white,
                ),
              ),
              title: Text(request.requesterEmail),
              subtitle: Text('ID: ${request.requesterId}'),
            ),
            const SizedBox(height: 24),

            // Date and time
            const Text(
              'Request Timestamp',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  size: 20,
                  color: Colors.blue,
                ),
                const SizedBox(width: 8),
                Text(
                  formattedDate,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(width: 24),
                const Icon(
                  Icons.access_time,
                  size: 20,
                  color: Colors.blue,
                ),
                const SizedBox(width: 8),
                Text(
                  formattedTime,
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 40),

            // Action buttons
            if (request.status == ApprovalStatus.pending)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _updateRequestStatus(context, ApprovalStatus.rejected),
                    icon: const Icon(Icons.cancel, color: Colors.white),
                    label: const Text('Reject', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _updateRequestStatus(context, ApprovalStatus.approved),
                    icon: const Icon(Icons.check_circle, color: Colors.white),
                    label: const Text('Approve', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
} 