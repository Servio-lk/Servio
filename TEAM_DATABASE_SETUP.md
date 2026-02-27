# Team Database Setup Guide

## Problem: Developers Can't See Each Other's Appointments

When each developer runs `docker-compose up` on their laptop, they get their **own isolated database**. Appointments created on one laptop don't appear on other laptops because the databases are completely separate.

## Solution: Use a Shared Database

All 4 developers connect to the **same database** so everyone can see all appointments.

---

## Option 1: Use Supabase Database (Recommended - Easiest)

Supabase provides a free PostgreSQL database that's already configured in this project!

### Step 1: Get Supabase Database Password

1. Go to [Supabase Dashboard](https://supabase.com/dashboard)
2. Select your project: `szgvnurzdglflmdabjol`
3. Go to **Settings** → **Database**
4. Find **Database Password** (you set this when creating the project)
5. Copy the password

### Step 2: Run Database Migration on Supabase

You need to set up the database schema on Supabase:

**Using Supabase SQL Editor:**

1. Go to Supabase Dashboard → **SQL Editor**
2. Copy the contents of `database/init.sql`
3. Paste and run it in the SQL Editor

**OR using psql:**

```powershell
# Connect to Supabase database
psql "postgresql://postgres:[YOUR_PASSWORD]@db.szgvnurzdglflmdabjol.supabase.co:5432/postgres"

# Then paste the contents of database/init.sql
```

### Step 3: Update .env.shared File

Edit `.env.shared` and add your Supabase database password:

```env
SHARED_DB_HOST=db.szgvnurzdglflmdabjol.supabase.co
SHARED_DB_PORT=5432
SHARED_DB_USER=postgres
SHARED_DB_PASSWORD=your_actual_supabase_password_here
SHARED_DB_NAME=postgres
```

### Step 4: All Developers Run This Command

```powershell
docker-compose -f docker-compose.shared-db.yml --env-file .env.shared up -d
```

✅ **Done!** All 4 developers now share the same Supabase database and can see each other's appointments.

---

## Option 2: One Developer Hosts the Database

If you don't want to use Supabase, one developer can host the database and others connect to it.

### On Developer 1's Laptop (Host):

**Step 1: Find your IP address**

```powershell
ipconfig
```

Look for `IPv4 Address` (e.g., `192.168.1.105`)

**Step 2: Update PostgreSQL to allow remote connections**

Edit `docker-compose.yml` - make sure postgres has:

```yaml
ports:
  - "5433:5432" # Already configured
```

**Step 3: Start the database**

```powershell
docker-compose up -d postgres
```

**Step 4: Share your IP with the team**
Tell the other 3 developers your IP address (e.g., `192.168.1.105`)

### On Other Developers' Laptops (Clients):

**Step 1: Update .env.shared**

```env
SHARED_DB_HOST=192.168.1.105  # Use Developer 1's IP
SHARED_DB_PORT=5433
SHARED_DB_USER=servio_user
SHARED_DB_PASSWORD=servio_password
SHARED_DB_NAME=servio_db
```

**Step 2: Run without local database**

```powershell
docker-compose -f docker-compose.shared-db.yml --env-file .env.shared up -d
```

✅ **Done!** All developers connect to Developer 1's database.

---

## Option 3: Keep Separate Databases (Current Setup)

If you want to keep testing with separate databases, use the "Show All Appointments" feature I added:

1. Go to Activity page
2. Click **"Show All Appointments"** button
3. You'll see all appointments in YOUR database

But you still won't see appointments from other developers' laptops.

---

## Switching Between Local and Shared Database

**Local database (each developer has their own):**

```powershell
docker-compose up -d
```

**Shared database (all developers see the same data):**

```powershell
docker-compose -f docker-compose.shared-db.yml --env-file .env.shared up -d
```

---

## Verifying It Works

After setting up shared database, test it:

1. **Developer 1**: Create an appointment
2. **Developer 2**: Refresh the Activity page → Should see Developer 1's appointment
3. **Developer 3**: Create another appointment
4. **Developer 4**: Should see both appointments

---

## Troubleshooting

### "Connection refused" error

- Check firewall settings
- Make sure the host developer's Docker is running
- Verify the IP address is correct

### "Password authentication failed"

- Double-check the password in `.env.shared`
- For Supabase, get the password from Dashboard → Settings → Database

### Tables don't exist

- Run the database migration (`database/init.sql`) on the shared database first

---

## Recommendation

**For a team of 4 developers:** Use **Option 1 (Supabase)** because:

- ✅ Free for development
- ✅ No need for one developer to always run their computer
- ✅ Works from anywhere (home, office, etc.)
- ✅ Automatic backups
- ✅ Easy to set up
