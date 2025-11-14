import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class StatsCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final bool isMobile;

  const StatsCard({super.key, required this.user, this.isMobile = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Format the createdAt date
    final joinDate =
        user['createdAt'] != null ? _formatDate(user['createdAt']) : 'N/A';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.insights_outlined),
                const SizedBox(width: 12),
                Text(
                  'Activity Stats',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _StatItem(
              icon: Icons.assignment_outlined,
              label: 'Total Reports',
              value: user['totalReports']?.toString() ?? '31',
            ),
            const SizedBox(height: 12),
            _StatItem(
              icon: Icons.calendar_today_outlined,
              label: 'Member Since',
              value: joinDate,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(dynamic date) {
    try {
      // Handle different date formats - could be DateTime, String, or Timestamp
      if (date is DateTime) {
        return DateFormat('MMM d, y').format(date);
      } else if (date is String) {
        final parsedDate = DateTime.parse(date);
        return DateFormat('MMM d, y').format(parsedDate);
      } else if (date is int) {
        // Handle timestamp (seconds or milliseconds)
        final dateTime = DateTime.fromMillisecondsSinceEpoch(
            date > 10000000000 ? date : date * 1000);
        return DateFormat('MMM d, y').format(dateTime);
      }
      return 'N/A';
    } catch (e) {
      return 'N/A';
    }
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon,
            size: 20,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.7),
                    ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
