# Quick Start: Admin Features

## 🔧 Setup (5 minutes)

### Step 1: Fix Supabase RLS
1. Open https://app.supabase.com/projects
2. Select your **au_connect** project
3. Go to **SQL Editor** → New Query
4. Copy entire contents of `SUPABASE_ADMIN_RLS_FIX.sql`
5. Click **Run** (Cmd+Enter or Ctrl+Enter)

### Step 2: Restart Backend
```powershell
Get-Process node -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Seconds 2
cd 'c:\Users\andre\Downloads\stitch\au_connect\server'
node server.js
```

### Step 3: Verify Endpoints Work
```powershell
# Should return JSON with statistics
curl http://localhost:3000/api/admin/dashboard

# Should return array of applications
curl http://localhost:3000/api/admin/applications?offset=0&limit=5
```

## 📱 Flutter Integration (5 minutes)

### Add to Navigation
In your main app file (where routes are defined):

```dart
import 'package:au_connect/screens/admin_applications_screen.dart';
import 'package:au_connect/screens/admin_stats_screen.dart';

// Add to routes:
routes: {
  '/admin/applications': (context) => const AdminApplicationsScreen(),
  '/admin/stats': (context) => const AdminStatsScreen(),
},
```

### Add Menu Items
```dart
// In admin dashboard
ListTile(
  icon: Icon(Icons.list),
  title: Text('Applications'),
  onTap: () => Navigator.pushNamed(context, '/admin/applications'),
),
ListTile(
  icon: Icon(Icons.bar_chart),
  title: Text('Dashboard & Reports'),
  onTap: () => Navigator.pushNamed(context, '/admin/stats'),
),
```

## 🧪 Quick Tests

### Test Dashboard Stats
```dart
import 'package:au_connect/services/admin_service.dart';

final stats = await AdminService.getDashboardStats();
print('Total: ${stats["totalApplications"]}');
print('By status: ${stats["statusBreakdown"]}');
```

### Test Applications List
```dart
final result = await AdminService.getApplicationsFiltered(
  offset: 0,
  limit: 20,
  status: 'pending',
);
print('Found: ${result["data"].length}');
print('Total: ${result["pagination"]["total"]}');
```

### Test Update Status
```dart
await AdminService.reviewApplication(
  appId: 1,
  status: 'approved',
  reviewNotes: 'All documents verified',
);
```

### Test Bulk Notification
```dart
await AdminService.sendBulkNotifications(
  recipientRole: 'applicant',
  type: 'announcement',
  title: 'Portal Maintenance',
  body: 'Portal will be down 2-4 AM tomorrow',
  filters: {'status': 'approved'},
);
```

## 📊 What You Get

| Feature | Location | What It Does |
|---------|----------|--------------|
| **Dashboard Stats** | `/admin/stats` | Shows total apps, status breakdown, by programme/nationality |
| **Applications List** | `/admin/applications` | Browse all apps, filter by status, paginate, quick actions |
| **Application Detail** | Tap any app | See full app + documents + history |
| **Update Status** | App detail page | Change status (pending→review→approved/rejected) |
| **Verify Documents** | App detail page | Check off documents as verified |
| **Send Notifications** | Bulk from dashboard | Send to specific admins/applicants |
| **Export Report** | /admin/stats | Download as CSV or JSON |

## ⚠️ Important Notes

1. **RLS Must Be Disabled**: Run the SQL fix FIRST
2. **Backend Must Run**: On port 3000
3. **Admin Role Required**: Only users with `role = 'admin'` should see these screens
4. **Service Role Only**: These endpoints use Supabase service role (backend only)

## 🆘 Troubleshooting

**Q: Admin screen shows "Error: 500"**
A: 
1. Check backend is running (`Get-Process node`)
2. Run Supabase SQL fix again
3. Restart backend: `Get-Process node | Stop-Process -Force`

**Q: No applications showing in list**
A: 
1. Make sure `applications` table has data
2. Check Supabase RLS is disabled
3. Try: `curl http://localhost:3000/api/admin/applications`

**Q: Dashboard stats show 0 everywhere**
A: 
1. Add test data to applications table
2. Refresh page
3. Check backend logs for errors

## 📝 Example: Complete Admin Workflow

```dart
// 1. Load dashboard stats
final dashboard = await AdminService.getDashboardStats();
// Shows: 150 total, 45 pending, 80 approved, 25 rejected

// 2. Get pending applications
final pending = await AdminService.getApplicationsFiltered(
  status: 'pending',
  limit: 20,
);
// Shows 10 pending apps

// 3. Review an application
final appId = pending['data'][0]['id'];
await AdminService.reviewApplication(
  appId: appId,
  status: 'approved',
  reviewNotes: 'All required documents verified',
);
// Applicant gets notification: "Your app was approved!"

// 4. Send bulk notification to approved applicants
await AdminService.sendBulkNotifications(
  recipientRole: 'applicant',
  type: 'next_steps',
  title: 'Next Steps in Your Application',
  body: 'You have been approved. Next step: complete visa application at...',
  filters: {'status': 'approved'},
);
```

---

**Ready?** Start with Step 1 (Fix RLS), then add the routes, then test!
