import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../viewmodels/charging/charging_review_viewmodel.dart';

class ChargingReviewScreen extends StatefulWidget {
  final String stationId;
  final String stationName;
  final String stationDescription;
  final String stationImage;

  const ChargingReviewScreen({
    super.key,
    required this.stationId,
    required this.stationName,
    required this.stationDescription,
    required this.stationImage,
  });

  @override
  State<ChargingReviewScreen> createState() => _ChargingReviewScreenState();
}

class _ChargingReviewScreenState extends State<ChargingReviewScreen> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ChargingReviewViewModel()..loadUser(),
      child: Consumer<ChargingReviewViewModel>(
        builder: (context, viewModel, _) {
          return Scaffold(
            backgroundColor: Colors.white,
            body: Column(
              children: [
                // Top App Bar
                Padding(
                  padding: const EdgeInsets.only(top: 40, left: 20, right: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Review",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
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
                ),

                // Station Details Card
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Row(
                        children: [
                          /*ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        widget.stationImage,
                        width: 10,
                        height: 10,
                        fit: BoxFit.cover,
                      ),
                    ),*/
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
                                    Icon(
                                      Icons.bolt,
                                      color: Colors.green,
                                      size: 18,
                                    ),
                                    Text(" Available "),
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

                // Review Input Fields
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Kindly tell us the reason you are reporting this bay:",
                          style: TextStyle(fontSize: 16),
                        ),

                        // User Info
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

                        // Star Rating
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(5, (index) {
                            return IconButton(
                              icon: Icon(
                                index < viewModel.rating
                                    ? Icons.star
                                    : Icons.star_border,
                                color: Colors.amber,
                                size: 30,
                              ),
                              onPressed: () {
                                viewModel.updateRating(index + 1);
                              },
                            );
                          }),
                        ),
                        const SizedBox(height: 10),

                        // Comment Box
                        TextField(
                          maxLines: 4,
                          maxLength: 500,
                          decoration: InputDecoration(
                            hintText: "Write your experience here (optional)",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onChanged: viewModel.updateComment,
                        ),
                      ],
                    ),
                  ),
                ),
                // Submit Button
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: ElevatedButton(
                    onPressed: viewModel.isSubmitting
                        ? null
                        : () => _submitReview(context, viewModel),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: viewModel.isSubmitting
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            "SUBMIT",
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _submitReview(
    BuildContext context,
    ChargingReviewViewModel viewModel,
  ) async {
    final result = await viewModel.submitReview(widget.stationId);
    if (!context.mounted) return;

    switch (result) {
      case ChargingReviewSubmitResult.success:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Review submitted successfully!")),
        );
        Navigator.pop(context);
        return;
      case ChargingReviewSubmitResult.missingRating:
      case ChargingReviewSubmitResult.userNotFound:
      case ChargingReviewSubmitResult.failed:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              viewModel.errorMessage ?? "Review submission failed. Try again!",
            ),
          ),
        );
    }
  }
}
