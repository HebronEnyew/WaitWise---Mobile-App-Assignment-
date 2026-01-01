# WaitWise - User Documentation & Usage Guide

## 1. Overview

**WaitWise** is an online mobile queue management application for government services. Users join virtual queues, track their position in real-time, and receive notifications when it's their turn. Admins manage queues and serve customers efficiently.

### Key Features
- User registration for multiple services (ID cards, tax payments, birth certificates)
- Real-time queue tracking with estimated wait times
- Automatic notifications when it's your turn
- Admin dashboard for queue management
- Ethiopian phone number validation
- Global sequential service numbering across all services

---

## 2. Tools & Frameworks

### Development Framework
- **Flutter SDK**: ^3.9.2 (Dart programming language)
- **Platform**: Android (minSdk 21, targetSdk 34)

### Backend & Database
- **Supabase**: Backend-as-a-Service (BaaS)
  - Real-time PostgreSQL database
  - Real-time subscriptions for live updates
  - Authentication services

### Key Dependencies
- `supabase_flutter: ^2.5.6` - Supabase integration
- `cupertino_icons: ^1.0.8` - UI icons
- `flutter_lints: ^5.0.0` - Code quality tools

### Development Tools
- Android Studio / VS Code, Flutter CLI, Git

---

## 3. Credentials

### Supabase Configuration
- **Project URL**: `https://ellzkktbnpnlnzzutcvs.supabase.co`
- **Anon Key**: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVsbHpra3RibnBubG56enV0Y3ZzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjcxNjUwMTUsImV4cCI6MjA4Mjc0MTAxNX0.YrpYlQs7R2RO8mztJlbVtHMfK13ez2ujekm6N74kmUY`

### Admins Login Credentials
-# ADMINS_JSON=[{"id":"hosanna","password":"hosi1234","service":"newId"},{"id":"yeabsira","password":"yeab2345","service":"renewID"},{"id":"hebron","password":"hebri3456","service":"taxPayment"},{"id":"kalkidan","password":"kal4567","service":"birthCertificate"}]


...

### Application Details
- **Package Name**: `com.waitwise.app`
- **Version**: 1.0.1
- **App Name**: WaitWise

---

## 4. User Guide - Step by Step

### 4.1 Getting Started

**Step 1: Launch App**
- Open WaitWise on Android device
- Ensure active internet connection
- Tap **"Get Started"** on welcome screen

**Step 2: Select Service**
- View available services:
  - New ID Card (20 min avg) | Renew ID Card (15min avg)
  - Tax Payment (40 min avg) | Birth Certificate (30 min avg)
- Each service shows current queue count
- Tap desired service to register

### 4.2 User Registration

**Step 1: Fill Registration Form**
- **Full Name**: Complete name (required)
- **Phone Number**: Ethiopian number in format:
  - `09XXXXXXXX` (10 digits) | `+2519XXXXXXXX` | `2519XXXXXXXX` | `9XXXXXXXX` (9 digits)
- **Kebele ID**: Identification number (required)

**Step 2: Submit & Confirm**
- Tap **"Register"** button
- Phone number is validated automatically
- On success, receive unique service number
- Redirected to success page showing queue position

**Step 3: View Registration Details**
- **Service Number**: Your unique global queue number
- **Queue Position**: Your position in line
- **People Ahead**: Count of people before you
- **Estimated Time**: Calculated wait time (minutes)

### 4.3 Viewing Your Status

**Step 1: Access Status Dashboard**
- Tap **status icon** (📊) in bottom navigation bar
- Or navigate from service page

**Step 2: Login**
- Enter **Full Name** (exactly as registered)
- Enter **Phone Number** (same format as registration)
- Tap **"Login"**

**Step 3: View All Registrations**
- See list of all services you're registered for
- Each card displays:
  - Service name and your service number
  - People ahead (real-time count)
  - Estimated wait time (auto-updating)
  - Current status

**Step 4: Real-time Updates**
- Status updates automatically when:
  - Someone ahead is served
  - New people join queue
  - Admin processes customers
- No manual refresh needed

### 4.4 Notifications

**When It's Your Turn:**
- When "People Ahead" becomes **0**:
  - **"Your Turn!"** notification banner appears
  - Service card highlights
  - Proceed to service counter

**Notification Behavior:**
- Automatic appearance
- Real-time via Supabase subscriptions
- No manual refresh required

### 4.5 Multiple Service Registration

**Registering for Multiple Services:**
- Register for different services separately
- Each gets unique sequential service number
- Global counter: numbers continue across all services
- Example: 4 people for "New ID" (1-4), next person for "Birth Certificate" gets #5

**Viewing All:**
- Login to status dashboard
- See all registrations in one place
- Each service shows individual status
- Duplicate registrations for same service prevented

---

## 5. Admin Guide - Step by Step

### 5.1 Admin Login

**Step 1: Access Login**
- From home screen, tap **"Log in for admin"** (bottom left)
- Or navigate to login page

**Step 2: Enter Credentials**
- Use an admin ID/password defined in ADMINS_JSON or created in the Supabase `admins` table.
- Example IDs from dev ADMINS_JSON: `hosanna`, `yeabsira`, `hebron`, `kalkidan` (use the passwords defined in your `.env` or update them in the DB).

...
**Step 3: Select Service**
- Choose service to manage:
  - New ID Card | Renew ID Card | Tax Payment | Birth Certificate

### 5.2 Managing Queue

**Step 1: View Queue List**
- See all users in queue for selected service
- Listed in order (by service number)
- Each entry shows: Service Number, Full Name, Phone, Kebele ID, Checkbox

**Step 2: Serve Customer**
- Find customer to serve (usually first in queue)
- Tap **checkbox** next to their name
- Confirm in dialog
- User removed from queue
- See **"User deleted"** success message

**Step 3: Real-time Updates**
- Queue updates automatically when:
  - New users register
  - You delete a user (serve customer)
- No manual refresh needed

### 5.3 Best Practices

**Serving Order:**
- Always serve in order (lowest service number first)
- First person in list should be served next
- Removal is automatic after serving

**Multiple Services:**
- Switch between services via selection
- Each service has independent queue
- Manage separately

**Notifications:**
- When you delete a user, next person automatically notified
- Works via real-time updates

---

## 6. Troubleshooting

### Common Issues & Solutions

**"App not installed" Error**
- Uninstall previous version (Settings > Apps > Uninstall)
- Ensure 100+ MB free storage
- Enable "Install from unknown sources"

**Black Screen on Startup**
- Check internet connection
- Verify Supabase credentials
- Restart app

**"No registration found" Error**
- Ensure name and phone match exactly as registered
- Try different phone formats: 09XXX, +2519XXX
- Check internet connection

**Real-time Updates Not Working**
- Verify internet connection
- Check Supabase Realtime enabled in dashboard
- Restart app

**Phone Number Validation Error**
- Use formats: `09XXXXXXXX`, `+2519XXXXXXXX`, or `9XXXXXXXX`
- Remove spaces, dashes, parentheses

---

## 7. Technical Notes

## 7. Technical Notes

- Keep `.env` out of version control. Add `.env` to `.gitignore`.
- To seed admins from environment, set ADMINS_JSON as a single-line JSON array (see example above).
- If you prefer server-side enforcement for names/duplicates, add DB constraints via Supabase SQL editor.

### Database Structure
- **users**: User registrations with service details
- **global_counter**: Tracks sequential service number
- **admins**: Admin credentials

### Real-time Features
- Supabase Realtime subscriptions
- Automatic updates without refresh
- Multi-device synchronization

### Phone Number Handling
- Normalized to `+2519XXXXXXXX` format
- Accepts multiple input formats
- Consistent database storage

---

**Version**: 1.0.1 | **Platform**: Android 5.0+ (API 21+) | **Last Updated**: 2025
