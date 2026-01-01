# wait_wise


Overview of the app UI and a sample registration success screen:

![Overview](assets/w1.jpg)
![Success screen](assets/w2.jpg)

## Project Summary & Review

WaitWise is a compact, practical Flutter MVP for managing physical queues digitally. It uses Supabase (Postgres + Realtime) to store user registrations, seed admin accounts, and broadcast queue changes in real time. The app focuses on simplicity and utility — users can register for services, see their queue position and an estimated wait time, while admins can check off served customers.

Highlights:
- Real-time updates using Supabase Realtime channels.
- Per-service estimated time calculation based on recent completion history and configurable per-service timings.
- Admin seeding from environment (`ADMINS_JSON`) to avoid hardcoding credentials.
- Simple, friendly UI designed for quick registration and clear status feedback.




