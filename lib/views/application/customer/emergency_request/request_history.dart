import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../models/emergency_request_model.dart';
import '../../../../viewmodels/emergency_request_viewmodel.dart';

class RequestHistoryScreen extends StatelessWidget {
  const RequestHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => EmergencyRequestViewModel()..loadCurrentCustomerId(),
      child: Consumer<EmergencyRequestViewModel>(
        builder: (context, viewModel, _) {
          return Scaffold(
            appBar: AppBar(title: const Text("Request History")),
            body: viewModel.isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildBody(viewModel),
          );
        },
      ),
    );
  }

  Widget _buildBody(EmergencyRequestViewModel viewModel) {
    final customerId = viewModel.customerId;
    if (customerId == null || customerId.isEmpty) {
      return const Center(child: Text("Error: No Customer ID found."));
    }

    return StreamBuilder<List<EmergencyRequest>>(
      stream: viewModel.getRequests(customerId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final requests = snapshot.data!;
        if (requests.isEmpty) {
          return const Center(child: Text("No past requests found."));
        }

        return ListView.builder(
          itemCount: requests.length,
          itemBuilder: (context, index) {
            return _RequestHistoryCard(request: requests[index]);
          },
        );
      },
    );
  }
}

class _RequestHistoryCard extends StatelessWidget {
  const _RequestHistoryCard({required this.request});

  final EmergencyRequest request;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      child: ExpansionTile(
        key: PageStorageKey(request.requestID),
        initiallyExpanded: true,
        title: Text("Status: ${request.status}"),
        subtitle: Text("Location: ${request.address}"),
        trailing: Text(request.preferredTime),
        children: [
          ListTile(title: Text("Booking Reason: ${request.bookingReason}")),
          if (request.status == "Completed") ...[
            ListTile(
              title: Text(
                "Charging Time: ${request.chargingFormattedTime.isEmpty ? '00:00:00' : request.chargingFormattedTime}",
              ),
            ),
            ListTile(
              title: Text(
                "Total Cost: ${request.totalCost == null ? 'N/A' : 'RM ${request.totalCost!.toStringAsFixed(2)}'}",
              ),
            ),
            if (request.imageUrl != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Image.network(
                  request.imageUrl!,
                  errorBuilder: (context, error, stackTrace) {
                    return const Text("Image Not Available");
                  },
                ),
              ),
          ] else ...[
            ListTile(
              title: Text(
                "Driver Assigned: ${request.driverID?.isNotEmpty == true ? request.driverID : 'Not Assigned'}",
              ),
            ),
          ],
        ],
      ),
    );
  }
}
