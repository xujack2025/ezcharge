import 'package:ezcharge/models/home_station_model.dart';
import 'package:ezcharge/services/home_service.dart';
import 'package:ezcharge/viewmodels/application/home_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeHomeService implements HomeServiceContract {
  FakeHomeService({this.stations = const []});

  final List<HomeStation> stations;
  final Map<String, BookmarkStatus> bookmarkStatuses = {};
  int fetchStationsCallCount = 0;
  String? addedStationId;
  String? removedBookmarkId;

  @override
  Future<List<HomeStation>> fetchStations() async {
    fetchStationsCallCount++;
    return stations;
  }

  @override
  Future<BookmarkStatus> getBookmarkStatus({
    required String customerId,
    required String stationId,
  }) async {
    return bookmarkStatuses[stationId] ??
        const BookmarkStatus(isBookmarked: false);
  }

  @override
  Future<BookmarkStatus> addBookmark({
    required String customerId,
    required String stationId,
  }) async {
    addedStationId = stationId;
    final status = BookmarkStatus(
      isBookmarked: true,
      bookmarkId: "bookmark-$stationId",
    );
    bookmarkStatuses[stationId] = status;
    return status;
  }

  @override
  Future<void> removeBookmark({
    required String customerId,
    required String bookmarkId,
  }) async {
    removedBookmarkId = bookmarkId;
  }
}

void main() {
  const acStation = HomeStation(
    stationId: "STT1",
    stationName: "Alpha Station",
    description: "Near mall",
    capacity: 4,
    nearby: "Mall",
    imageUrl: "https://example.com/alpha.png",
    currentTypes: ["AC"],
    latitude: 3.1,
    longitude: 101.1,
  );

  const dcStation = HomeStation(
    stationId: "STT2",
    stationName: "Beta Station",
    description: "Near office",
    capacity: 2,
    nearby: ["Office", "Cafe"],
    imageUrl: "https://example.com/beta.png",
    currentTypes: ["DC"],
    latitude: 3.2,
    longitude: 101.2,
  );

  group('HomeViewModel', () {
    test('loads stations from service', () async {
      final service = FakeHomeService(stations: [acStation, dcStation]);
      final viewModel = HomeViewModel(homeService: service);

      await viewModel.loadStations();

      expect(service.fetchStationsCallCount, 1);
      expect(viewModel.isLoading, isFalse);
      expect(viewModel.errorMessage, isNull);
      expect(viewModel.stations, [acStation, dcStation]);
      expect(viewModel.filteredStations, [acStation, dcStation]);
    });

    test('filters stations by search query and keeps first match', () async {
      final service = FakeHomeService(stations: [acStation, dcStation]);
      final viewModel = HomeViewModel(homeService: service);

      await viewModel.loadStations();
      viewModel.filterStations('station');

      expect(viewModel.filteredStations, [acStation]);
    });

    test('applies power and nearby filters', () async {
      final service = FakeHomeService(stations: [acStation, dcStation]);
      final viewModel = HomeViewModel(homeService: service);

      await viewModel.loadStations();
      viewModel.applyFilters('DC', ['Cafe']);

      expect(viewModel.filteredStations, [dcStation]);
    });

    test('adds bookmark and exposes bookmark state', () async {
      final service = FakeHomeService(stations: [acStation]);
      final viewModel = HomeViewModel(homeService: service);

      await viewModel.loadStations();
      final added = await viewModel.toggleBookmark(
        customerId: 'CUS1',
        station: acStation,
      );

      expect(added, isTrue);
      expect(service.addedStationId, acStation.stationId);
      expect(viewModel.isBookmarked(acStation.stationId), isTrue);
    });

    test('removes bookmark when station is already bookmarked', () async {
      final service = FakeHomeService(stations: [acStation]);
      service.bookmarkStatuses[acStation.stationId] = const BookmarkStatus(
        isBookmarked: true,
        bookmarkId: 'BKK1',
      );
      final viewModel = HomeViewModel(homeService: service);

      await viewModel.loadStations(customerId: 'CUS1');
      final added = await viewModel.toggleBookmark(
        customerId: 'CUS1',
        station: acStation,
      );

      expect(added, isFalse);
      expect(service.removedBookmarkId, 'BKK1');
      expect(viewModel.isBookmarked(acStation.stationId), isFalse);
    });
  });
}
