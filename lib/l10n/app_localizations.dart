import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_sw.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
    Locale('pt'),
    Locale('sw'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'AU Connect'**
  String get appName;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome to AU Connect'**
  String get welcome;

  /// No description provided for @chooseLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose Your Language'**
  String get chooseLanguage;

  /// No description provided for @studentRole.
  ///
  /// In en, this message translates to:
  /// **'Student'**
  String get studentRole;

  /// No description provided for @applicantRole.
  ///
  /// In en, this message translates to:
  /// **'Applicant'**
  String get applicantRole;

  /// No description provided for @adminRole.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get adminRole;

  /// No description provided for @studentDesc.
  ///
  /// In en, this message translates to:
  /// **'Access courses, view grades, and get the latest campus updates.'**
  String get studentDesc;

  /// No description provided for @applicantDesc.
  ///
  /// In en, this message translates to:
  /// **'Track your application, submit documents, and check requirements.'**
  String get applicantDesc;

  /// No description provided for @adminDesc.
  ///
  /// In en, this message translates to:
  /// **'Manage campus systems, verify records, and oversee operations.'**
  String get adminDesc;

  /// No description provided for @selectYourRole.
  ///
  /// In en, this message translates to:
  /// **'Please select your role to continue.'**
  String get selectYourRole;

  /// No description provided for @mostCommon.
  ///
  /// In en, this message translates to:
  /// **'Most Common'**
  String get mostCommon;

  /// No description provided for @applicationPortal.
  ///
  /// In en, this message translates to:
  /// **'APPLICATION PORTAL'**
  String get applicationPortal;

  /// No description provided for @selectPathway.
  ///
  /// In en, this message translates to:
  /// **'SELECT YOUR PATHWAY'**
  String get selectPathway;

  /// No description provided for @chooseApplicantType.
  ///
  /// In en, this message translates to:
  /// **'Choose your applicant type to begin your journey with Africa University.'**
  String get chooseApplicantType;

  /// No description provided for @localApplicant.
  ///
  /// In en, this message translates to:
  /// **'Local Applicant'**
  String get localApplicant;

  /// No description provided for @zimbabweanCitizen.
  ///
  /// In en, this message translates to:
  /// **'Zimbabwean Citizen'**
  String get zimbabweanCitizen;

  /// No description provided for @localApplicantDesc.
  ///
  /// In en, this message translates to:
  /// **'Apply for undergraduate or diploma programmes as a Zimbabwean citizen.'**
  String get localApplicantDesc;

  /// No description provided for @international.
  ///
  /// In en, this message translates to:
  /// **'International'**
  String get international;

  /// No description provided for @usdFeesApply.
  ///
  /// In en, this message translates to:
  /// **'USD Fees Apply'**
  String get usdFeesApply;

  /// No description provided for @internationalDesc.
  ///
  /// In en, this message translates to:
  /// **'Students from outside Zimbabwe joining Africa University.'**
  String get internationalDesc;

  /// No description provided for @mastersPostgraduate.
  ///
  /// In en, this message translates to:
  /// **'Masters / Postgraduate'**
  String get mastersPostgraduate;

  /// No description provided for @researchTrack.
  ///
  /// In en, this message translates to:
  /// **'Research Track'**
  String get researchTrack;

  /// No description provided for @mastersDesc.
  ///
  /// In en, this message translates to:
  /// **'Masters, PhD, and other postgraduate degree programmes.'**
  String get mastersDesc;

  /// No description provided for @returningStudent.
  ///
  /// In en, this message translates to:
  /// **'Returning Student'**
  String get returningStudent;

  /// No description provided for @reAdmission.
  ///
  /// In en, this message translates to:
  /// **'Re-admission'**
  String get reAdmission;

  /// No description provided for @returningDesc.
  ///
  /// In en, this message translates to:
  /// **'Former AU student applying to resume studies after an absence.'**
  String get returningDesc;

  /// No description provided for @transferApplicant.
  ///
  /// In en, this message translates to:
  /// **'Transfer Applicant'**
  String get transferApplicant;

  /// No description provided for @creditTransfer.
  ///
  /// In en, this message translates to:
  /// **'Credit Transfer'**
  String get creditTransfer;

  /// No description provided for @transferDesc.
  ///
  /// In en, this message translates to:
  /// **'Currently enrolled elsewhere and transferring to Africa University.'**
  String get transferDesc;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get welcomeBack;

  /// No description provided for @signInToContinue.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue your application'**
  String get signInToContinue;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot?'**
  String get forgotPassword;

  /// No description provided for @rememberMe.
  ///
  /// In en, this message translates to:
  /// **'Remember me'**
  String get rememberMe;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @needHelp.
  ///
  /// In en, this message translates to:
  /// **'Need help?'**
  String get needHelp;

  /// No description provided for @contactAdmissions.
  ///
  /// In en, this message translates to:
  /// **'Contact Admissions Support'**
  String get contactAdmissions;

  /// No description provided for @resetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPassword;

  /// No description provided for @sendResetLink.
  ///
  /// In en, this message translates to:
  /// **'Send Reset Link'**
  String get sendResetLink;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @or.
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get or;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @confirmEmail.
  ///
  /// In en, this message translates to:
  /// **'Confirm Email Address'**
  String get confirmEmail;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @goodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get goodMorning;

  /// No description provided for @goodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get goodAfternoon;

  /// No description provided for @goodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get goodEvening;

  /// No description provided for @applicationProgress.
  ///
  /// In en, this message translates to:
  /// **'Application Progress'**
  String get applicationProgress;

  /// No description provided for @stepsCompleted.
  ///
  /// In en, this message translates to:
  /// **'steps completed'**
  String get stepsCompleted;

  /// No description provided for @continueApplication.
  ///
  /// In en, this message translates to:
  /// **'Continue Application'**
  String get continueApplication;

  /// No description provided for @startApplication.
  ///
  /// In en, this message translates to:
  /// **'Start Application'**
  String get startApplication;

  /// No description provided for @viewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get viewDetails;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @personalInformation.
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get personalInformation;

  /// No description provided for @selectProgramme.
  ///
  /// In en, this message translates to:
  /// **'Select Programme'**
  String get selectProgramme;

  /// No description provided for @documentUpload.
  ///
  /// In en, this message translates to:
  /// **'Document Upload'**
  String get documentUpload;

  /// No description provided for @reviewAndSubmit.
  ///
  /// In en, this message translates to:
  /// **'Review & Submit'**
  String get reviewAndSubmit;

  /// No description provided for @submitApplication.
  ///
  /// In en, this message translates to:
  /// **'Submit Application'**
  String get submitApplication;

  /// No description provided for @applicationStatus.
  ///
  /// In en, this message translates to:
  /// **'Application Status'**
  String get applicationStatus;

  /// No description provided for @documents.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get documents;

  /// No description provided for @uploadDocument.
  ///
  /// In en, this message translates to:
  /// **'Upload Document'**
  String get uploadDocument;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @saveAndContinue.
  ///
  /// In en, this message translates to:
  /// **'Save & Continue'**
  String get saveAndContinue;

  /// No description provided for @approved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get approved;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @denied.
  ///
  /// In en, this message translates to:
  /// **'Denied'**
  String get denied;

  /// No description provided for @underReview.
  ///
  /// In en, this message translates to:
  /// **'Under Review'**
  String get underReview;

  /// No description provided for @offerLetter.
  ///
  /// In en, this message translates to:
  /// **'Offer Letter'**
  String get offerLetter;

  /// No description provided for @downloadOfferLetter.
  ///
  /// In en, this message translates to:
  /// **'Download Offer Letter'**
  String get downloadOfferLetter;

  /// No description provided for @eligibilityCheck.
  ///
  /// In en, this message translates to:
  /// **'Eligibility Check'**
  String get eligibilityCheck;

  /// No description provided for @youQualify.
  ///
  /// In en, this message translates to:
  /// **'You meet the requirements for this programme'**
  String get youQualify;

  /// No description provided for @youDontQualify.
  ///
  /// In en, this message translates to:
  /// **'You do not meet the minimum requirements for this programme'**
  String get youDontQualify;

  /// No description provided for @suggestedProgrammes.
  ///
  /// In en, this message translates to:
  /// **'Programmes you qualify for'**
  String get suggestedProgrammes;

  /// No description provided for @selectThisInstead.
  ///
  /// In en, this message translates to:
  /// **'Select This Instead'**
  String get selectThisInstead;

  /// No description provided for @announcements.
  ///
  /// In en, this message translates to:
  /// **'Announcements'**
  String get announcements;

  /// No description provided for @noAnnouncements.
  ///
  /// In en, this message translates to:
  /// **'No announcements yet.'**
  String get noAnnouncements;

  /// No description provided for @loadingError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load your data. Pull down to retry.'**
  String get loadingError;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr', 'pt', 'sw'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
    case 'pt':
      return AppLocalizationsPt();
    case 'sw':
      return AppLocalizationsSw();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
