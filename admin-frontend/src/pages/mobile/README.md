# Mobile Pages

This directory contains all mobile-specific pages for the Servio application, designed for mobile viewport (max-width: 428px).

## Pages Overview

### 1. Welcome (`/mobile/welcome`)
- **Purpose**: Login/Welcome screen with bottom sheet design
- **Features**: 
  - Email and password inputs
  - Social login options (Google, Facebook)
  - Forgot password link
  - Bottom sheet UI pattern

### 2. Home (`/mobile/home`)
- **Purpose**: Main dashboard for logged-in users
- **Features**:
  - Greeting with user name
  - Search bar with "Later" quick action
  - Last service information
  - Service suggestions list
  - Special offers carousel
  - Bottom tab navigation

### 3. Services (`/mobile/services`)
- **Purpose**: Browse all available services
- **Features**:
  - Search bar
  - Categorized services:
    - Periodic Maintenance
    - Nano Coating
    - Collision Repairs
  - Clickable service items
  - Bottom tab navigation

### 4. Activity (`/mobile/activity`)
- **Purpose**: View upcoming and past appointments
- **Features**:
  - Upcoming service card with image
  - Past services list
  - Filter options
  - Rebook functionality
  - Bottom tab navigation

### 5. Service Detail (`/mobile/service/:id`)
- **Purpose**: View detailed information about a specific service
- **Features**:
  - Service image header
  - Back button
  - Service description with "Show more"
  - Pricing and oil selection options
  - Special instructions text area
  - Book now button with price

### 6. Choose Time (`/mobile/choose-time`)
- **Purpose**: Select appointment date and time
- **Features**:
  - Horizontal scrollable date picker
  - Vertical scrollable time slots
  - Selected state indicators
  - Schedule and Cancel buttons

### 7. Checkout (`/mobile/checkout`)
- **Purpose**: Review order before booking
- **Features**:
  - Order summary with edit option
  - Price breakdown
  - Vehicle information
  - Contact details
  - Payment method selection
  - Book and Cancel buttons

### 8. Appointment Confirmed (`/mobile/confirmed`)
- **Purpose**: Confirmation screen after successful booking
- **Features**:
  - QR code for appointment
  - Appointment ID
  - Service details
  - Date and time
  - Vehicle and contact info
  - Payment method
  - Add to calendar button

## Design System

### Colors
- **Primary**: `#ff5d2e` (Orange)
- **Background Gradient**: `from-[#fff7f5] to-[#fbfbfb]`
- **Surface**: `#ffe7df` (Light orange)
- **Text Primary**: Black
- **Text Secondary**: `#4b4b4b`
- **Border**: `#ffe7df`

### Typography
- **Headings**: Semibold, varying sizes (20px-28px)
- **Body**: Medium/Regular, 14px-16px
- **Small**: 12px

### Components
- **Buttons**: 
  - Primary: Orange background with white text and shadow
  - Secondary: White background with border
- **Cards**: White background with subtle shadow
- **Inputs**: White background with light border
- **Tab Bar**: White background with active indicator

### Layout
- **Max Width**: 428px (centered on larger screens)
- **Padding**: 16px (standard)
- **Gap**: 8px, 12px, 16px, 24px (various)
- **Border Radius**: 8px, 12px, 16px, 24px

## Navigation Flow

```
Welcome → Home
         ↓
    [Tab Navigation]
    - Home
    - Services → Service Detail → Choose Time → Checkout → Confirmed
    - Activity
    - Account
```

## Usage

Import pages from the mobile directory:

```tsx
import { Home, Services, Activity } from '@/pages/mobile';
```

Or import individually:

```tsx
import Home from '@/pages/mobile/Home';
```

## Responsive Considerations

- All pages are optimized for mobile viewports (320px-428px)
- Status bar mimics iOS design
- Home indicator at bottom for gesture navigation
- Touch-friendly tap targets (minimum 44x44px)

## Future Enhancements

- [ ] Add loading states
- [ ] Implement error handling
- [ ] Add animations/transitions
- [ ] Connect to backend API
- [ ] Add authentication flow
- [ ] Implement real QR code generation
- [ ] Add push notifications
- [ ] Implement deep linking
