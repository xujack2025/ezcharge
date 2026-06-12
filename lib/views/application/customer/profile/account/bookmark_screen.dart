import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../../models/profile_account_model.dart';
import '../../../../../../viewmodels/application/profile_bookmark_viewmodel.dart';
import '../../charging/charging_station_detail_screen.dart';

class BookmarkScreen extends StatelessWidget {
  const BookmarkScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProfileBookmarkViewModel()..loadBookmarks(),
      child: const _BookmarkContent(),
    );
  }
}

class _BookmarkContent extends StatelessWidget {
  const _BookmarkContent();

  Future<void> _removeBookmark(BuildContext context, String bookmarkId) async {
    final viewModel = context.read<ProfileBookmarkViewModel>();
    final result = await viewModel.removeBookmark(bookmarkId);
    if (!context.mounted) return;

    switch (result) {
      case ProfileBookmarkRemoveResult.success:
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Bookmark removed!')));
      case ProfileBookmarkRemoveResult.customerNotFound:
      case ProfileBookmarkRemoveResult.failed:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              viewModel.errorMessage ??
                  'Unable to remove bookmark. Please try again.',
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ProfileBookmarkViewModel>();

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        leading: IconButton(
          icon: Container(
            decoration: const BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(8),
            child: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Bookmark',
          style: TextStyle(
            color: Colors.black,
            fontSize: 25,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: viewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : viewModel.errorMessage != null
          ? Center(child: Text(viewModel.errorMessage!))
          : viewModel.stations.isEmpty
          ? const Center(child: Text('No bookmarked stations found!'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: viewModel.stations.length,
              itemBuilder: (context, index) {
                return _StationCard(
                  station: viewModel.stations[index],
                  onRemove: () => _removeBookmark(
                    context,
                    viewModel.stations[index].bookmarkId,
                  ),
                );
              },
            ),
    );
  }
}

class _StationCard extends StatelessWidget {
  const _StationCard({required this.station, required this.onRemove});

  final ProfileBookmarkStation station;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ChargingStationDetailScreen(stationId: station.stationId),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Colors.black, width: 1),
        ),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  station.imageUrl,
                  width: 100,
                  height: 80,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      station.stationName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      station.description,
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.bookmark, color: Colors.black),
                onPressed: onRemove,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
