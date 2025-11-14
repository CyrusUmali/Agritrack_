import 'package:flutter/material.dart';
import 'package:flareline/pages/products/profile_widgets/detail_row.dart';

class KeyDetailsCard extends StatelessWidget {
  final Map<String, dynamic> product;

  const KeyDetailsCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Key Details',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            DetailRow(
                label: 'Category',
                value: product['category'],
                context: context),
            DetailRow(
                label: 'Sector', value: product['sector'], context: context),
            DetailRow(
                label: 'Market Value',
                value: product['marketValue'],
                context: context),
            DetailRow(
                label: 'Primary Region',
                value: product['region'],
                context: context),
            DetailRow(
                label: 'Seasonality',
                value: product['seasonality'],
                context: context),
          ],
        ),
      ),
    );
  }
}
