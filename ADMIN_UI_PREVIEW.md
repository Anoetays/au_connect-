# Admin Dashboard UI Preview

## Admin Applications Screen

### Desktop View (Table)
```
┌─────────────────────────────────────────────────────────────────────────────┐
│ Applications Management          [All Applications ▼]                       │
├─────────────────────────────────────────────────────────────────────────────┤
│ Applicant  │ Programme   │ Type          │ Status    │ Submitted │ Actions │
├────────────┼─────────────┼───────────────┼───────────┼───────────┼─────────┤
│ John Doe   │ Engineering │ Local         │ PENDING   │ Apr 5     │ ⋮       │
│ Jane Smith │ Medicine    │ International │ APPROVED  │ Apr 4     │ ⋮       │
│ Bob Wilson │ Business    │ Local         │ REJECTED  │ Apr 3     │ ⋮       │
│ Alice Lee  │ Law         │ International │ REVIEW    │ Apr 2     │ ⋮       │
│ Carlos Rey │ Engineering │ Master        │ PENDING   │ Apr 1     │ ⋮       │
├────────────┴─────────────┴───────────────┴───────────┴───────────┴─────────┤
│ Previous                    Page 1 of 8                              Next   │
└─────────────────────────────────────────────────────────────────────────────┘
```

**Filter Dropdown Options**:
- All Applications
- Pending
- Under Review
- Approved
- Rejected

**Action Menu (⋮)**:
- Move to Review
- Approve
- Reject

### Mobile View (Cards)
```
┌─────────────────────────────────┐
│ Applications Management [⋮]     │
├─────────────────────────────────┤
│ ┌───────────────────────────┐   │
│ │ John Doe                  │   │
│ │ Engineering • Local       │   │
│ │ Submitted: 2026-04-05    │   │
│ └───────────────────────────┘   │
│ ┌───────────────────────────┐   │
│ │ Jane Smith                │   │
│ │ Medicine • International  │   │
│ │ Submitted: 2026-04-04    │   │
│ └───────────────────────────┘   │
│ ┌───────────────────────────┐   │
│ │ Bob Wilson                │   │
│ │ Business • Local          │   │
│ │ Submitted: 2026-04-03    │   │
│ └───────────────────────────┘   │
└─────────────────────────────────┘
```

---

## Admin Stats & Dashboard Screen

### Key Metrics (Top Section)
```
┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│ 📊           │  │ ⏳           │  │ ✅           │  │ ❌           │
│              │  │              │  │              │  │              │
│     156      │  │      45      │  │      89      │  │      22      │
│              │  │              │  │              │  │              │
│   TOTAL      │  │   PENDING    │  │   APPROVED   │  │   REJECTED   │
│ APPLICATIONS │  │              │  │              │  │              │
└──────────────┘  └──────────────┘  └──────────────┘  └──────────────┘
```

### Status Breakdown
```
APPROVED    ████████████████████████░░░ 57.1%  (89 apps)
PENDING     ███████████░░░░░░░░░░░░░░░░ 28.8%  (45 apps)
REJECTED    ██░░░░░░░░░░░░░░░░░░░░░░░░ 14.1%  (22 apps)
```

### By Programme
```
┌─────────────────┬────────────┐
│ Programme       │ Count      │
├─────────────────┼────────────┤
│ Engineering     │ 52 (33%)   │
│ Business        │ 48 (31%)   │
│ Medicine        │ 38 (24%)   │
│ Law             │ 18 (12%)   │
└─────────────────┴────────────┘
```

### By Nationality (Top 10)
```
┌─────────────────┬────────────┐
│ Country         │ Count      │
├─────────────────┼────────────┤
│ Zimbabwe        │ 120 (77%)  │
│ South Africa    │ 18 (12%)   │
│ Nigeria         │ 8 (5%)     │
│ Kenya           │ 5 (3%)     │
│ Botswana        │ 3 (2%)     │
└─────────────────┴────────────┘
```

---

## Application Detail View (When Tapped)

```
┌─────────────────────────────────────────────────────────────────────────┐
│ Application Detail: John Doe                          [← Back]         │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│ Applicant Information                                                   │
│ ─────────────────────────────────────────────────────────────────────  │
│ Name: John Doe                                                          │
│ Email: john@email.com                                                   │
│ Phone: +263712345678                                                    │
│ Nationality: Zimbabwe                                                   │
│ Submitted: Apr 5, 2026 10:30 AM                                        │
│                                                                         │
│ Application Details                                                     │
│ ─────────────────────────────────────────────────────────────────────  │
│ Programme: Engineering                                                  │
│ Type: Local                                                             │
│ Status: PENDING                                                         │
│ Current Status: [Update ▼]                                             │
│                                                                         │
│ Documents                                                               │
│ ─────────────────────────────────────────────────────────────────────  │
│ ✓ passport.pdf                                    [VERIFIED]           │
│ ✓ transcript.pdf                                  [VERIFIED]           │
│ ✓ recommendation_letter.pdf                       [VERIFIED]           │
│ ✗ medical_report.pdf                              [REJECTED]  [Re-upload]
│                                                                         │
│ Admin Notes                                                             │
│ ─────────────────────────────────────────────────────────────────────  │
│ [Review Notes...                                                    ]   │
│                                                                         │
│ [Approve]  [Move to Review]  [Reject]                                 │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Bulk Notification Screen

```
┌─────────────────────────────────────────────────┐
│ Send Bulk Notification                         │
├─────────────────────────────────────────────────┤
│                                                 │
│ Send To:                                        │
│ ◉ All Admins                                    │
│ ○ Filtered Applicants                           │
│                                                 │
│ Type:                                           │
│ [announcement                           ▼]     │
│                                                 │
│ Subject:                                        │
│ [Application Portal Update                  ]   │
│                                                 │
│ Message:                                        │
│ [Portal will be down for maintenance      ]     │
│ [tomorrow night 2-4 AM for updates.       ]     │
│ [                                         ]     │
│ [                                         ]     │
│                                                 │
│ Filters (if sending to Applicants):             │
│ Programme: [All ▼]                              │
│ Status:    [All ▼]                              │
│                                                 │
│ Preview: Will send to 156 applicants            │
│                                                 │
│ [Cancel]  [Send Notification]                  │
│                                                 │
└─────────────────────────────────────────────────┘
```

---

## Export Report Dialog

```
┌─────────────────────────────────────────────────┐
│ Export Applications Report                      │
├─────────────────────────────────────────────────┤
│                                                 │
│ Format:                                         │
│ ◉ CSV (Excel)                                   │
│ ○ JSON (API)                                    │
│                                                 │
│ Filters:                                        │
│ Status:    [All ▼]                              │
│ Programme: [All ▼]                              │
│                                                 │
│ Records: 156 applications                       │
│                                                 │
│ [Cancel]  [Download Report]                    │
│                                                 │
│ File: applications_export_20260406.csv          │
│                                                 │
└─────────────────────────────────────────────────┘
```

---

## Notification Example (Sent to Applicant)

```
┌────────────────────────────────────┐
│ Application Status Updated         │
├────────────────────────────────────┤
│                                    │
│ Your application has been          │
│ APPROVED ✓                         │
│                                    │
│ You have been approved for         │
│ Engineering programme!             │
│                                    │
│ Next Steps:                        │
│ 1. Complete visa application       │
│ 2. Schedule medical examination    │
│ 3. Pay accommodation deposit       │
│                                    │
│ Thank you,                         │
│ AU Connect Admin Team             │
│                                    │
│ [View Details]  [Dismiss]          │
│                                    │
└────────────────────────────────────┘
```

---

## Data Flow

```
Admin Opens App
    ↓
[User must be role = 'admin']
    ↓
[Admin Dashboard]
    ├─→ GET /api/admin/dashboard
    │   └─→ Loads statistics (total, by status, by programme, by nationality)
    │
    ├─→ GET /api/admin/applications
    │   └─→ Loads paginated applications list
    │
    ├─→ Click Application
    │   └─→ GET /api/admin/applications/:appId
    │       └─→ Loads detail + documents
    │
    ├─→ Update Status
    │   └─→ POST /api/admin/applications/:appId/review
    │       ├─→ Updates database
    │       └─→ Sends notification to applicant
    │
    ├─→ Verify Document
    │   └─→ POST /api/admin/documents/:docId/verify
    │       └─→ Marks document verified
    │
    ├─→ Send Bulk Notification
    │   └─→ POST /api/admin/notifications/bulk
    │       └─→ Creates notification for multiple users
    │
    └─→ Export Report
        └─→ GET /api/admin/reports/export?format=csv
            └─→ Downloads Excel file
```

---

## Color Scheme

**Status Colors**:
- **Pending**: 🟨 Amber (#FFC107)
- **Approved**: 🟢 Green (#4CAF50)
- **Rejected**: 🔴 Red (#F44336)
- **Under Review**: 🔵 Blue (#2196F3)

**General Colors**:
- **Text**: #1B1C1E (Dark)
- **Muted**: #757575 (Gray)
- **Border**: rgba(185, 28, 28, 0.13)
- **Background**: #F9F9F9

---

## Accessibility Notes

✓ All buttons have clear labels
✓ Status indicators use both color AND icon/text
✓ Tables and lists are keyboard navigable
✓ Forms have proper labels and error messages
✓ Mobile view automatically switches at 800px width
✓ Dark mode ready (uses AppTheme colors)
