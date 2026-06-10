import 'package:flutter/material.dart';

import '../../../models/home_station_model.dart';
import 'home_station_card.dart';

class HomeStationSheet extends StatelessWidget {
  const HomeStationSheet({
    super.key,
    required this.searchController,
    required this.isLoading,
    required this.stations,
    required this.canReserve,
    required this.isBookmarked,
    required this.onSearchChanged,
    required this.onBookmarkPressed,
    required this.onReservePressed,
    required this.onViewChargersPressed,
  });

  final TextEditingController searchController;
  final bool isLoading;
  final List<HomeStation> stations;
  final bool canReserve;
  final bool Function(String stationId) isBookmarked;
  final ValueChanged<String> onSearchChanged;
  final Future<void> Function(HomeStation station) onBookmarkPressed;
  final ValueChanged<HomeStation> onReservePressed;
  final ValueChanged<HomeStation> onViewChargersPressed;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.15,
      minChildSize: 0.15,
      maxChildSize: 0.6,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(width: 40, height: 5, color: Colors.grey[400]),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: searchController,
                  onChanged: onSearchChanged,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: "SEARCH",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : stations.isEmpty
                    ? const Center(child: Text("No station found"))
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: stations.length,
                        itemBuilder: (context, index) {
                          final station = stations[index];
                          return HomeStationCard(
                            station: station,
                            isBookmarked: isBookmarked(station.stationId),
                            canReserve: canReserve,
                            onBookmarkPressed: () => onBookmarkPressed(station),
                            onReservePressed: () => onReservePressed(station),
                            onViewChargersPressed: () =>
                                onViewChargersPressed(station),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
