import 'package:flutter/material.dart';

const Color kCrimson = Color(0xFFB22234);
const Color kCrimsonDark = Color(0xFF8B1A27);
const Color kCrimsonLight = Color(0xFFD94F5C);
const Color kCrimsonMuted = Color(0xFFF5E6E8);
const Color kBackground = Color(0xFFFBF8F8);
const Color kTextDark = Color(0xFF1A0A0C);
const Color kTextMid = Color(0xFF5A3A3E);
const Color kTextLight = Color(0xFF9A7A7E);
const Color kBorder = Color(0xFFE8D5D7);

const Map<String, Map<String, String>> kGreetings = {
  'English': {'hello': 'Hello!', 'welcome': 'Welcome to AU Connect'},
  'French': {'hello': 'Bonjour!', 'welcome': 'Bienvenue sur AU Connect'},
  'Portuguese': {'hello': 'Ola!', 'welcome': 'Bem-vindo ao AU Connect'},
  'Swahili': {'hello': 'Habari!', 'welcome': 'Karibu kwenye AU Connect'},
};

const Map<String, Map<String, String>> kNameLabels = {
  'English': {
    'title': "What's your preferred name?",
    'sub': 'Enter your name in English',
    'label': 'Your name',
  },
  'French': {
    'title': 'Quel est votre prenom?',
    'sub': 'Entrez votre prenom en francais',
    'label': 'Votre prenom',
  },
  'Portuguese': {
    'title': 'Qual e o seu nome?',
    'sub': 'Digite seu nome em portugues',
    'label': 'Seu nome',
  },
  'Swahili': {
    'title': 'Jina lako ni nani?',
    'sub': 'Weka jina lako kwa Kiswahili',
    'label': 'Jina lako',
  },
};

const Map<String, Map<String, dynamic>> kProgrammes = {
  'Technology': {
    'programmes': [
      'Computer Science',
      'Artificial Intelligence',
      'Software Engineering',
      'Computer Information Systems',
      'Information Technology'
    ],
    'requirement':
        'At least 2 A-Level passes in science subjects (Mathematics, Physics, Chemistry, or Computer Science).',
    'aLevelMsg':
        'Do you have at least 2 A-Level passes in science subjects (e.g. Maths, Physics, Chemistry)?',
  },
  'HealthScience': {
    'programmes': [
      'Medical Laboratory Science',
      'Agriscience',
      'Animal Science',
      'Social Work',
      'Public Health',
      'Nursing'
    ],
    'requirement':
        'At least 2 A-Level passes in health science subjects (Biology, Chemistry, or related).',
    'aLevelMsg':
        'Do you have at least 2 A-Level passes in health science subjects (e.g. Biology, Chemistry)?',
  },
  'Business': {
    'programmes': [
      'Accounting',
      'Business Management',
      'Agribusiness',
      'Economics',
      'Marketing',
      'Human Resource Management'
    ],
    'requirement':
        'At least 2 A-Level passes in commercial subjects (Accounting, Business Studies, Economics, or Maths).',
    'aLevelMsg':
        'Do you have at least 2 A-Level passes in commercial subjects (e.g. Accounting, Economics, Business)?',
  },
  'Theology': {
    'programmes': [
      'Divinity',
      'Theology',
      'Hebrew Studies',
      'Greek Studies',
      'Biblical Studies',
      'Religious Education'
    ],
    'requirement':
        'At least 2 A-Level passes including at least one theology-related subject.',
    'aLevelMsg':
        'Do you have at least 2 A-Level passes including a theology-related subject?',
  },
};
