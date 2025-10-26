# Servio Backend Setup Guide

## ✅ What's Been Set Up

### 1. **PostgreSQL Database (Docker)**
- Running on port 5433 (avoiding conflict with existing PostgreSQL)
- Container name: `servio-postgres`
- Database: `servio_db`
- User: `servio_user`
- Password: `servio_password`

### 2. **Database Schema**
Tables created:
- **users**: Stores user account information
- **vehicles**: Stores vehicle information (linked to users)
- **service_records**: Stores service history (linked to vehicles)

### 3. **Backend API (Node.js + Express)**
- Running on: `http://localhost:3001`
- CORS enabled for frontend at `http://localhost:5173`
- JWT authentication implemented

### 4. **API Endpoints**

#### Authentication Endpoints:
- **POST** `/api/auth/signup` - Register new user
- **POST** `/api/auth/login` - Login user
- **GET** `/api/auth/profile` - Get user profile (requires auth token)
- **GET** `/api/health` - Health check endpoint

### 5. **Frontend Integration**
- API service created at `frontend/src/services/api.ts`
- Login and Signup pages integrated with backend
- Error handling and loading states implemented
- JWT token stored in localStorage

## 🚀 How to Use

### Start the Backend (Already Running)
The backend is currently running in the background. If you need to restart it:

```bash
cd backend
npm run dev
```

### Start the Frontend
```bash
cd frontend
npm run dev
```

## 🧪 Test the Integration

1. **Open your browser** to `http://localhost:5173`

2. **Create a new account:**
   - Go to Sign Up page
   - Fill in:
     - Full Name
     - Email
     - Phone (optional)
     - Password (min 6 characters)
     - Confirm Password
   - Click "Sign Up"
   - You'll be redirected to login after successful signup

3. **Login with your account:**
   - Enter your email and password
   - Click "Log In"
   - You'll see a success message

## 📊 Check Database Data

You can connect to the database to verify data is being saved:

```bash
docker exec -it servio-postgres psql -U servio_user -d servio_db
```

Then run SQL queries:
```sql
-- View all users
SELECT id, full_name, email, phone, created_at FROM users;

-- Exit
\q
```

## 🔍 API Testing with curl

### Test Signup:
```bash
curl -X POST http://localhost:3001/api/auth/signup \
  -H "Content-Type: application/json" \
  -d '{
    "fullName": "Test User",
    "email": "test@example.com",
    "phone": "1234567890",
    "password": "password123"
  }'
```

### Test Login:
```bash
curl -X POST http://localhost:3001/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123"
  }'
```

### Test Profile (replace TOKEN with actual token from login):
```bash
curl -X GET http://localhost:3001/api/auth/profile \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

## 🛠️ Useful Commands

### Docker Commands:
```bash
# View running containers
docker ps

# View database logs
docker logs servio-postgres

# Stop database
docker-compose down

# Start database
docker-compose up -d

# Reset database (WARNING: Deletes all data)
docker-compose down -v
docker-compose up -d
```

### Backend Commands:
```bash
cd backend

# Start in development mode (with auto-reload)
npm run dev

# Start in production mode
npm start
```

## 📝 What Happens When You Sign Up/Login

1. **Signup Flow:**
   - User fills the form
   - Frontend sends data to `/api/auth/signup`
   - Backend validates the data
   - Password is hashed using bcrypt
   - User is saved to database
   - JWT token is generated
   - Token and user info sent back to frontend
   - Token stored in localStorage
   - User redirected to login

2. **Login Flow:**
   - User enters credentials
   - Frontend sends data to `/api/auth/login`
   - Backend finds user by email
   - Password is compared with hash
   - JWT token is generated
   - Token and user info sent back
   - Token stored in localStorage
   - Success message shown

## 🔐 Security Features

- ✅ Passwords are hashed (not stored as plain text)
- ✅ JWT tokens for authentication
- ✅ Input validation on backend
- ✅ CORS configured
- ✅ SQL injection protection (using parameterized queries)
- ✅ Unique email constraint

## 📁 Project Structure

```
Servio/
├── backend/
│   ├── src/
│   │   ├── config/
│   │   │   └── database.js          # PostgreSQL connection
│   │   ├── controllers/
│   │   │   └── authController.js    # Auth logic
│   │   ├── middleware/
│   │   │   ├── auth.js              # JWT verification
│   │   │   └── validate.js          # Input validation
│   │   ├── routes/
│   │   │   └── authRoutes.js        # API routes
│   │   └── index.js                 # Express server
│   ├── .env                          # Environment variables
│   └── package.json
├── database/
│   └── init.sql                      # Database schema
├── frontend/
│   └── src/
│       ├── pages/
│       │   ├── Login.tsx
│       │   └── Signup.tsx
│       └── services/
│           └── api.ts                # API service
└── docker-compose.yml                # PostgreSQL Docker config
```

## 🎉 Next Steps

Now that authentication is working, you can:

1. Create a dashboard page for logged-in users
2. Add vehicle management features
3. Add service record tracking
4. Implement profile editing
5. Add password reset functionality
6. Implement OAuth (Google/Facebook) login

## ⚠️ Troubleshooting

**If backend won't start:**
```bash
# Check if port 3001 is in use
lsof -ti:3001 | xargs kill -9

# Restart backend
cd backend && npm run dev
```

**If database connection fails:**
```bash
# Check if Docker is running
docker ps

# Restart database
docker-compose down && docker-compose up -d
```

**If frontend can't connect to backend:**
- Make sure backend is running on port 3001
- Check `.env` file in frontend has correct API URL
- Check browser console for CORS errors
