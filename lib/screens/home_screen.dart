import 'package:flutter/material.dart';
import 'package:approver/services/auth_service.dart';
import 'package:approver/services/database_service.dart';
import 'package:approver/services/notification_service.dart';
import 'package:approver/models/approval_request.dart';
import 'package:approver/widgets/request_card.dart';
import 'package:approver/screens/request_details_screen.dart';
import 'package:approver/widgets/version_display.dart';
import 'package:provider/provider.dart';
import 'package:approver/models/app_user.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final AuthService _authService = AuthService();
  final DatabaseService _databaseService = DatabaseService();
  final NotificationService _notificationService = NotificationService();
  bool _showOnlyPending = true;

  @override
  void initState() {
    super.initState();
    // Initialize notifications
    _notificationService.init();
    _notificationService.subscribeToApprovalRequests();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh data when app is resumed
      setState(() {});
    }
  }

  Future<void> _signOut() async {
    try {
      await _notificationService.unsubscribeFromApprovalRequests();
      await _authService.signOut();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out: $e')),
      );
    }
  }

  void _viewRequestDetails(ApprovalRequest request) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RequestDetailsScreen(request: request),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AppUser?>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Approval Requests'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
            tooltip: 'Sign Out',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await _notificationService.testManualNotification();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Test notification sent')),
          );
        },
        tooltip: 'Test Notification',
        child: const Icon(Icons.notifications),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Hello, ${user?.displayName ?? 'User'}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Switch(
                  value: _showOnlyPending,
                  onChanged: (value) {
                    setState(() {
                      _showOnlyPending = value;
                    });
                  },
                  activeTrackColor: Colors.blue.shade200,
                  activeColor: Colors.blue,
                  inactiveThumbColor: Colors.grey,
                  inactiveTrackColor: Colors.grey.shade300,
                ),
                const Text('Pending only'),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<ApprovalRequest>>(
              stream: _showOnlyPending
                  ? _databaseService.getPendingApprovalRequests()
                  : _databaseService.getApprovalRequests(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                final requests = snapshot.data ?? [];

                if (requests.isEmpty) {
                  return const Center(
                    child: Text(
                      'No approval requests found',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    final request = requests[index];
                    return RequestCard(
                      request: request,
                      onTap: () => _viewRequestDetails(request),
                      onApprove: _showOnlyPending
                          ? () async {
                              await _databaseService.updateApprovalStatus(
                                request.id,
                                ApprovalStatus.approved,
                              );
                            }
                          : null,
                      onReject: _showOnlyPending
                          ? () async {
                              await _databaseService.updateApprovalStatus(
                                request.id,
                                ApprovalStatus.rejected,
                              );
                            }
                          : null,
                    );
                  },
                );
              },
            ),
          ),
          // Version display footer
          const Padding(
            padding: EdgeInsets.only(bottom: 16.0, top: 8.0),
            child: VersionDisplay(),
          ),
        ],
      ),
    );
  }
} 