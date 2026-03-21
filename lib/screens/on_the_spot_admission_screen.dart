import 'package:flutter/material.dart';
import 'package:au_connect/theme/app_theme.dart';

class OnTheSpotAdmissionScreen extends StatelessWidget {
  const OnTheSpotAdmissionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('On-the-Spot Admission'),
        backgroundColor: isDark ? AppTheme.backgroundDark : null,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Upcoming Admission Events',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: [
                  _buildEventCard(
                    'On-the-Spot Admission Event',
                    'June 20, 2026',
                    'African University Campus',
                    '10:00 AM – 4:00 PM',
                    'Join us for instant admission decisions. Bring your documents and meet with faculty.',
                  ),
                  const SizedBox(height: 16),
                  _buildEventCard(
                    'Engineering Open Day',
                    'July 5, 2026',
                    'Engineering Building',
                    '9:00 AM – 3:00 PM',
                    'Explore engineering programs and speak with professors about admission requirements.',
                  ),
                  const SizedBox(height: 16),
                  _buildEventCard(
                    'Business School Information Session',
                    'July 12, 2026',
                    'Business Center',
                    '2:00 PM – 5:00 PM',
                    'Learn about business programs and MBA opportunities.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventCard(String title, String date, String location, String time, String description) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 20),
                const SizedBox(width: 8),
                Text(date),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on, size: 20),
                const SizedBox(width: 8),
                Text(location),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.access_time, size: 20),
                const SizedBox(width: 8),
                Text(time),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Register for event
              },
              child: const Text('Register for Event'),
            ),
          ],
        ),
      ),
    );
  }
}