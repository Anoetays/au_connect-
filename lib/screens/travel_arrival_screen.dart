import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:au_connect/theme/app_theme.dart';

class TravelArrivalScreenResult {
  final DateTime? arrivalDate;
  final bool airportPickupRequested;

  TravelArrivalScreenResult({
    required this.arrivalDate,
    required this.airportPickupRequested,
  });
}

class TravelArrivalScreen extends StatefulWidget {
  final DateTime? initialArrivalDate;
  final bool initialAirportPickupRequested;

  const TravelArrivalScreen({
    super.key,
    this.initialArrivalDate,
    this.initialAirportPickupRequested = false,
  });

  @override
  State<TravelArrivalScreen> createState() => _TravelArrivalScreenState();
}

class _TravelArrivalScreenState extends State<TravelArrivalScreen> {
  DateTime? _arrivalDate;
  bool _airportPickupRequested = false;

  @override
  void initState() {
    super.initState();
    _arrivalDate = widget.initialArrivalDate;
    _airportPickupRequested = widget.initialAirportPickupRequested;
  }

  Future<void> _pickArrivalDate() async {
    final now = DateTime.now();
    final result = await showDatePicker(
      context: context,
      initialDate: _arrivalDate ?? now.add(const Duration(days: 30)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (result != null) {
      setState(() {
        _arrivalDate = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Travel & Arrival'),
        backgroundColor: isDark ? AppTheme.backgroundDark : null,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Suggested Arrival Date',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _arrivalDate != null
                  ? '${_arrivalDate!.month}/${_arrivalDate!.day}/${_arrivalDate!.year}'
                  : 'Pick the date you plan to arrive',
              style: theme.textTheme.titleMedium?.copyWith(
                color: isDark ? Colors.grey[300] : const Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: _pickArrivalDate,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppTheme.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Choose Arrival Date'),
            ),
            const SizedBox(height: 24),
            _buildSectionCard(
              title: 'Airport Pickup',
              content:
                  'Request a pickup from the airport on your arrival date. Our team will be there to welcome you.',
              icon: Symbols.airplane_ticket,
              actionLabel: _airportPickupRequested ? 'Requested' : 'Request Airport Pickup',
              onAction: () {
                setState(() {
                  _airportPickupRequested = !_airportPickupRequested;
                });
              },
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              title: 'Accommodation Setup',
              content: 'Get help booking on-campus or off-campus housing before you arrive.',
              icon: Symbols.home_work,
              actionLabel: 'View Options',
              onAction: () {
                // Placeholder for navigation to accommodation info
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Accommodation setup coming soon.')),
                );
              },
            ),
            const SizedBox(height: 16),
            Text(
              'Map Preview',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Container(
              height: 160,
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Symbols.map, size: 52, color: AppTheme.primary.withOpacity(0.9)),
                    const SizedBox(height: 12),
                    Text(
                      'Map preview will appear here',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark ? Colors.grey[300] : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(
                    context,
                    TravelArrivalScreenResult(
                      arrivalDate: _arrivalDate,
                      airportPickupRequested: _airportPickupRequested,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Save and Return'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required String content,
    required IconData icon,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppTheme.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: onAction,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}
