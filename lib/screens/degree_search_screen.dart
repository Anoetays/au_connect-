import 'package:flutter/material.dart';
import 'package:au_connect/theme/app_theme.dart';

class DegreeSearchScreen extends StatefulWidget {
  const DegreeSearchScreen({super.key});

  @override
  State<DegreeSearchScreen> createState() => _DegreeSearchScreenState();
}

class _DegreeSearchScreenState extends State<DegreeSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<Map<String, dynamic>> _degrees = [
    {
      'title': 'Computer Science',
      'description': 'Study programming, algorithms, and software development',
      'college': 'College of Engineering and Applied Science',
    },
    {
      'title': 'Business Administration',
      'description': 'Learn management, finance, and entrepreneurial skills',
      'college': 'College of Business',
    },
    {
      'title': 'Nursing',
      'description': 'Prepare for a career in healthcare and patient care',
      'college': 'College of Health Sciences',
    },
    {
      'title': 'Psychology',
      'description': 'Explore human behavior and mental processes',
      'college': 'College of Arts and Humanities',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filteredDegrees = _degrees.where((degree) =>
        degree['title'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
        degree['description'].toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Degree Search'),
        backgroundColor: isDark ? AppTheme.backgroundDark : null,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search degrees (e.g., Computer Science, Nursing)...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
            const SizedBox(height: 20),
            Text(
              'Available Degrees',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: filteredDegrees.length,
                itemBuilder: (context, index) {
                  final degree = filteredDegrees[index];
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            degree['title'],
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            degree['description'],
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'College: ${degree['college']}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    // Apply for degree
                                  },
                                  child: const Text('Apply for this degree'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    // Save or compare
                                  },
                                  child: const Text('Save/Compare'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}