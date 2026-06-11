import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../../../../models/charging_checkout_model.dart';
import '../../../../viewmodels/charging/charging_payment_viewmodel.dart';
import '../profile/payment/payment_history_list.dart';

class ChargingPaymentHistoryDetailScreen extends StatelessWidget {
  const ChargingPaymentHistoryDetailScreen({
    super.key,
    required this.accountId,
    required this.paymentDocId,
  });

  final String accountId;
  final String paymentDocId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ChargingPaymentViewModel()
        ..loadPaymentHistoryDetail(
          accountId: accountId,
          paymentId: paymentDocId,
        ),
      child: Consumer<ChargingPaymentViewModel>(
        builder: (context, viewModel, _) {
          final detail = viewModel.historyDetail;
          final costStr = "-RM${(detail?.totalCost ?? 0).toStringAsFixed(2)}";
          final dateStr = detail?.paidTime == null
              ? ""
              : DateFormat('EEE MMM d, h:mma').format(detail!.paidTime!);

          return Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              leadingWidth: 60,
              leading: Padding(
                padding: const EdgeInsets.all(8),
                child: InkWell(
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PaymentHistoryListScreen(),
                      ),
                    );
                  },
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                ),
              ),
              title: const Text(
                "Payment History",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            backgroundColor: Colors.grey[200],
            body: viewModel.isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            costStr,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _infoRow(
                            "Charging Station:",
                            detail?.stationName ?? "",
                          ),
                          _infoRow("Charging Slot:", detail?.chargerName ?? ""),
                          _infoRow("Charger Type:", detail?.chargerType ?? ""),
                          _infoRow("Total Duration:", detail?.duration ?? ""),
                          const SizedBox(height: 8),
                          _infoRow("Paid By:", detail?.paymentMethod ?? ""),
                          _infoRow("Paid Time:", dateStr),
                          _infoRow("Payment ID:", detail?.paymentId ?? ""),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: detail == null
                                  ? null
                                  : () async {
                                      final pdf = _buildReceipt(
                                        detail,
                                        dateStr,
                                      );
                                      await Printing.layoutPdf(
                                        onLayout:
                                            (PdfPageFormat format) async =>
                                                pdf.save(),
                                      );
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                "PRINT",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          );
        },
      ),
    );
  }

  pw.Document _buildReceipt(
    ChargingPaymentHistoryDetail detail,
    String dateStr,
  ) {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text(
                  'Payment Receipt',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),
              _buildSectionTitle('Charging Details'),
              _buildInfoRow('Charging Station:', detail.stationName),
              _buildInfoRow('Charging Slot:', detail.chargerName),
              _buildInfoRow('Charger Type:', detail.chargerType),
              _buildInfoRow('Total Duration:', detail.duration),
              pw.SizedBox(height: 16),
              _buildSectionTitle('Payment Details'),
              _buildInfoRow('Paid By:', detail.paymentMethod),
              _buildInfoRow('Paid Time:', dateStr),
              _buildInfoRow('Payment ID:', detail.paymentId),
              pw.SizedBox(height: 16),
              _buildSectionTitle('Total Cost'),
              pw.Text(
                'RM${detail.totalCost.toStringAsFixed(2)}',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.red,
                ),
              ),
              pw.SizedBox(height: 30),
              pw.Divider(),
              pw.Center(
                child: pw.Text(
                  'Thank you for using our service!',
                  style: const pw.TextStyle(fontSize: 12),
                ),
              ),
            ],
          );
        },
      ),
    );
    return pdf;
  }

  pw.Widget _buildSectionTitle(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 18,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.black,
        ),
      ),
    );
  }

  pw.Widget _buildInfoRow(String label, String value) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Text(
            label,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
        ),
        pw.Expanded(flex: 2, child: pw.Text(value)),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 6),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }
}
