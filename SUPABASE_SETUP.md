# Supabase Setup Instructions

## 1. Create a Supabase Project

1. Go to https://supabase.com and sign up/login
2. Create a new project
3. Wait for the project to be fully provisioned

## 2. Get Your Supabase Credentials

1. Go to Project Settings > API
2. Copy your Project URL
3. Copy your anon/public key

## 3. Update Configuration

Open `lib/config/supabase_config.dart` and replace:

- `YOUR_SUPABASE_URL` with your Project URL
- `YOUR_SUPABASE_ANON_KEY` with your anon key

## 4. Set Up Database Tables

1. Go to SQL Editor in your Supabase dashboard
2. Run the SQL from `supabase_setup.sql` file
3. This will create:
   - `users` table for storing user registrations
   - `global_counter` table for tracking global service numbers (auto-increments across all services)
   - `admins` table for admin authentication
   - Indexes for better performance
   - Enable real-time replication

## 5. Enable Row Level Security (RLS)

For development, you can disable RLS or set up policies:

1. Go to Authentication > Policies
2. For each table (users, service_counters, admins), you can:
   - Disable RLS temporarily for testing
   - Or create policies that allow all operations

Example policy for users table (allow all):

```sql
CREATE POLICY "Allow all operations" ON users
FOR ALL
USING (true)
WITH CHECK (true);
```

Repeat for `global_counter` and `admins` tables.

## 6. Enable Realtime

1. Go to Database > Replication
2. Enable replication for:
   - `users` table
   - `global_counter` table
   - `admins` table (optional)

## 7. Install Dependencies

Run in your project directory:

```bash
flutter pub get
```

## 8. Run the App

```bash
flutter run
```

## Notes

- The app uses real-time subscriptions to update queue counts automatically
- Admin credentials are seeded automatically on first run
- Service names are mapped between display names and database names:
  - "New Id card" → "newId"
  - "Renew Id card" → "renewID"
  - "Tax payment" → "taxPayment"
  - "Birth certificate" → "birthCertificate"
