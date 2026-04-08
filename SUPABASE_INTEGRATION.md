# AU Connect: Supabase Integration Guide

## ✅ COMPLETED

### 1. Database Schema (SQL Migration)
File: `supabase/migrations/20260405_init_schema.sql`

**Tables Created:**
- `profiles` - User account info (id, email, full_name, role)
- `applications` - Applicant form data (user_id, all form fields, status)

**Features:**
- Automatic profile creation on sign-up via trigger
- RLS (Row Level Security) policies for data isolation
- Admin access to view all submitted applications
- Automatic timestamp management (created_at, updated_at)

**To Apply the Migration:**
1. Go to Supabase Dashboard → SQL Editor
2. Copy the entire contents of `supabase/migrations/20260405_init_schema.sql`
3. Paste and run in the SQL Editor
4. Verify: Check the Tables section - you should see `profiles` and `applications`

---

### 2. Services Updated

#### AuthService (`lib/services/auth_service.dart`)
- ✅ `signUpWithEmailAndPassword()` - Creates auth account + profile
- ✅ `signInWithEmailAndPassword()` - Real Supabase auth
- ✅ `getUserRole()` - Fetch user role from profiles table
- ✅ `isEmailVerified` - Check email verification status
- ✅ `signOut()` - Proper session cleanup

#### OnboardingApplicationService (NEW)
File: `lib/services/onboarding_application_service.dart`
- `getOrCreateApplication()` - Ensures user has application record
- `saveField()` - Save single form field to Supabase
- `saveFields()` - Save multiple fields at once
- `getApplication()` - Fetch saved application data
- `submitApplication()` - Set status to 'submitted'

#### OnboardingController (UPDATED)
File: `lib/screens/onboarding/onboarding_controller.dart`
- ✅ `savePersonalInfo()` - Save first_name, last_name, email, phone
- ✅ `saveCountry()` - Save country selection
- ✅ `saveLanguage()` - Save language preference
- ✅ `saveName()` - Save preferred name
- ✅ `saveGender()` - Save gender
- ✅ `saveDOB()` - Save date of birth
- ✅ `saveStudyLevel()` - Save study level
- ✅ `saveFieldOfStudy()` - Save field of study
- ✅ `saveProgramme()` - Save programme selection
- ✅ `saveALevelQualified()` - Save A-level status
- ✅ `saveAcademicInfo()` - Save school & grades
- ✅ `saveFinancing()` - Save financing option
- ✅ `saveAccommodation()` - Save accommodation choice
- ✅ `saveDisability()` - Save disability info
- ✅ `saveNextOfKin()` - Save next of kin info
- ✅ `savePaymentMethod()` - Save payment method
- ✅ `loadSavedData()` - Fetch and populate form from Supabase
- ✅ `doRegister()` - Real auth sign-up (UPDATED)
- ✅ `doSubmit()` - Real submission to Supabase (UPDATED)

---

## 🔧 INTEGRATION STEPS

### Step 1: Initialize Supabase Table Structure
```sql
-- Run in Supabase → SQL Editor
-- See: supabase/migrations/20260405_init_schema.sql
```

### Step 2: Update Registration Screen
File: `lib/screens/onboarding/register_screen.dart`

In the `PrimaryButton` onTap:
```dart
PrimaryButton(
  label: 'Create Account & Continue →',
  onTap: () => c.doRegister(context), // Already calls real auth!
),
```

### Step 3: Update Each Step Screen to Save Data

**Gender Screen** - After state update, save:
```dart
InkWell(
  onTap: () {
    c.state.gender = 'Female';
    c.saveGender(); // ADD THIS
    c.refresh();
  },
  ...
)
```

**Country Screen** - After selection:
```dart
CountryChip(
  ...
  onTap: () {
    c.state.country = item.$3;
    c.saveCountry(); // ADD THIS
    c.refresh();
  },
)
```

**Pattern for ALL fields:**
```dart
// After updating state field:
await c.saveSomeField(); // one of the save methods
c.refresh(); // refresh UI
```

### Step 4: Update Review Screen to Load Data
File: `lib/screens/onboarding/review_screen.dart`

In the build method (before returning content):
```dart
@override
Widget build(BuildContext context) {
  final c = OnboardingScope.of(context);
  
  // Load data from Supabase on first build
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    if (!c.isLoading) {
      try {
        await c.loadSavedData();
      } catch (e) {
        debugPrint('Error loading saved data: $e');
      }
    }
  });

  return OnboardingShell(
    footer: c.isLoading
        ? const Center(child: CircularProgressIndicator())
        : PrimaryButton(
            label: '✅ Confirm & Submit Application',
            onTap: () => c.doSubmit(context),
          ),
    child: c.isLoading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            // ... display review data (already populated by loadSavedData)
          ),
  );
}
```

### Step 5: Update Login Screen
File: `lib/screens/applicant_sign_in_screen.dart`

Add real authentication:
```dart
Future<void> _signIn() async {
  final email = emailController.text.trim();
  final password = passwordController.text;

  if (email.isEmpty || password.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Enter email and password')),
    );
    return;
  }

  setState(() => _isLoading = true);

  try {
    final authService = AuthService();
    final response = await authService.signInWithEmailAndPassword(
      email,
      password,
    );

    if (!response.user!.emailConfirmedAt != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please check your email to verify your account'),
        ),
      );
      setState(() => _isLoading = false);
      return;
    }

    // Navigate to dashboard (you may need role-based routing)
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/onboarding_dashboard');
    }
  } on AuthException catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Login failed: ${e.message}')),
    );
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}
```

### Step 6: Query Admin Dashboard
File: `lib/screens/admin_dashboard_screen.dart`

Add method to fetch submitted applications:
```dart
Future<void> _loadApplications() async {
  try {
    final response = await Supabase.instance.client
        .from('applications')
        .select()
        .eq('status', 'submitted')
        .order('created_at', ascending: false);
    
    setState(() => _applications = response as List<Map<String, dynamic>>);
  } catch (e) {
    debugPrint('Error loading applications: $e');
  }
}

// In build, display:
ListView.builder(
  itemCount: _applications.length,
  itemBuilder: (context, index) {
    final app = _applications[index];
    return ListTile(
      title: Text(app['first_name'] + ' ' + app['last_name']),
      subtitle: Text('Programme: ${app['programme']}'),
      trailing: Text(app['status']),
    );
  },
)
```

---

## 🔐 Authentication Flow

### Sign Up (New User)
1. User fills email & password → Click "Create Account"
2. `doRegister()` calls `authService.signUpWithEmailAndPassword()`
3. Supabase Auth creates user account
4. Trigger auto-creates profile in `profiles` table with role='applicant'
5. Trigger auto-creates empty row in `applications` table
6. User receives confirmation email
7. User must verify email before login succeeds

### Login (Existing User)
1. User enters email & password → Click "Sign In"
2. `authService.signInWithEmailAndPassword()` called
3. Verify email is confirmed (`emailConfirmedAt != null`)
4. Fetch user role from `profiles` table
5. Route to appropriate dashboard:
   - Role='applicant' → Onboarding or Applicant Dashboard
   - Role='admin' → Admin Dashboard

### Logout
1. Call `authService.signOut()`
2. Session cleared
3. Redirect to login screen

---

## 📋 Database Schema Quick Reference

### profiles table
```
id (UUID primary key, references auth.users)
email (TEXT, unique)
full_name (TEXT)
role (TEXT: 'applicant' | 'admin' | 'staff')
created_at (TIMESTAMP)
updated_at (TIMESTAMP)
```

### applications table
```
id (UUID primary key)
user_id (UUID, references auth.users, unique per user)
first_name, last_name, preferred_name (TEXT)
email, phone (TEXT)
country, language (TEXT)
gender, date_of_birth (TEXT)
study_level, field_of_study, programme (TEXT)
school_attended, grades (TEXT)
financing, accommodation (TEXT)
disability, disability_detail (TEXT)
kin_name, kin_relationship, kin_phone (TEXT)
payment_method (TEXT)
certificate_file_name (TEXT)
a_level_qualified (BOOLEAN)
status (TEXT: 'draft' | 'submitted' | 'reviewed' | 'approved' | 'rejected')
application_type (TEXT: 'local' | 'international' | 'postgraduate' | 'transfer')
created_at, updated_at (TIMESTAMP)
```

---

## 🧪 Testing Checklist

- [ ] SQL migration applied successfully
- [ ] New user can sign up with email/password
- [ ] Confirmation email is sent
- [ ] User can log in after email verification
- [ ] Form data persists when navigating between steps
- [ ] Form data loads correctly on Review screen
- [ ] Admin can view submitted applications
- [ ] User profile created automatically on sign-up
- [ ] RLS policies prevent cross-user data access

---

## ⚠️ Important Notes

1. **Email Verification**: Supabase sends verification emails by default. You may need to configure email provider in Supabase settings.
2. **RLS Policies**: Data is automatically isolated per user via Row Level Security.
3. **UPSERT Pattern**: All saves use upsert to prevent duplicates during navigation.
4. **Role-Based Access**: Admin role must be set via Supabase dashboard (roles=admin table).
5. **Frontend Auth State**: Use `StreamBuilder(stream: authService.user)` to react to auth changes.

---

## 🚀 Next Steps (Optional Enhancements)

1. Add role-based routing (redirect based on user role)
2. Add session persistence (restore session on app restart)
3. Add password reset flow
4. Add file upload for documents (certificates)
5. Add email templates customization
6. Add audit logging for admin actions
7. Add payment integration for application fees
