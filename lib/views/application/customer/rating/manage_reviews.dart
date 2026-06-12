import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../../../models/customer_rating_model.dart';
import '../../../../../../viewmodels/application/manage_reviews_viewmodel.dart';

class ManageReviewsPage extends StatelessWidget {
  const ManageReviewsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ManageReviewsViewModel(),
      child: const _ManageReviewsContent(),
    );
  }
}

class _ManageReviewsContent extends StatelessWidget {
  const _ManageReviewsContent();

  void _editReview(BuildContext context, CustomerReview review) {
    final viewModel = context.read<ManageReviewsViewModel>();
    final messenger = ScaffoldMessenger.of(context);
    final reviewController = TextEditingController(text: review.reviewText);
    var newRating = review.rating.clamp(1, 5);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Edit Review'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: reviewController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Update your review',
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return GestureDetector(
                        onTap: () {
                          setDialogState(() => newRating = index + 1);
                        },
                        child: Icon(
                          index < newRating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 32,
                        ),
                      );
                    }),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final result = await viewModel.updateReview(
                      reviewId: review.reviewId,
                      reviewText: reviewController.text,
                      rating: newRating,
                    );
                    if (!dialogContext.mounted) return;
                    Navigator.pop(dialogContext);
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          result == ManageReviewActionResult.success
                              ? 'Review updated!'
                              : viewModel.errorMessage ??
                                    'Unable to update review.',
                        ),
                      ),
                    );
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    ).whenComplete(reviewController.dispose);
  }

  Future<void> _deleteReview(
    BuildContext context,
    CustomerReview review,
  ) async {
    final viewModel = context.read<ManageReviewsViewModel>();
    final messenger = ScaffoldMessenger.of(context);
    final result = await viewModel.deleteReview(review.reviewId);
    if (!context.mounted) return;

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          result == ManageReviewActionResult.success
              ? 'Review deleted!'
              : viewModel.errorMessage ?? 'Unable to delete review.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ManageReviewsViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage My Reviews'),
        elevation: 4,
        backgroundColor: Colors.blueAccent,
      ),
      body: StreamBuilder<List<CustomerReview>>(
        stream: viewModel.watchReviews(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                viewModel.errorMessage ?? 'Unable to load reviews.',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }

          final reviews = snapshot.data ?? const <CustomerReview>[];
          if (reviews.isEmpty) {
            return const Center(
              child: Text(
                'No reviews found.',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
            );
          }

          return ListView.builder(
            itemCount: reviews.length,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            itemBuilder: (context, index) {
              final review = reviews[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
                shadowColor: Colors.black26,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.shade100,
                    child: const Icon(Icons.rate_review, color: Colors.blue),
                  ),
                  title: Text(
                    review.reviewText.isEmpty ? 'No review' : review.reviewText,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Row(
                    children: [
                      _buildStars(review.rating),
                      const SizedBox(width: 10),
                      Text(
                        _formatDate(review.reviewDate),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _editReview(context, review);
                      } else if (value == 'delete') {
                        _deleteReview(context, review);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Text('Edit Review'),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete Review'),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'No date';
    return DateFormat('yyyy-MM-dd').format(date);
  }

  Widget _buildStars(int rating, {double size = 18}) {
    final safeRating = rating.clamp(0, 5);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Icon(
            index < safeRating ? Icons.star : Icons.star_border,
            color: Colors.amber,
            size: size,
          ),
        );
      }),
    );
  }
}
