import 'package:flutter/material.dart';
import 'package:au_connect/theme/app_theme.dart';
import 'package:au_connect/models/college_data.dart';

class CollegeDegreesScreen extends StatefulWidget {
  final College college;

  const CollegeDegreesScreen({super.key, required this.college});

  @override
  State<CollegeDegreesScreen> createState() => _CollegeDegreesScreenState();
}

class _CollegeDegreesScreenState extends State<CollegeDegreesScreen> {
  String _searchQuery = '';
  late List<Degree> _filteredDegrees;

  @override
  void initState() {
    super.initState();
    _filteredDegrees = widget.college.degrees;
  }

  void _filterDegrees(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredDegrees = widget.college.degrees;
      } else {
        _filteredDegrees = widget.college.degrees
            .where((degree) =>
                degree.name.toLowerCase().contains(query.toLowerCase()) ||
                degree.description.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.college.name} Degrees'),
        backgroundColor: isDark ? AppTheme.backgroundDark : null,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Available Degrees',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              onChanged: _filterDegrees,
              decoration: InputDecoration(
                hintText: 'Search degrees...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).cardColor,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _filteredDegrees.isEmpty
                  ? Center(
                      child: Text(
                        'No degrees found matching "$_searchQuery"',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filteredDegrees.length,
                      itemBuilder: (context, index) {
                        final degree = _filteredDegrees[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: _buildDegreeCard(degree),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDegreeCard(Degree degree) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              degree.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              degree.description,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Apply for degree
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Application started for ${degree.name}'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }
}