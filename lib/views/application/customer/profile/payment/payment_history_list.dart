import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../../models/profile_payment_card_model.dart';
import '../../../../../viewmodels/application/payment_history_viewmodel.dart';
import '../../charging/charging_payment_history_detail_screen.dart';

class PaymentHistoryListScreen extends StatelessWidget {
  const PaymentHistoryListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PaymentHistoryViewModel()..loadPaymentHistory(),
      child: const _PaymentHistoryContent(),
    );
  }
}

class _PaymentHistoryContent extends StatelessWidget {
  const _PaymentHistoryContent();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<PaymentHistoryViewModel>();

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leadingWidth: 60,
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: InkWell(
            onTap: () => Navigator.pop(context),
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
          'Payment History',
          style: TextStyle(
            color: Colors.black,
            fontSize: 25,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: _PaymentHistoryBody(viewModel: viewModel),
    );
  }
}

class _PaymentHistoryBody extends StatelessWidget {
  const _PaymentHistoryBody({required this.viewModel});

  final PaymentHistoryViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    if (viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final errorMessage = viewModel.errorMessage;
    if (errorMessage != null) {
      return Center(child: Text(errorMessage));
    }

    if (viewModel.items.isEmpty) {
      return const Center(child: Text('No payment history found.'));
    }

    return ListView.builder(
      itemCount: viewModel.items.length,
      itemBuilder: (context, index) {
        return _PaymentHistoryTile(
          accountId: viewModel.customerId,
          item: viewModel.items[index],
        );
      },
    );
  }
}

class _PaymentHistoryTile extends StatelessWidget {
  const _PaymentHistoryTile({required this.accountId, required this.item});

  final String accountId;
  final ProfilePaymentHistoryItem item;

  @override
  Widget build(BuildContext context) {
    final dateStr = item.paidTime != null
        ? DateFormat('EEE MMM d, h:mma').format(item.paidTime!)
        : '';
    final costStr = '-RM${item.totalCost.toStringAsFixed(2)}';

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChargingPaymentHistoryDetailScreen(
              accountId: accountId,
              paymentDocId: item.paymentId,
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade300,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  dateStr,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  costStr,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6),
                Text(item.stationName, style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 4),
                Text(
                  '${item.chargerName} | ${item.chargerType}',
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  'Duration: ${item.duration} • ${item.paymentMethod}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
