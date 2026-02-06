# Urban Go - Quick Start Tutorial

## Step-by-Step Guide for Beginners

### Step 1: Understanding the Project Structure

The project is organized into folders based on functionality:

```
lib/
├── models/      → Data structures (User, Vehicle, Booking)
├── services/    → Business logic (Authentication, Bookings)
└── screens/     → User interface pages
    ├── auth/    → Login and Registration
    ├── passenger/
    ├── driver/
    └── conductor/
```

**What each folder contains:**
- **Models**: Define what data looks like (e.g., what fields a User has)
- **Services**: Handle operations (e.g., how to login, create bookings)
- **Screens**: Show the UI and interact with services

---

### Step 2: Running the App

1. **Open terminal in the project folder**

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run the app:**
   ```bash
   flutter run
   ```

4. **Wait for the app to load on emulator/device**

---

### Step 3: Understanding the Login Flow

### File: `lib/screens/auth/login_screen.dart`

**What happens when you login:**

1. User enters email and password
2. The `_handleLogin()` function is called
3. It calls `AuthService.login()` from the services layer
4. AuthService checks if credentials are valid
5. If valid, app navigates to the appropriate dashboard

**Code explanation:**
```dart
void _handleLogin() async {
  // 1. Call the login service
  final success = await AuthService.login(
    email: _emailController.text.trim(),
    password: _passwordController.text.trim(),
  );

  // 2. If successful, get the logged-in user
  if (success) {
    final user = AuthService.getCurrentUser();
    
    // 3. Navigate to correct dashboard based on role
    if (user.role == UserRole.passenger) {
      Navigator.pushReplacement(...PassengerDashboard());
    }
  }
}
```

**Demo Credentials:**
- Passenger: `passenger@demo.com` / `password123`
- Driver: `driver@demo.com` / `password123`
- Conductor: `conductor@demo.com` / `password123`

---

### Step 4: Understanding User Roles

The app has 3 user types defined in `lib/models/user_model.dart`:

```dart
enum UserRole {
  driver,       // Operates vehicles
  conductor,    // Collects fares, manages passengers
  passenger,    // Books rides
}
```

Each role has its own dashboard and features.

---

### Step 5: Passenger Features Explained

### File: `lib/screens/passenger/passenger_dashboard.dart`

The passenger sees a dashboard with 4 main sections (bottom navigation):

1. **Home** - Welcome screen with quick actions
2. **Find Rides** - Search and book vehicles
3. **My Bookings** - View past and current bookings
4. **Wallet** - Add money and view transactions

### Booking a Ride

**File: `lib/screens/passenger/search_vehicles_screen.dart`**

Process:
1. Enter pickup and drop locations
2. App searches available vehicles via `VehicleService.getAvailableVehicles()`
3. Shows list of available vehicles with:
   - Vehicle registration number
   - Available seats
   - Price per km
4. Click "Book Now" to proceed to booking details

**File: `lib/screens/passenger/booking_screen.dart`**

Booking details:
1. Select number of seats
2. Choose payment method (Digital or Cash)
3. View fare calculation
4. Confirm booking

---

### Step 6: Understanding Services

### File: `lib/services/auth_service.dart`

**Purpose:** Handle all authentication-related operations

**Main functions:**
- `register()` - Create new user account
- `login()` - Verify credentials and login
- `logout()` - Logout current user
- `getCurrentUser()` - Get logged-in user

**Example:**
```dart
// In AuthService
static User? _currentUser; // Stores logged-in user

static Future<bool> login({required String email, required String password}) async {
  // Find user with matching email and password
  final user = _userDatabase.values.firstWhere(
    (user) => user.email == email && user.password == password,
  );
  _currentUser = user; // Save logged-in user
  return true;
}
```

### File: `lib/services/vehicle_service.dart`

**Purpose:** Manage all vehicle-related operations

**Main functions:**
- `getAllVehicles()` - Get all vehicles
- `getAvailableVehicles()` - Get vehicles with available seats
- `bookSeats()` - Reserve seats in a vehicle
- `updateVehicleStatus()` - Change vehicle status

**Example:**
```dart
static Future<bool> bookSeats({
  required String vehicleId,
  required int seatsToBook,
  required String passengerId,
}) async {
  // Find the vehicle
  final vehicle = _vehicles.firstWhere((v) => v.id == vehicleId);
  
  // Check if seats available
  if (vehicle.availableSeats >= seatsToBook) {
    // Reduce available seats
    vehicle.availableSeats -= seatsToBook;
    return true;
  }
  return false;
}
```

### File: `lib/services/booking_service.dart`

**Purpose:** Handle all booking operations

**Main functions:**
- `createBooking()` - Create new booking
- `getBookingsByPassenger()` - Get passenger's bookings
- `updateBookingStatus()` - Update booking status
- `cancelBooking()` - Cancel a booking

---

### Step 7: Understanding Data Flow

Let's trace a booking from start to finish:

```
1. USER ACTION: Clicks "Book Now" on a vehicle
   ↓
2. BookingScreen opens with vehicle details
   ↓
3. USER ENTERS: Number of seats and payment method
   ↓
4. USER CLICKS: "Confirm & Book"
   ↓
5. CODE EXECUTION:
   - Get current user
   - Call BookingService.createBooking()
   - Call VehicleService.bookSeats()
   ↓
6. DATABASE UPDATE:
   - New booking created with status "pending"
   - Vehicle's available seats reduced
   ↓
7. RESULT: Success message shown, booking saved
```

---

### Step 8: Driver Dashboard

**File: `lib/screens/driver/driver_dashboard.dart`

Driver can:
1. **Home** - View statistics (trips, earnings, rating)
2. **Vehicles** - Manage their vehicles, view details
3. **Earnings** - Track money earned from trips

Key concept: A driver owns vehicles and operates them.

---

### Step 9: Conductor Dashboard

**File: `lib/screens/conductor/conductor_dashboard.dart`**

Conductor can:
1. **Home** - View passenger count, collections, pending payments
2. **Bookings** - View today's passenger bookings, update status
3. **Collections** - Track money collected (cash and digital)

Key concept: A conductor manages passengers and collects fares.

---

### Step 10: Modifying the App

### Want to add a new feature? Follow these steps:

**Example: Add a "Help" button**

1. **Create a new screen** (in appropriate folder)
   ```dart
   // lib/screens/common/help_screen.dart
   class HelpScreen extends StatelessWidget {
     @override
     Widget build(BuildContext context) {
       return Scaffold(
         appBar: AppBar(title: Text('Help')),
         body: Text('Help content here'),
       );
     }
   }
   ```

2. **Add button in dashboard**
   ```dart
   // In PassengerDashboard or other dashboard
   ListTile(
     title: Text('Help'),
     onTap: () {
       Navigator.push(
         context,
         MaterialPageRoute(builder: (_) => HelpScreen()),
       );
     },
   )
   ```

3. **Run the app:**
   ```bash
   flutter run
   ```

---

### Step 11: Understanding Async/Await

Many functions use `async` and `await`. Here's why:

```dart
// When you call a service, it takes time (simulated with delay)
// async means "this function will take time"
// await means "wait for this operation to complete"

Future<bool> login({required String email, required String password}) async {
  // Simulate network delay
  await Future.delayed(Duration(milliseconds: 500));
  
  // Now find the user
  final user = _userDatabase.values.firstWhere(...);
  return true;
}
```

**In UI code:**
```dart
void _handleLogin() async {
  setState(() { _isLoading = true; }); // Show loading spinner
  
  // Wait for login to complete
  final success = await AuthService.login(...);
  
  setState(() { _isLoading = false; }); // Hide loading spinner
}
```

---

### Step 12: Key Concepts Summary

| Concept | What it is | Example |
|---------|-----------|---------|
| **Model** | Data structure | `User`, `Vehicle`, `Booking` |
| **Service** | Business logic | `AuthService`, `BookingService` |
| **Screen** | UI page | `LoginScreen`, `PassengerDashboard` |
| **Widget** | UI component | `TextField`, `ElevatedButton`, `Card` |
| **async/await** | Waiting for operations | Getting data from database |
| **setState** | Update UI when data changes | Showing/hiding loading spinner |
| **Navigator** | Moving between screens | Going from login to dashboard |

---

### Step 13: Common Patterns in the Code

**Pattern 1: Loading data from service**
```dart
FutureBuilder<List<Booking>>(
  future: BookingService.getBookingsByPassenger(userId),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return CircularProgressIndicator(); // Show loading
    }
    return ListView(...); // Show data
  },
)
```

**Pattern 2: Calling service and updating UI**
```dart
void _handleBooking() async {
  setState(() { _isProcessing = true; });
  
  try {
    await BookingService.createBooking(...);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Success!')),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e')),
    );
  } finally {
    setState(() { _isProcessing = false; });
  }
}
```

---

### Step 14: Next Steps to Learn

1. **Modify existing screens** - Change colors, text, layouts
2. **Add new fields to models** - Add more user properties
3. **Create new services** - Add more business logic
4. **Connect to real backend** - Replace simulated data with API calls
5. **Add database** - Use Firebase or local SQLite
6. **Implement payments** - Add Stripe, Razorpay, etc.

---

### Helpful Tips

1. **Use Flutter DevTools** for debugging:
   ```bash
   flutter pub global activate devtools
   devtools
   ```

2. **Hot reload** while developing (R key in terminal)

3. **Check errors** in the "Problems" tab in VS Code

4. **Use Flutter extensions** for better development experience

5. **Read the official Flutter docs** for more details

---

### You're Ready!

Now you understand:
✅ Project structure
✅ How authentication works
✅ How bookings are created
✅ How to navigate between screens
✅ How to call services
✅ How user roles work

Start exploring the code and modify it to learn more!
