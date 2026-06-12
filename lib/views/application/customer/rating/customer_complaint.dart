import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../../viewmodels/application/customer_complaint_viewmodel.dart';
import 'manage_complaint.dart';

class CustomerComplaintPage extends StatelessWidget {
  final String stationId;
  final String stationName;
  final String stationDescription;
  final String stationImage;

  const CustomerComplaintPage({
    super.key,
    required this.stationId,
    required this.stationName,
    required this.stationDescription,
    required this.stationImage,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CustomerComplaintViewModel()..loadChargingBays(stationId),
      child: _CustomerComplaintContent(
        stationId: stationId,
        stationName: stationName,
        stationDescription: stationDescription,
        stationImage: stationImage,
      ),
    );
  }
}

class _CustomerComplaintContent extends StatefulWidget {
  const _CustomerComplaintContent({
    required this.stationId,
    required this.stationName,
    required this.stationDescription,
    required this.stationImage,
  });

  final String stationId;
  final String stationName;
  final String stationDescription;
  final String stationImage;

  @override
  State<_CustomerComplaintContent> createState() =>
      _CustomerComplaintContentState();
}

class _CustomerComplaintContentState extends State<_CustomerComplaintContent> {
  Future<void> _submitComplaint() async {
    final viewModel = context.read<CustomerComplaintViewModel>();
    final messenger = ScaffoldMessenger.of(context);
    final result = await viewModel.submitComplaint(stationId: widget.stationId);
    if (!mounted) return;

    switch (result) {
      case CustomerComplaintSubmitResult.success:
        messenger.showSnackBar(
          const SnackBar(content: Text('Complaint submitted successfully!')),
        );
        Navigator.pop(context);
      case CustomerComplaintSubmitResult.missingRequiredFields:
      case CustomerComplaintSubmitResult.customerNotFound:
      case CustomerComplaintSubmitResult.failed:
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              viewModel.errorMessage ?? 'Unable to submit complaint.',
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<CustomerComplaintViewModel>();
    final selectedImage = viewModel.selectedImage;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Report',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.blue,
                    ),
                    child: const Icon(Icons.close, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        widget.stationImage,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.stationName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            widget.stationDescription,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 5),
                          const Row(
                            children: [
                              Icon(Icons.bolt, color: Colors.green, size: 18),
                              Text(' Available '),
                              Icon(
                                Icons.ev_station,
                                color: Colors.black,
                                size: 18,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Location Bay *',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            DropdownButtonFormField<String>(
              initialValue: viewModel.selectedBayId,
              hint: viewModel.isLoading
                  ? const Text('Loading bays...')
                  : const Text('Select Bay'),
              items: viewModel.chargingBays.map((bay) {
                return DropdownMenuItem(
                  value: bay.chargerId,
                  child: Text(bay.chargerName),
                );
              }).toList(),
              onChanged: viewModel.isLoading ? null : viewModel.selectBay,
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            if (viewModel.errorMessage != null &&
                viewModel.chargingBays.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  viewModel.errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            const SizedBox(height: 15),
            const Text(
              'Report Reason *',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            DropdownButtonFormField<String>(
              initialValue: viewModel.reportReason,
              hint: const Text('Report Reason'),
              items: ['Charger not working', 'Blocked bay', 'Payment issue']
                  .map(
                    (reason) =>
                        DropdownMenuItem(value: reason, child: Text(reason)),
                  )
                  .toList(),
              onChanged: viewModel.selectReportReason,
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 15),
            const Text(
              'Details',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            TextField(
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Write your reason here (optional)',
                border: OutlineInputBorder(),
              ),
              onChanged: viewModel.updateDetails,
            ),
            const SizedBox(height: 15),
            const Text(
              'Upload Photo (Optional)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            GestureDetector(
              onTap: viewModel.pickImage,
              child: Container(
                height: 100,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: selectedImage == null
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.camera_alt, color: Colors.grey),
                            Text('Select Photo'),
                          ],
                        )
                      : Image.file(
                          selectedImage,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: viewModel.isSubmitting ? null : _submitComplaint,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: viewModel.isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'SUBMIT',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ManageComplaintsPage(),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  side: const BorderSide(color: Colors.blue),
                ),
                child: const Text(
                  'MANAGE COMPLAINTS',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
