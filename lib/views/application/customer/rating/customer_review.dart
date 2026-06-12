import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../../viewmodels/application/customer_review_viewmodel.dart';
import 'manage_reviews.dart';

class ReviewPage extends StatelessWidget {
  final String stationId;
  final String stationName;
  final String stationDescription;
  final String stationImage;

  const ReviewPage({
    super.key,
    required this.stationId,
    required this.stationName,
    required this.stationDescription,
    required this.stationImage,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CustomerReviewViewModel()..loadCustomer(),
      child: _ReviewContent(
        stationId: stationId,
        stationName: stationName,
        stationDescription: stationDescription,
        stationImage: stationImage,
      ),
    );
  }
}

class _ReviewContent extends StatefulWidget {
  const _ReviewContent({
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
  State<_ReviewContent> createState() => _ReviewContentState();
}

class _ReviewContentState extends State<_ReviewContent> {
  final TextEditingController _reviewController = TextEditingController();

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    final viewModel = context.read<CustomerReviewViewModel>();
    final messenger = ScaffoldMessenger.of(context);
    final result = await viewModel.submitReview(widget.stationId);
    if (!mounted) return;

    switch (result) {
      case CustomerReviewSubmitResult.success:
        messenger.showSnackBar(
          const SnackBar(content: Text('Review submitted successfully!')),
        );
        _reviewController.clear();
        Navigator.pop(context);
      case CustomerReviewSubmitResult.missingRating:
      case CustomerReviewSubmitResult.customerNotFound:
      case CustomerReviewSubmitResult.failed:
        messenger.showSnackBar(
          SnackBar(
            content: Text(viewModel.errorMessage ?? 'Unable to submit review.'),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<CustomerReviewViewModel>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Review',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withValues(alpha: 0.1),
                      ),
                      child: const Icon(Icons.close, color: Colors.black),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          widget.stationImage,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 12),
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
                            const SizedBox(height: 2),
                            Text(
                              widget.stationDescription,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Row(
                              children: [
                                Icon(Icons.bolt, color: Colors.green, size: 18),
                                Text(
                                  ' Available ',
                                  style: TextStyle(fontSize: 14),
                                ),
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
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Share your experience:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.black12,
                          child: Icon(Icons.person, color: Colors.black),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          viewModel.username,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                    if (viewModel.isLoading)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: LinearProgressIndicator(),
                      ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return GestureDetector(
                          onTap: () => viewModel.updateRating(index + 1),
                          child: Icon(
                            index < viewModel.rating
                                ? Icons.star
                                : Icons.star_border,
                            color: Colors.amber,
                            size: 32,
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      maxLines: 4,
                      maxLength: 500,
                      controller: _reviewController,
                      decoration: InputDecoration(
                        hintText: 'Write your experience here (optional)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                      onChanged: viewModel.updateComment,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                children: [
                  ElevatedButton(
                    onPressed: viewModel.isSubmitting ? null : _submitReview,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: viewModel.isSubmitting
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'SUBMIT',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ManageReviewsPage(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.settings, color: Colors.blue),
                    label: const Text(
                      'Manage My Reviews',
                      style: TextStyle(fontSize: 16),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
