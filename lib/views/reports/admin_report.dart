import 'package:flutter/material.dart';

//import 'financial_performance_report.dart';
import 'charging_pile_utilization_report.dart';
import 'charging_usage_report.dart';
import 'complaint_resolution_report.dart';

class PrintReportScreen extends StatelessWidget {
  const PrintReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Select Report to Print")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildReportTile(
            context,
            "📊 Charging Usage Report",
            const ChargingUsageReport(),
          ),
          _buildReportTile(
            context,
            "🛠️ Complaint Resolution Report",
            const ComplaintResolutionReport(),
          ),
          //_buildReportTile(context, "💰 Financial Performance Report", FinancialPerformanceReport()),
          _buildReportTile(
            context,
            "🔌 Charging Pile Utilization Report",
            const ChargingPileUtilizationReport(),
          ),
        ],
      ),
    );
  }

  Widget _buildReportTile(
    BuildContext context,
    String title,
    Widget reportPage,
  ) {
    return Card(
      child: ListTile(
        title: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => reportPage),
        ),
      ),
    );
  }
}
