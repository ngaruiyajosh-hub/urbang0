# Urban Go - Public Transport App

## Project Overview

Urban Go is a comprehensive Flutter mobile application that connects drivers, conductors, and passengers for seamless public transport management. The app includes digital payment integration, real-time vehicle tracking, seat management, and route information.

## Features

### 👤 Three User Roles

#### 1. **Passenger**
- Browse and search available vehicles
- Select pickup and drop locations
- Check seat availability
- Book rides with multiple seat selection
- Digital payment or pay-on-boarding option
- View booking history
- Digital wallet management
- Track route information

#### 2. **Driver**
- Manage vehicle details and routes
- View current and historical bookings
- Track earnings and trips
- Monitor vehicle status
- Access driver ratings

#### 3. **Conductor**
- Manage passenger bookings
- Collect fares (cash and digital)
- View daily collections
- Update booking status
- Track today's passengers

## Project Structure

```
lib/
├── main.dart                          # App entry point
├── models/                            # Data models
│   ├── user_model.dart               # User, UserRole
│   ├── vehicle_model.dart            # Vehicle, VehicleType, VehicleStatus
│   ├── booking_model.dart            # Booking, BookingStatus
│   └── route_model.dart              # Route information
├── services/                          # Business logic
│   ├── auth_service.dart             # Authentication & user management
│   ├── vehicle_service.dart          # Vehicle operations
│   ├── booking_service.dart          # Booking management
│   └── route_service.dart            # Route management
└── screens/                           # UI screens
    ├── auth/
    │   ├── login_screen.dart
    │   └── register_screen.dart
    ├── passenger/
    │   ├── passenger_dashboard.dart
    │   ├── search_vehicles_screen.dart
    │   ├── booking_screen.dart
    │   ├── my_bookings_screen.dart
    │   └── wallet_screen.dart
    ├── driver/
    │   └── driver_dashboard.dart
    └── conductor/
        └── conductor_dashboard.dart
```

## Getting Started

### Prerequisites
- Flutter SDK (3.10.8 or higher)
- Dart SDK
- Android Studio or Xcode for emulator

### Installation Steps

1. **Clone the repository**
```bash
cd c:\Users\JOASH\urban_go
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Run the app**
```bash
flutter run
```

## Demo Credentials

Use these credentials to test the app:

### Passenger
- **Email:** passenger@demo.com
- **Password:** password123

### Driver
- **Email:** driver@demo.com
- **Password:** password123

### Conductor
- **Email:** conductor@demo.com
- **Password:** password123

## Key Classes & Models

### User Model
```dart
enum UserRole { driver, conductor, passenger }

class User {
  String id, name, email, phone, password
  UserRole role
  double walletBalance
  DateTime createdAt
}
```

### Vehicle Model
```dart
enum VehicleType { bus, van, car }
enum VehicleStatus { available, onTrip, maintenance }

class Vehicle {
  String id, registrationNumber, driverId, conductorId, currentRoute
  VehicleType type
  int totalSeats, availableSeats
  double pricePerKm
  VehicleStatus status
  List<String> bookedBy
}
```

### Booking Model
```dart
enum BookingStatus { pending, confirmed, ongoing, completed, cancelled }

class Booking {
  String id, passengerId, vehicleId, pickupLocation, dropLocation
  DateTime bookingTime, departureTime, arrivalTime
  double fare
  int seatsBooked
  BookingStatus status
  String paymentMethod
  bool isPaid
}
```

## Services Overview

### AuthService
Handles user authentication and registration
- `register()` - Register new user
- `login()` - Login user
- `logout()` - Logout current user
- `getCurrentUser()` - Get logged-in user

### VehicleService
Manages vehicle operations
- `getAllVehicles()` - Get all vehicles
- `getAvailableVehicles()` - Get available vehicles
- `bookSeats()` - Book seats in vehicle
- `updateVehicleStatus()` - Update vehicle status

### BookingService
Handles booking operations
- `createBooking()` - Create new booking
- `getBookingsByPassenger()` - Get passenger's bookings
- `getBookingsByVehicle()` - Get vehicle's bookings
- `updateBookingStatus()` - Update booking status
- `processPayment()` - Process payment

### RouteService
Manages route information
- `getAllRoutes()` - Get all available routes
- `searchRoutes()` - Search routes by location
- `getRoutesByStop()` - Get routes passing through a stop

## User Flows

### Passenger Flow
1. Register/Login → Passenger Dashboard
2. Search Vehicles (Browse Available)
3. Select Vehicle → View Details
4. Confirm Booking → Select Seats → Choose Payment
5. Payment Confirmation
6. View My Bookings → Track Trip
7. Manage Wallet

### Driver Flow
1. Register/Login → Driver Dashboard
2. View My Vehicles
3. Monitor Vehicle Status & Availability
4. Track Earnings & Trip History
5. View Ratings

### Conductor Flow
1. Register/Login → Conductor Dashboard
2. View Today's Bookings
3. Update Booking Status
4. Collect Fares
5. View Daily Collections & Reports

## Key Features Implementation

### Authentication
- User registration with role selection
- Login with email and password
- Session management
- Demo users pre-populated for testing

### Vehicle Management
- Real-time seat availability
- Multiple vehicle types (Bus, Van, Car)
- Dynamic pricing per kilometer
- Status tracking (Available, On Trip, Maintenance)

### Booking System
- Multi-seat selection
- Fare calculation based on distance and seats
- Payment options (Digital/Cash)
- Booking status tracking
- Cancellation support

### Wallet System
- Digital wallet for passengers
- Add money functionality
- Transaction history
- Payment processing

## Future Enhancements

1. **GPS Integration**
   - Real-time vehicle location tracking
   - Route navigation
   - Distance calculation

2. **Payment Gateway**
   - UPI integration
   - Credit/Debit card payment
   - Digital wallet APIs

3. **Notifications**
   - Push notifications for bookings
   - Real-time status updates
   - Reminders

4. **Rating & Reviews**
   - Passenger ratings for drivers/conductors
   - Driver/Conductor ratings for passengers
   - Review comments

5. **Advanced Features**
   - Favorite routes
   - Scheduled bookings
   - Multi-city support
   - Analytics dashboard

6. **Backend Integration**
   - Firebase Realtime Database
   - Cloud Firestore
   - Firebase Authentication
   - Stripe/Razorpay integration

## Code Explanation for Beginners

### What is a Model?
Models are classes that hold data. For example, `User` model holds user information like name, email, etc. They're like containers for information.

### What is a Service?
Services contain the business logic (the rules and operations). For example, `AuthService` handles how users login and register.

### What is a Screen?
Screens are the UI pages that users see. For example, `LoginScreen` is the login page.

### How does the app flow work?
1. User sees LoginScreen
2. User enters credentials
3. LoginScreen calls AuthService.login()
4. AuthService checks the credentials
5. If correct, app navigates to the appropriate dashboard

## Testing the App

1. **Test Registration**
   - Click "Sign Up"
   - Enter details with new email
   - Select role
   - Create account

2. **Test Passenger Flow**
   - Login with passenger@demo.com / password123
   - Browse vehicles
   - Book a ride
   - View bookings

3. **Test Driver Flow**
   - Login with driver@demo.com / password123
   - View vehicles
   - Check earnings

4. **Test Conductor Flow**
   - Login with conductor@demo.com / password123
   - View bookings
   - Update status
   - View collections

## Troubleshooting

### Common Issues

1. **App doesn't start**
   - Run `flutter clean`
   - Run `flutter pub get`
   - Run `flutter run`

2. **Build errors**
   - Check Flutter version: `flutter --version`
   - Update Flutter: `flutter upgrade`

3. **Device not found**
   - Check connected devices: `flutter devices`
   - Start emulator or connect physical device

## Learning Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [Dart Language Tour](https://dart.dev/guides/language/language-tour)
- [Flutter Codelab](https://flutter.dev/docs/codelabs)

## Next Steps

1. Study the code structure and understand the flow
2. Modify the UI to match your design
3. Add real backend integration
4. Implement payment gateway
5. Add GPS tracking
6. Deploy to App Store/Play Store

## Support

For questions about the code, refer to the comments in each file. This project is designed to help you learn Flutter development step by step.

Happy coding! 🚀
