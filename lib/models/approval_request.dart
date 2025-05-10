import 'package:cloud_firestore/cloud_firestore.dart';

enum ApprovalStatus { pending, approved, rejected }

class ApprovalRequest {
  final String id;
  final String title;
  final String description;
  final String requesterId;
  final String requesterEmail;
  final DateTime createdAt;
  final ApprovalStatus status;

  ApprovalRequest({
    required this.id,
    required this.title,
    required this.description,
    required this.requesterId,
    required this.requesterEmail,
    required this.createdAt,
    this.status = ApprovalStatus.pending,
  });

  factory ApprovalRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ApprovalRequest(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      requesterId: data['requesterId'] ?? '',
      requesterEmail: data['requesterEmail'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      status: ApprovalStatus.values.firstWhere(
        (e) => e.toString() == 'ApprovalStatus.${data['status'] ?? 'pending'}',
        orElse: () => ApprovalStatus.pending,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'requesterId': requesterId,
      'requesterEmail': requesterEmail,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status.toString().split('.').last,
    };
  }

  ApprovalRequest copyWith({
    String? id,
    String? title,
    String? description,
    String? requesterId,
    String? requesterEmail,
    DateTime? createdAt,
    ApprovalStatus? status,
  }) {
    return ApprovalRequest(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      requesterId: requesterId ?? this.requesterId,
      requesterEmail: requesterEmail ?? this.requesterEmail,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
    );
  }
} 