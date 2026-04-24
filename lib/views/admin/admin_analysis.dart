import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:ezcharge/views/admin/admin_dashboard.dart';

class AdminAnalyticsPage extends StatefulWidget {
  const AdminAnalyticsPage({super.key});

  @override
  State<AdminAnalyticsPage> createState() => _AdminAnalyticsPageState();
}

class _AdminAnalyticsPageState extends State<AdminAnalyticsPage>
    with SingleTickerProviderStateMixin {
  Map<int, int> hourlyUsage = {}; // Stores peak hour data
  String dateRange = ""; // Stores formatted date range (e.g., "7-13 Mar 2025")
  TabController? _tabController;
  int _expandedUserSection = 0;

  @override
  void initState() {
    super.initState();
    generateDateRange(); // Generate last 7 days' range
    listenForChargingSessions(); // Listen for live updates from Firestore
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  /// **Generates the last 7 days' date range in "7-13 Mar 2025" format**
  void generateDateRange() {
    DateTime today = DateTime.now();
    DateTime startDate = today.subtract(const Duration(days: 6)); // 7 days ago
    DateTime endDate = today; // Today

    DateFormat dayFormat = DateFormat('d'); // Only day (e.g., 7)
    DateFormat monthYearFormat = DateFormat(
      'MMM yyyy',
    ); // Month and Year (e.g., Mar 2025)

    setState(() {
      dateRange =
          "${dayFormat.format(startDate)}-${dayFormat.format(endDate)} ${monthYearFormat.format(endDate)}";
    });
  }

  /// **Listens for real-time Firestore updates**
  void listenForChargingSessions() {
    FirebaseFirestore.instance
        .collection('attendance')
        .where(
          'CheckInTime',
          isGreaterThan: Timestamp.fromDate(
            DateTime.now().subtract(const Duration(days: 7)),
          ),
        ) // Last 7 days
        .snapshots()
        .listen((snapshot) {
          Map<int, int> tempHourlyUsage = {
            for (int i = 0; i < 24; i++) i: 0,
          }; // Initialize all 24 hours with 0

          for (var doc in snapshot.docs) {
            var docData = doc.data();
            if (!(docData).containsKey('CheckInTime')) {
              continue;
            }

            Timestamp? checkInTimestamp = doc['CheckInTime'];
            if (checkInTimestamp == null) continue; // Skip if timestamp is null

            DateTime storedTime = checkInTimestamp
                .toDate(); // Retrieved Firebase time (misinterpreted as UTC)
            DateTime adjustedTime =
                storedTime /*.add(const Duration(hours: 8))*/; // Manually adjust by +8 hours

            debugPrint(
              "Firebase Stored Time: $storedTime | Corrected Local Time: $adjustedTime",
            );

            int hour = adjustedTime.hour;
            tempHourlyUsage[hour] = (tempHourlyUsage[hour] ?? 0) + 1;
          }

          if (mounted) {
            setState(() {
              hourlyUsage = tempHourlyUsage;
            });
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3, // Three Tabs
      child: Scaffold(
        appBar: AppBar(
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(18.0),
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.blueAccent,
              labelColor: Colors.blueAccent,
              unselectedLabelColor: Colors.black54,
              tabs: const [
                Tab(icon: Icon(Icons.timeline), text: "Peak Hours"),
                Tab(icon: Icon(Icons.ev_station), text: "Charging Stations"),
                Tab(icon: Icon(Icons.person), text: "User Behavior"),
              ],
            ),
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildPeakHourAnalysis(), // Peak Hour Analysis Tab
            _buildChargingStationOverview(), // Charging Station Tab
            _buildUserBehaviorAnalysis(), // User Behavior Tab
          ],
        ),
      ),
    );
  }

  /// **1️⃣ Peak Hour Analysis Tab**
  Widget _buildPeakHourAnalysis() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // **Title**
          const Center(
            child: Text(
              "📈 Peak Hour Charging Sessions",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 5),

          // **Display Date Range**
          Center(
            child: Text(
              dateRange,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 10),

          // **Line Chart**
          SizedBox(
            height: 350, // Better height for visibility
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: hourlyUsage.isEmpty
                  ? const Center(
                      child: Text(
                        "No data available for the past 7 days.",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  : LineChart(
                      LineChartData(
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: true,
                          getDrawingHorizontalLine: (value) {
                            return FlLine(
                              color: Colors.grey[300]!,
                              strokeWidth: 0.8, // Thicker for better visibility
                            );
                          },
                          getDrawingVerticalLine: (value) {
                            return FlLine(
                              color: Colors.grey[300]!,
                              strokeWidth: 0.5, // Subtle vertical grid lines
                            );
                          },
                        ),
                        titlesData: FlTitlesData(
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: false, // Hides the top labels
                            ),
                          ),
                          leftTitles: const AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: false, // Hides the labels
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 32,
                              interval: 4, // Show label every 4 hours
                              getTitlesWidget: (double value, TitleMeta meta) {
                                int displayHour = value.toInt();
                                return Text(
                                  "${displayHour}h",
                                  // Display local time correctly
                                  style: const TextStyle(fontSize: 12),
                                );
                              },
                            ),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: false, // Hides the labels
                            ),
                          ),
                        ),
                        borderData: FlBorderData(
                          show: true,
                          border: Border.all(color: Colors.grey, width: 1),
                        ),
                        minX: 0,
                        // Start from 0 hours
                        maxX: 23,
                        // End at 23 hours
                        minY: 0,
                        maxY: hourlyUsage.values.isNotEmpty
                            ? (hourlyUsage.values.reduce(
                                        (a, b) => a > b ? a : b,
                                      ) +
                                      1)
                                  .toDouble()
                            : 10,
                        lineBarsData: [
                          LineChartBarData(
                            spots: hourlyUsage.entries
                                .map(
                                  (entry) => FlSpot(
                                    entry.key.toDouble(),
                                    entry.value.toDouble(),
                                  ),
                                )
                                .toList(),
                            isCurved: true,
                            curveSmoothness: 0.3,
                            color: Colors.blueAccent,
                            gradient: LinearGradient(
                              colors: [
                                Colors.blueAccent,
                                Colors.lightBlueAccent,
                              ], // 🔹 Apply gradient
                            ),
                            barWidth: 4,
                            isStrokeCapRound: true,
                            belowBarData: BarAreaData(
                              show: true,
                              gradient: LinearGradient(
                                colors: [
                                  Colors.blueAccent.withOpacity(0.4),
                                  Colors.transparent,
                                ], // 🔹 Gradient for below the line
                                stops: [0.1, 1.0],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                            dotData: FlDotData(
                              show: true,
                              getDotPainter: (spot, percent, barData, index) =>
                                  FlDotCirclePainter(
                                    radius: 4,
                                    color: Colors.blueAccent,
                                    strokeWidth: 1.5,
                                    strokeColor: Colors.white,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  /// **2️⃣ Charging Station Overview Tab**
  Widget _buildChargingStationOverview() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('station').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        var stations = snapshot.data!.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .toList();

        return stations.isEmpty
            ? const Center(
                child: Text(
                  "No charging stations available.",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              )
            : ListView.builder(
                itemCount: stations.length,
                itemBuilder: (context, index) {
                  var station = stations[index];
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(
                      vertical: 5,
                      horizontal: 10,
                    ),
                    child: ListTile(
                      title: Text(
                        station["StationName"],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        "Status: ${station["CapacityStatus"]}",
                        style: TextStyle(
                          color: station["CapacityStatus"] == "Overloaded"
                              ? Colors.red
                              : station["CapacityStatus"] == "Undefined"
                              ? Colors.grey
                              : station["CapacityStatus"] == "High Demand"
                              ? Colors.orange
                              : Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const AdminDashboard(initialIndex: 3),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
      },
    );
  }

  /// **User Behavior Analytics Page**
  Widget _buildUserBehaviorAnalysis() {
    return CustomScrollView(
      slivers: [
        _buildExpandableSectionHeaderSliver(
          index: 0,
          title: "📍 Most Frequently Visited Stations",
        ),
        if (_expandedUserSection == 0)
          SliverToBoxAdapter(
            child: SizedBox(height: 200, child: _buildTopStationsChart()),
          ),
        _buildExpandableSectionHeaderSliver(
          index: 1,
          title: "📅 Recent Charging Sessions",
        ),
        if (_expandedUserSection == 1) _buildRecentSessionsSliver(),
        _buildExpandableSectionHeaderSliver(
          index: 2,
          title: "🔌 Most Used Chargers",
        ),
        if (_expandedUserSection == 2)
          SliverToBoxAdapter(
            child: SizedBox(height: 200, child: _buildMostUsedChargersChart()),
          ),
        _buildExpandableSectionHeaderSliver(
          index: 3,
          title: "📄 Charger Usage Details",
        ),
        if (_expandedUserSection == 3) _buildChargerUsageSliver(),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
      ],
    );
  }

  SliverToBoxAdapter _buildExpandableSectionHeaderSliver({
    required int index,
    required String title,
  }) {
    final bool isExpanded = _expandedUserSection == index;

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          elevation: 1,
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () {
              setState(() {
                _expandedUserSection = isExpanded ? -1 : index;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.keyboard_arrow_down),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// **1️⃣ Most Used Chargers (Bar Chart)**
  Widget _buildMostUsedChargersChart() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('attendance').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        // Count charger usage
        Map<String, int> chargerCounts = {};
        for (var doc in snapshot.data!.docs) {
          var data = doc.data() as Map<String, dynamic>;
          String chargerId = data["SlotID"] ?? "Unknown";
          chargerCounts[chargerId] = (chargerCounts[chargerId] ?? 0) + 1;
        }

        // Sort chargers by usage (Top 5)
        var sortedChargers = chargerCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        sortedChargers = sortedChargers.take(5).toList();

        return BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: sortedChargers.isNotEmpty
                ? sortedChargers.first.value.toDouble() + 5
                : 10,
            barGroups: sortedChargers.map((entry) {
              return BarChartGroupData(
                x: sortedChargers.indexOf(entry),
                barRods: [
                  BarChartRodData(
                    toY: entry.value.toDouble(),
                    color: Colors.green,
                    width: 20,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              );
            }).toList(),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (double value, TitleMeta meta) {
                    return Text(
                      sortedChargers[value.toInt()].key,
                      style: const TextStyle(fontSize: 10),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// **3️⃣ Charger Usage Details (SliverList)**
  Widget _buildChargerUsageSliver() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('attendance').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        // **🔥 Count each SlotID usage**
        Map<String, Map<String, dynamic>> chargerData = {};

        for (var doc in snapshot.data!.docs) {
          var data = doc.data() as Map<String, dynamic>;
          String slotID = data["SlotID"] ?? "Unknown";
          String currentType = data["CurrentType"] ?? "Unknown"; // "AC" or "DC"
          double chargerVoltage =
              double.tryParse(data["ChargerVoltage"].toString()) ?? 0.0;

          // 🔥 If SlotID already exists, increase count & add kWh usage
          if (chargerData.containsKey(slotID)) {
            chargerData[slotID]!["UsageCount"] += 1;
            chargerData[slotID]!["ChargerVoltage"] += chargerVoltage;
          } else {
            // 🔥 Initialize SlotID if it doesn't exist
            chargerData[slotID] = {
              "ChargerID": slotID,
              "UsageCount": 1,
              "ChargerVoltage": chargerVoltage,
              "CurrentType": currentType,
            };
          }
        }

        // **🔥 Convert Map to List & Sort by Usage Count**
        List<Map<String, dynamic>> chargers = chargerData.values.toList();
        chargers.sort((a, b) => b["UsageCount"].compareTo(a["UsageCount"]));

        if (chargers.isEmpty) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(
                "No charger usage records.",
                style: TextStyle(color: Colors.grey),
              ),
            ),
          );
        }

        // Converted from ListView.builder -> SliverList to keep a single viewport.
        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              var charger = chargers[index];

              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 5),
                child: ListTile(
                  leading: Icon(
                    charger["CurrentType"] == "AC"
                        ? Icons.power
                        : Icons.flash_on,
                    color: charger["CurrentType"] == "AC"
                        ? Colors.blue
                        : Colors.orange,
                  ),
                  title: Text("Charger: ${charger["ChargerID"]}"),
                  subtitle: Text("Usage: ${charger["UsageCount"]} times"),
                  trailing: Text(
                    "⚡ ${charger["ChargerVoltage"].toStringAsFixed(1)} kWh",
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              );
            }, childCount: chargers.length),
          ),
        );
      },
    );
  }

  /// **1️⃣ Top 5 Most Visited Charging Stations (Bar Chart)**
  Widget _buildTopStationsChart() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('attendance').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        // Count station visits
        Map<String, int> stationCounts = {};
        for (var doc in snapshot.data!.docs) {
          var data = doc.data() as Map<String, dynamic>;
          String stationName = data["StationID"] ?? "Unknown";
          stationCounts[stationName] = (stationCounts[stationName] ?? 0) + 1;
        }

        // Sort stations by usage (Top 5)
        var sortedStations = stationCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        sortedStations = sortedStations.take(5).toList();

        return BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: sortedStations.isNotEmpty
                ? sortedStations.first.value.toDouble() + 5
                : 10,
            barGroups: sortedStations.map((entry) {
              return BarChartGroupData(
                x: sortedStations.indexOf(entry),
                barRods: [
                  BarChartRodData(
                    toY: entry.value.toDouble(),
                    color: Colors.blueAccent,
                    width: 20,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              );
            }).toList(),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (double value, TitleMeta meta) {
                    return Text(
                      sortedStations[value.toInt()].key,
                      style: const TextStyle(fontSize: 10),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// **3️⃣ Recent Charging Sessions (SliverList)**
  Widget _buildRecentSessionsSliver() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('attendance')
          .orderBy("CheckInTime", descending: true)
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        var sessions = snapshot.data!.docs;

        if (sessions.isEmpty) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(
                "No recent charging sessions.",
                style: TextStyle(color: Colors.grey),
              ),
            ),
          );
        }

        // Converted from ListView.builder -> SliverList to avoid nested scroll conflicts.
        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              var session = sessions[index].data() as Map<String, dynamic>;

              String stationName = session["StationID"] ?? "Unknown Station";
              String durationString =
                  session["Duration"] ?? "0:00:00"; // Default if missing

              // Convert Duration String to Minutes.
              int durationMinutes = _convertDurationToMinutes(durationString);

              Timestamp? timestamp = session["CheckInTime"];
              String formattedTime = timestamp != null
                  ? DateTime.fromMillisecondsSinceEpoch(
                      timestamp.millisecondsSinceEpoch,
                    ).toLocal().toString()
                  : "N/A";

              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 5),
                child: ListTile(
                  leading: const Icon(Icons.ev_station, color: Colors.blue),
                  title: Text("Station: $stationName"),
                  subtitle: Text(
                    "Duration: $durationMinutes mins",
                    style: const TextStyle(color: Colors.grey),
                  ),
                  trailing: Text(
                    formattedTime,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              );
            }, childCount: sessions.length),
          ),
        );
      },
    );
  }

  /// **Helper Function: Convert `"HH:MM:SS"` to Minutes**
  int _convertDurationToMinutes(String duration) {
    try {
      List<String> parts = duration.split(":");
      int hours = int.parse(parts[0]);
      int minutes = int.parse(parts[1]);
      return (hours * 60) + minutes; // Convert hours to minutes and add
    } catch (e) {
      debugPrint("Error parsing duration: $e");
      return 0; // Default to 0 if parsing fails
    }
  }
}
