import 'package:flutter/material.dart';
import 'package:au_connect/theme/app_theme.dart';

class CollegeSearchScreen extends StatefulWidget {
  const CollegeSearchScreen({super.key});

  @override
  State<CollegeSearchScreen> createState() => _CollegeSearchScreenState();
}

class _CollegeSearchScreenState extends State<CollegeSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<Map<String, dynamic>> _colleges = [
    {
      'name': 'College of Engineering and Applied Science',
      'description': 'Programs in engineering, technology, and applied sciences',
      'programs': ['Computer Science', 'Mechanical Engineering', 'Electrical Engineering'],
    },
    {
      'name': 'College of Business',
      'description': 'Business administration, finance, and management programs',
      'programs': ['Business Administration', 'Finance', 'Marketing'],
    },
    {
      'name': 'College of Health Sciences',
      'description': 'Medical and health-related programs',
      'programs': ['Nursing', 'Pharmacy', 'Public Health'],
    },
    {
      'name': 'College of Arts and Humanities',
      'description': 'Liberal arts, social sciences, and humanities',
      'programs': ['Psychology', 'Sociology', 'Literature'],
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filteredColleges = _colleges.where((college) =>
        college['name'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
        college['description'].toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('College Search'),
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
                hintText: 'Search colleges or faculties...',
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
              'Search Results',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: filteredColleges.length,
                itemBuilder: (context, index) {
                  final college = filteredColleges[index];
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            college['name'],
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            college['description'],
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            children: (college['programs'] as List<String>).map((program) => Chip(label: Text(program))).toList(),
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