# Mobile Navigation Flow

## User Journey Map

```
┌─────────────────────────────────────────────────────────────────┐
│                         WELCOME SCREEN                          │
│                      (/mobile/welcome)                          │
│                                                                  │
│  ┌────────────────────────────────────────────────────┐        │
│  │  Logo                                                │        │
│  │  Welcome Back to Servio                             │        │
│  │  ┌──────────────────┐                               │        │
│  │  │ Email           │                               │        │
│  │  └──────────────────┘                               │        │
│  │  ┌──────────────────┐                               │        │
│  │  │ Password        │                               │        │
│  │  └──────────────────┘                               │        │
│  │  [ Log In ]                                          │        │
│  │  Forgot Password?                                    │        │
│  │  ────── or ──────                                   │        │
│  │  [ Log In with Google ]                             │        │
│  │  [ Log In with Facebook ]                           │        │
│  └────────────────────────────────────────────────────┘        │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                          HOME SCREEN                            │
│                       (/mobile/home)                            │
│                                                                  │
│  Hello, Cham!                                                   │
│  ┌──────────────────────────────────────┐                      │
│  │ 🔍 Search services     │ 📅 Later    │                      │
│  └──────────────────────────────────────┘                      │
│  ┌──────────────────────────────────────┐                      │
│  │ 🏢 Last service: Auto Miraj          │                      │
│  └──────────────────────────────────────┘                      │
│  Suggestions                        See all                     │
│  • Lube Services                →                               │
│  • Washing Packages              →                               │
│  • Exterior & Interior Detailing →                               │
│  • Engine Tune ups               →                               │
│  ┌──────────────────────────────┐                              │
│  │ Special Offers               │                              │
│  │ [Book now]                   │                              │
│  └──────────────────────────────┘                              │
│  ────────────────────────────────                              │
│  🏠 Home  📋 Services  📄 Activity  👤 Account                 │
└─────────────────────────────────────────────────────────────────┘
      │           │              │              │
      │           ▼              ▼              ▼
      │    ┌──────────┐   ┌──────────┐   ┌──────────┐
      │    │ SERVICES │   │ ACTIVITY │   │ ACCOUNT  │
      │    │  PAGE    │   │   PAGE   │   │   PAGE   │
      │    └──────────┘   └──────────┘   └──────────┘
      │           │              │
      │           ▼              │
      │    ┌─────────────────────────────────────────┐
      │    │        SERVICE DETAIL                   │
      │    │    (/mobile/service/:id)                │
      │    │                                          │
      │    │  [<] Back        [Service Image]        │
      │    │  Lubricant Service                      │
      │    │  LKR 1,500.00                           │
      │    │  Description...                         │
      │    │  ○ Standard Oil       [✓]               │
      │    │  ○ Synthetic Blend    [ ]               │
      │    │  ○ Full Synthetic     [ ]               │
      │    │  Special Instructions: [___]            │
      │    │  [ Book now • LKR 5,500 ]               │
      │    └─────────────────────────────────────────┘
      │           │
      │           ▼
      │    ┌─────────────────────────────────────────┐
      │    │        CHOOSE TIME                      │
      │    │    (/mobile/choose-time)                │
      │    │                                          │
      │    │  [<] Choose a time                      │
      │    │  [Tomorrow] [Mon] [Tue] [Wed]...        │
      │    │  ───────────────────────────            │
      │    │  ○ 9:00 AM - 9:30 AM    [●]             │
      │    │  ○ 9:30 AM - 10:00 AM   [ ]             │
      │    │  ○ 10:00 AM - 10:30 AM  [ ]             │
      │    │  ...                                     │
      │    │  [ Schedule ]                           │
      │    │  [ Cancel ]                             │
      │    └─────────────────────────────────────────┘
      │           │
      │           ▼
      │    ┌─────────────────────────────────────────┐
      │    │          CHECKOUT                       │
      │    │      (/mobile/checkout)                 │
      │    │                                          │
      │    │  [<] Checkout                           │
      │    │  Order Summary:                         │
      │    │  • Lubricant Service                    │
      │    │  • Tomorrow, 9:00 AM       [Edit]       │
      │    │  Price Breakdown:                       │
      │    │  • Service Fee: +LKR 1,500              │
      │    │  • Standard Oil: +LKR 4,000             │
      │    │  • Total: LKR 5,500                     │
      │    │  🚗 Toyota Premio                       │
      │    │  📞 +94 72 4523 299                     │
      │    │  💰 Cash                                │
      │    │  [ Book ]                               │
      │    │  [ Cancel ]                             │
      │    └─────────────────────────────────────────┘
      │           │
      │           ▼
      │    ┌─────────────────────────────────────────┐
      │    │    APPOINTMENT CONFIRMED                │
      │    │   (/mobile/confirmed)                   │
      │    │                                          │
      │    │  [<] Appointment Confirmed!             │
      │    │  Chamal Dissanayake                     │
      │    │  ID: #SL-GOV-2025-00483                 │
      │    │  ┌───────────────────┐                  │
      │    │  │                   │                  │
      │    │  │    [QR CODE]      │                  │
      │    │  │                   │                  │
      │    │  └───────────────────┘                  │
      │    │  Service: Lubricant Service             │
      │    │  ⚠️ Oct 26 · 9:00 AM - 9:30 AM          │
      │    │  🚗 Toyota Premio                       │
      │    │  📞 +94 72 4523 299                     │
      │    │  💰 Pay by Cash                         │
      │    │  [ Add to calendar ]                    │
      │    └─────────────────────────────────────────┘
      │
      └──────────► Back to Home/Activity
```

## Tab Bar Navigation

```
┌─────────────────────────────────────────────────────┐
│                  Bottom Tab Bar                     │
├─────────────────────────────────────────────────────┤
│  🏠 Home  │  📋 Services  │  📄 Activity  │  👤 Account │
│    ▬▬        (active)                                │
└─────────────────────────────────────────────────────┘
```

## Screen Hierarchy

```
Root
├── Welcome (Login)
└── App Shell (After Login)
    ├── Tab Navigation
    │   ├── Home
    │   ├── Services
    │   │   └── Service Detail (Modal/Push)
    │   │       └── Choose Time (Modal/Push)
    │   │           └── Checkout (Modal/Push)
    │   │               └── Confirmation (Modal/Push)
    │   ├── Activity
    │   └── Account
    └── Floating Components
        ├── Status Bar (iOS)
        ├── Navigation Bar
        └── Home Indicator
```

## Key Interactions

### 1. Service Booking Flow
```
Home/Services → Service Detail → Choose Time → Checkout → Confirmed
```

### 2. Rebooking Flow
```
Activity → Past Service → Rebook → Service Detail → ...
```

### 3. Quick Actions
```
Home → Search → Services
Home → Later → Choose Time
Home → Last Service → Service Detail
```

## UI Patterns

### Bottom Sheet
- Welcome screen uses bottom sheet for login form
- Swipe down to dismiss (future enhancement)

### Cards
- Service cards: Image + Title + CTA
- Appointment cards: Image + Details + Actions
- Info cards: Icon + Text + Navigation

### Lists
- Service list: Icon + Name + Arrow
- Time slots: Text + Radio button
- Price breakdown: Item + Price

### Forms
- Input fields: Label + Text input
- Selection: Radio buttons / Checkboxes
- Actions: Primary + Secondary buttons

### Navigation
- Back button: Top left on detail pages
- Tab bar: Bottom navigation for main sections
- Close button: Modal dismissal

## Color Coding

```
Primary Actions:   🟠 Orange (#ff5d2e)
Secondary Actions: ⚪ White with border
Success:           🟢 Green (future)
Warning:           🟡 Yellow (#ffe7df)
Error:             🔴 Red (future)
Text Primary:      ⚫ Black
Text Secondary:    ⚫ Gray (#4b4b4b)
Background:        ⚪ White/Gradient
```
