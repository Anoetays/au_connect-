class College {
  final String id;
  final String name;
  final String description;
  final List<Degree> degrees;

  const College({
    required this.id,
    required this.name,
    required this.description,
    required this.degrees,
  });
}

class Degree {
  final String id;
  final String name;
  final String description;

  const Degree({
    required this.id,
    required this.name,
    required this.description,
  });
}

class CollegeData {
  static final List<College> colleges = [
    College(
      id: 'engineering',
      name: 'College of Engineering and Applied Science',
      description: 'Programs in engineering, technology, and applied sciences',
      degrees: [
        Degree(
          id: 'cs',
          name: 'Computer Science',
          description: 'Study of computation, algorithms, and computer systems',
        ),
        Degree(
          id: 'se',
          name: 'Software Engineering',
          description: 'Design, development, and maintenance of software systems',
        ),
        Degree(
          id: 'me',
          name: 'Mechanical Engineering',
          description: 'Design and manufacturing of mechanical systems',
        ),
      ],
    ),
    College(
      id: 'business',
      name: 'College of Business Management',
      description: 'Business administration, finance, and management programs',
      degrees: [
        Degree(
          id: 'ba',
          name: 'Business Administration',
          description: 'Management and administration of business operations',
        ),
        Degree(
          id: 'finance',
          name: 'Finance',
          description: 'Financial planning, investment, and risk management',
        ),
        Degree(
          id: 'marketing',
          name: 'Marketing',
          description: 'Market research, advertising, and consumer behavior',
        ),
      ],
    ),
    College(
      id: 'health',
      name: 'College of Health Sciences',
      description: 'Medical and health-related programs',
      degrees: [
        Degree(
          id: 'mls',
          name: 'Medical Laboratory Sciences',
          description: 'Clinical laboratory testing and diagnostics',
        ),
        Degree(
          id: 'nursing',
          name: 'Nursing',
          description: 'Patient care and healthcare delivery',
        ),
        Degree(
          id: 'pharmacy',
          name: 'Pharmacy',
          description: 'Drug therapy and pharmaceutical care',
        ),
      ],
    ),
    College(
      id: 'agriculture',
      name: 'College of Agriculture and Natural Resources',
      description: 'Agricultural sciences and natural resource management',
      degrees: [
        Degree(
          id: 'agronomy',
          name: 'Agronomy',
          description: 'Crop production and soil management',
        ),
        Degree(
          id: 'forestry',
          name: 'Forestry',
          description: 'Forest management and conservation',
        ),
        Degree(
          id: 'env_sci',
          name: 'Environmental Science',
          description: 'Environmental protection and sustainability',
        ),
      ],
    ),
    College(
      id: 'social_science',
      name: 'College of Social Science, Theology, Education and Human Sciences',
      description: 'Social sciences, education, and human development programs',
      degrees: [
        Degree(
          id: 'psychology',
          name: 'Psychology',
          description: 'Study of human behavior and mental processes',
        ),
        Degree(
          id: 'education',
          name: 'Education',
          description: 'Teaching and learning methodologies',
        ),
        Degree(
          id: 'sociology',
          name: 'Sociology',
          description: 'Study of society and social institutions',
        ),
      ],
    ),
  ];

  static College? getCollegeById(String id) {
    return colleges.firstWhere((college) => college.id == id);
  }
}