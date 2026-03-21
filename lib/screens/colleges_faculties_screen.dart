import 'package:flutter/material.dart';
import 'package:au_connect/theme/app_theme.dart';
import 'package:au_connect/models/college_data.dart';
import 'package:au_connect/screens/college_degrees_screen.dart';

class CollegesFacultiesScreen extends StatelessWidget {
  const CollegesFacultiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Colleges & Faculties'),
        backgroundColor: isDark ? AppTheme.backgroundDark : null,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Explore Our Colleges',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: CollegeData.colleges.length,
                itemBuilder: (context, index) {
                  final college = CollegeData.colleges[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: _buildCollegeCard(context, college),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCollegeCard(BuildContext context, College college) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              college.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              college.description,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => CollegeDegreesScreen(college: college)),
                );
              },
              child: const Text('View Degrees'),
            ),
          ],
        ),
      ),
    );
  }
}