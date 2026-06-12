import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../../../models/customer_rating_model.dart';
import '../../../../../../viewmodels/application/manage_complaints_viewmodel.dart';

class ManageComplaintsPage extends StatelessWidget {
  const ManageComplaintsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ManageComplaintsViewModel(),
      child: const _ManageComplaintsContent(),
    );
  }
}

class _ManageComplaintsContent extends StatelessWidget {
  const _ManageComplaintsContent();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ManageComplaintsViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage My Complaints'),
        elevation: 4,
        backgroundColor: Colors.blueAccent,
      ),
      body: StreamBuilder<List<CustomerComplaint>>(
        stream: viewModel.watchComplaints(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                viewModel.errorMessage ?? 'Unable to load complaints.',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }

          final complaints = snapshot.data ?? const <CustomerComplaint>[];
          if (complaints.isEmpty) {
            return const Center(
              child: Text(
                'No complaints found.',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
            );
          }

          return ListView.builder(
            itemCount: complaints.length,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            itemBuilder: (context, index) {
              final complaint = complaints[index];
              return Hero(
                tag: complaint.documentId,
                child: Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 5,
                  shadowColor: Colors.black26,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        colors: [
                          _getStatusBackgroundColor(complaint.status),
                          Colors.white,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: CircleAvatar(
                        backgroundColor: _getStatusColor(complaint.status),
                        child: Icon(
                          _getStatusIcon(complaint.status),
                          color: Colors.white,
                        ),
                      ),
                      title: Text(
                        complaint.reason.isEmpty
                            ? 'No reason provided'
                            : complaint.reason,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            'Status: ${complaint.status}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _getStatusColor(complaint.status),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Date: ${_formatDate(complaint.complaintDate)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        size: 18,
                        color: Colors.black54,
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ComplaintDetailScreen(complaint: complaint),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'resolved':
        return Colors.green;
      case 'in progress':
        return Colors.orange;
      default:
        return Colors.red;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'resolved':
        return Icons.check_circle;
      case 'in progress':
        return Icons.sync;
      default:
        return Icons.hourglass_empty;
    }
  }

  Color _getStatusBackgroundColor(String status) {
    switch (status.toLowerCase()) {
      case 'resolved':
        return Colors.green.shade100;
      case 'in progress':
        return Colors.blue.shade100;
      default:
        return Colors.yellow.shade100;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'No date';
    return DateFormat('yyyy-MM-dd').format(date);
  }
}

class ComplaintDetailScreen extends StatelessWidget {
  final CustomerComplaint complaint;

  const ComplaintDetailScreen({super.key, required this.complaint});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complaint Details'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: complaint.documentId,
              child: Material(
                color: Colors.transparent,
                child: Text(
                  complaint.reason.isEmpty
                      ? 'No reason provided'
                      : complaint.reason,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Description: ${complaint.description.isEmpty ? 'No description provided' : complaint.description}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 10),
            Text(
              'Status: ${complaint.status}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Date: ${complaint.complaintDate == null ? 'No date' : DateFormat('yyyy-MM-dd').format(complaint.complaintDate!)}',
              style: const TextStyle(fontSize: 16, color: Colors.black54),
            ),
            if (complaint.chargerBay.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                'Bay: ${complaint.chargerBay}',
                style: const TextStyle(fontSize: 16, color: Colors.black54),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
