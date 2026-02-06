# Urban Go - Architecture & Visual Guide

## Application Architecture

```
┌─────────────────────────────────────────────────────┐
│                    USER INTERFACE LAYER              │
│  (Screens - What users see and interact with)       │
├─────────────────────────────────────────────────────┤
│  LoginScreen → PassengerDashboard                    │
│  RegisterScreen → DriverDashboard                    │
│  BookingScreen → ConductorDashboard                  │
└────────────────┬────────────────────────────────────┘
                 │ Uses
                 ↓
┌─────────────────────────────────────────────────────┐
│                  SERVICES LAYER                      │
│  (Business Logic - How things work)                 │
├─────────────────────────────────────────────────────┤
│  AuthService         → Handles login/registration    │
│  VehicleService      → Manages vehicles & seats      │
│  BookingService      → Handles bookings              │
│  RouteService        → Manages routes                │
└────────────────┬────────────────────────────────────┘
                 │ Uses
                 ↓
┌─────────────────────────────────────────────────────┐
│                   DATA LAYER                         │
│  (Models - Data structures)                          │
├─────────────────────────────────────────────────────┤
│  User          → Passenger, Driver, Conductor        │
│  Vehicle       → Bus, Van, Car                       │
│  Booking       → Trip reservation                    │
│  Route         → Transport routes                    │
└─────────────────────────────────────────────────────┘
```

## User Authentication Flow

```
START
  │
  ├─→ User on LoginScreen
  │     │
  │     └─→ Enters email & password
  │           │
  │           └─→ Clicks "Login"
  │                 │
  │                 └─→ AuthService.login() called
  │                       │
  │                       ├─→ Email exists? YES
  │                       │     │
  │                       │     └─→ Password matches? YES
  │                       │           │
  │                       │           └─→ Set _currentUser
  │                       │                 │
  │                       │                 └─→ Return TRUE ✓
  │                       │
  │                       └─→ Invalid credentials
  │                             │
  │                             └─→ Return FALSE ✗
  │
  ├─→ If TRUE: Navigate to Dashboard
  │     │
  │     ├─→ Check user.role
  │     │
  │     ├─→ role == passenger → PassengerDashboard
  │     ├─→ role == driver → DriverDashboard
  │     └─→ role == conductor → ConductorDashboard
  │
  └─→ If FALSE: Show error message

END
```

## Passenger Booking Flow

```
PASSENGER APP FLOW:
─────────────────

PassengerDashboard
      │
      ├─→ Click "Find Rides"
      │     │
      │     └─→ SearchVehiclesScreen
      │           │
      │           ├─→ Enter:
      │           │   - Pickup Location
      │           │   - Drop Location
      │           │
      │           └─→ Click "Search Vehicles"
      │                 │
      │                 └─→ VehicleService.getAvailableVehicles()
      │                       │
      │                       └─→ Load vehicles with available seats
      │
      ├─→ Click "Book Now" on vehicle
      │     │
      │     └─→ BookingScreen
      │           │
      │           ├─→ Select number of seats (1-5)
      │           │
      │           ├─→ Choose payment:
      │           │   - Digital Payment (auto-pay)
      │           │   - Pay on Boarding
      │           │
      │           ├─→ View calculated fare
      │           │   (Price per km × Distance × Number of seats)
      │           │
      │           └─→ Click "Confirm & Book"
      │                 │
      │                 ├─→ BookingService.createBooking()
      │                 │     │
      │                 │     └─→ Create new Booking record
      │                 │
      │                 └─→ VehicleService.bookSeats()
      │                       │
      │                       └─→ Reduce available seats
      │                       └─→ Add passenger to bookedBy list
      │
      ├─→ Booking confirmed ✓
      │
      ├─→ Click "My Bookings"
      │     │
      │     └─→ MyBookingsScreen
      │           │
      │           ├─→ Show all bookings with status:
      │           │   - Pending (yellow)
      │           │   - Confirmed (blue)
      │           │   - Ongoing (purple)
      │           │   - Completed (green)
      │           │   - Cancelled (red)
      │           │
      │           └─→ Can cancel pending bookings
      │
      └─→ Click "Wallet"
            │
            └─→ WalletScreen
                  │
                  ├─→ View balance
                  ├─→ Add money
                  └─→ View transaction history

END
```

## Vehicle Data Model

```
┌─────────────────────────────────┐
│         VEHICLE CLASS           │
├─────────────────────────────────┤
│ Properties:                     │
│ • id: String                    │
│ • registrationNumber: String    │
│ • type: VehicleType             │
│ │  ├─ BUS (50 seats)            │
│ │  ├─ VAN (15 seats)            │
│ │  └─ CAR (5 seats)             │
│ • driverId: String              │
│ • conductorId: String           │
│ • totalSeats: int               │
│ • availableSeats: int           │
│ • pricePerKm: double            │
│ • status: VehicleStatus         │
│ │  ├─ AVAILABLE                 │
│ │  ├─ ON_TRIP                   │
│ │  └─ MAINTENANCE               │
│ • currentRoute: String          │
│ • bookedBy: List<String>        │
│                                 │
│ Methods:                        │
│ • copyWith() - Create modified  │
│ • toJson() - Convert to JSON    │
│ • fromJson() - Create from JSON │
└─────────────────────────────────┘

EXAMPLE VEHICLE:
Registration: KA-01-AB-1234
Type: BUS
Total Seats: 50
Available: 45
Price: ₹2.50/km
Status: AVAILABLE
Route: Downtown Express (Central Station → Airport)
```

## Booking Data Model

```
┌──────────────────────────────────┐
│        BOOKING CLASS             │
├──────────────────────────────────┤
│ Properties:                      │
│ • id: String                     │
│ • passengerId: String            │
│ • vehicleId: String              │
│ • pickupLocation: String         │
│ • dropLocation: String           │
│ • bookingTime: DateTime          │
│ • departureTime: DateTime        │
│ • arrivalTime: DateTime          │
│ • fare: double                   │
│ • seatsBooked: int               │
│ • status: BookingStatus          │
│ │  ├─ PENDING                    │
│ │  ├─ CONFIRMED                  │
│ │  ├─ ONGOING                    │
│ │  ├─ COMPLETED                  │
│ │  └─ CANCELLED                  │
│ • paymentMethod: String          │
│ │  ├─ DIGITAL                    │
│ │  └─ CASH                       │
│ • isPaid: bool                   │
│                                  │
│ Methods:                         │
│ • toJson() - Convert to JSON     │
│ • fromJson() - Create from JSON  │
└──────────────────────────────────┘

EXAMPLE BOOKING:
ID: 16849245
Passenger: John (user123)
Vehicle: KA-01-AB-1234 (BUS)
From: Central Station
To: Airport Terminal
Time: 2024-01-15 10:30
Seats: 3
Fare: ₹750 (₹250 × 3)
Status: CONFIRMED ✓
Payment: DIGITAL
Paid: YES
```

## Service Layer Communication

```
SCREEN LAYER                SERVICES LAYER             DATA STORAGE
────────────                ──────────────             ────────────

LoginScreen                AuthService
    │                          │
    ├─ email ────────────────→ login()
    └─ password               │
                              ├─ Check email exists
                              ├─ Check password matches
                              ├─ Set _currentUser
                              └─ Return boolean
                              
PassengerDashboard         VehicleService
    │                          │
    └─ Search ────────────────→ getAvailableVehicles()
       request                 │
                              ├─ Filter by status
                              ├─ Filter by available seats > 0
                              └─ Return List<Vehicle>

BookingScreen              BookingService
    │                          │
    └─ Create ────────────────→ createBooking()
       booking                 │
                              ├─ Create Booking record
                              ├─ Set status = pending
                              ├─ Set isPaid = true/false
                              └─ Return booking ID

                          VehicleService
                              │
                              └─ bookSeats()
                                 │
                                 ├─ Find vehicle
                                 ├─ availableSeats -= seatsBooked
                                 └─ bookedBy.add(passengerId)
```

## Dashboard Navigation Structure

```
┌──────────────────────────────────────────────┐
│              LOGIN SCREEN                    │
│  ┌──────────────────────────────────────┐  │
│  │ Email: passenger@demo.com            │  │
│  │ Password: •••••••                    │  │
│  │                                      │  │
│  │ [LOGIN]  [SIGN UP]                  │  │
│  └──────────────────────────────────────┘  │
└──────────────────────────────────────────────┘
         │
         ├─ Login as PASSENGER
         │    │
         │    └─→ ┌─────────────────────────────────────┐
         │        │    PASSENGER DASHBOARD              │
         │        │  ┌─ HOME      ──────────────┐       │
         │        │  │ [Book Ride] [My Bookings] │      │
         │        │  │ [Wallet] [Support]       │       │
         │        │  └──────────────────────────┘       │
         │        │  ┌─ FIND RIDES  ────────────┐       │
         │        │  │ Search vehicles           │       │
         │        │  │ Select vehicle            │       │
         │        │  │ Book seats                │       │
         │        │  └──────────────────────────┘       │
         │        │  ┌─ MY BOOKINGS  ────────────┐      │
         │        │  │ View all bookings         │       │
         │        │  │ Cancel booking            │       │
         │        │  └──────────────────────────┘       │
         │        │  ┌─ WALLET  ─────────────────┐      │
         │        │  │ Check balance             │       │
         │        │  │ Add money                 │       │
         │        │  │ View transactions         │       │
         │        │  └──────────────────────────┘       │
         │        └─────────────────────────────────────┘
         │
         ├─ Login as DRIVER
         │    │
         │    └─→ ┌─────────────────────────────────────┐
         │        │     DRIVER DASHBOARD                │
         │        │  ┌─ HOME  ───────────────────┐      │
         │        │  │ Stats: Trips, Earnings    │      │
         │        │  │ Rating, Quick Actions     │      │
         │        │  └───────────────────────────┘      │
         │        │  ┌─ VEHICLES  ────────────────┐     │
         │        │  │ My vehicles                │     │
         │        │  │ Vehicle status             │     │
         │        │  │ Seat availability          │     │
         │        │  └───────────────────────────┘      │
         │        │  ┌─ EARNINGS  ────────────────┐     │
         │        │  │ Total earnings             │     │
         │        │  │ This month / week          │     │
         │        │  │ Recent trips               │     │
         │        │  └───────────────────────────┘      │
         │        └─────────────────────────────────────┘
         │
         └─ Login as CONDUCTOR
              │
              └─→ ┌─────────────────────────────────────┐
                  │    CONDUCTOR DASHBOARD              │
                  │  ┌─ HOME  ───────────────────┐      │
                  │  │ Stats: Passengers, Money  │      │
                  │  │ Pending, Quick Actions    │      │
                  │  └───────────────────────────┘      │
                  │  ┌─ BOOKINGS  ────────────────┐     │
                  │  │ Today's bookings           │     │
                  │  │ Update status              │     │
                  │  │ Passenger info             │     │
                  │  └───────────────────────────┘      │
                  │  ┌─ COLLECTIONS  ─────────────┐     │
                  │  │ Today's collections        │     │
                  │  │ Collected vs Pending       │     │
                  │  │ Collection details         │     │
                  │  └───────────────────────────┘      │
                  └─────────────────────────────────────┘
```

## How Data Flows Through the App

```
EXAMPLE: Passenger books a ride

STEP 1: User Input (Screen)
────────────────────────────
User enters:
- Pickup: "Central Station"
- Drop: "Airport Terminal"
- Clicks: Search

         ↓↓↓

STEP 2: Service Call (Business Logic)
──────────────────────────────────────
VehicleService.getAvailableVehicles()
        │
        ├─ Filter vehicles where:
        │  • status == AVAILABLE
        │  • availableSeats > 0
        │
        └─ Return List of vehicles

         ↓↓↓

STEP 3: UI Updates (Screen)
────────────────────────────
Show vehicles in list with:
- Registration number
- Available seats count
- Price per km
- "Book Now" button

         ↓↓↓

STEP 4: User Books (Screen)
────────────────────────────
User selects:
- Vehicle: KA-01-AB-1234
- Seats: 3
- Payment: Digital
- Clicks: "Confirm & Book"

         ↓↓↓

STEP 5: Create Booking (Services)
──────────────────────────────────
BookingService.createBooking()
        │
        ├─ Create new Booking object:
        │  {
        │    id: "unique_id",
        │    passengerId: "user_123",
        │    vehicleId: "KA-01-AB-1234",
        │    pickupLocation: "Central Station",
        │    dropLocation: "Airport Terminal",
        │    seatsBooked: 3,
        │    fare: 750,
        │    status: PENDING,
        │    paymentMethod: DIGITAL,
        │    isPaid: true
        │  }
        │
        └─ Save to database

         ↓↓↓

STEP 6: Update Vehicle (Services)
──────────────────────────────────
VehicleService.bookSeats()
        │
        ├─ Find vehicle: KA-01-AB-1234
        │
        ├─ Update:
        │  • availableSeats: 45 → 42
        │  • bookedBy: ["user_123"]
        │
        └─ Save to database

         ↓↓↓

STEP 7: Show Success (Screen)
──────────────────────────────
Display:
✓ Booking confirmed!
- Booking ID: 16849245
- Fare: ₹750
- Status: Pending
- Go to "My Bookings" to track

         ↓↓↓

FINAL STATE:
────────────
Booking record created ✓
Vehicle seats updated ✓
Ready for trip ✓
```

## Key Flutter Concepts Visual

```
FLUTTER APP STRUCTURE:

┌──────────────────────────────────┐
│       MAIN.DART (Entry Point)    │
│                                  │
│  main() → MyApp() → MaterialApp  │
│                        │         │
│                 home: LoginScreen
│                                  │
└──────────────────────────────────┘
           │
           └─→ ┌────────────────────────────────┐
               │    WIDGET (UI Component)       │
               │                                │
               │  Stateless  → No changes       │
               │  Stateful   → Can change       │
               │                                │
               └────────────────────────────────┘
           │
           └─→ ┌────────────────────────────────┐
               │    BUILD METHOD                │
               │                                │
               │  Returns the UI layout         │
               │  Called when:                  │
               │  • First time screen shows     │
               │  • setState() called           │
               │  • Parent widget rebuilds      │
               │                                │
               └────────────────────────────────┘

STATEFUL WIDGET LIFECYCLE:

1. createState() → Creates mutable state
        │
        ↓
2. initState() → Runs once when created
        │
        ↓
3. build() → Draws the UI (called many times)
        │
        ↓
4. setState() → Update data, rebuild UI
        │
        ↓
5. dispose() → Cleanup when widget removed
```

## File Organization Quick Reference

```
lib/
│
├── main.dart
│   └─ App entry point, MyApp class
│
├── models/
│   ├── user_model.dart       → User, UserRole enums
│   ├── vehicle_model.dart    → Vehicle, VehicleType, VehicleStatus
│   ├── booking_model.dart    → Booking, BookingStatus
│   └── route_model.dart      → Route information
│
├── services/
│   ├── auth_service.dart     → Login, Register, Logout
│   ├── vehicle_service.dart  → Get vehicles, Book seats
│   ├── booking_service.dart  → Create, Update bookings
│   └── route_service.dart    → Search routes
│
└── screens/
    ├── auth/
    │   ├── login_screen.dart
    │   └── register_screen.dart
    │
    ├── passenger/
    │   ├── passenger_dashboard.dart
    │   ├── search_vehicles_screen.dart
    │   ├── booking_screen.dart
    │   ├── my_bookings_screen.dart
    │   └── wallet_screen.dart
    │
    ├── driver/
    │   └── driver_dashboard.dart
    │
    └── conductor/
        └── conductor_dashboard.dart

FINDING FILES:
• Changing login logic? → services/auth_service.dart
• Modifying UI? → screens/*/
• Adding properties to user? → models/user_model.dart
• Changing how bookings work? → services/booking_service.dart
```

This visual guide should help you understand how everything connects!
