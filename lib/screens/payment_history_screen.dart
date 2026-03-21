import 'package:flutter/material.dart';
import 'package:au_connect/models/payment_status.dart';

class PaymentHistoryScreen extends StatelessWidget {
  const PaymentHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final history = PaymentData.paymentHistory;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment History'),
      ),
      body: history.isEmpty
          ? const Center(
              child: Text(
                'No payment activity yet.',
                style: TextStyle(fontSize: 16),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: history.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final record = history[index];
                return Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              record.txRef,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: record.status.color.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                record.status.displayName,
                                style: TextStyle(
                                  color: record.status.color,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('Method: ${record.method.name}'),
                        const SizedBox(height: 4),
                        Text('Amount: \$${record.amount.toStringAsFixed(2)}'),
                        const SizedBox(height: 4),
                        Text('Date: ${record.createdAt}'),
                        if (record.note != null && record.note!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text('Note: ${record.note}'),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
