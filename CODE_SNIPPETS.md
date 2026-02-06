# Urban Go - Code Snippets & Common Patterns

Quick reference for common coding tasks. Copy and paste to get started quickly!

---

## 🔐 Authentication

### Login a User
```dart
void _handleLogin() async {
  final success = await AuthService.login(
    email: 'passenger@demo.com',
    password: 'password123',
  );
  
  if (success) {
    final user = AuthService.getCurrentUser();
    // Navigate to appropriate dashboard
  }
}
```

### Register a User
```dart
void _handleRegister() async {
  final success = await AuthService.register(
    name: 'John Doe',
    email: 'john@example.com',
    phone: '9876543210',
    password: 'password123',
    role: UserRole.passenger,
  );
  
  if (success) {
    // Navigate to login
  }
}
```

### Get Current User
```dart
final user = AuthService.getCurrentUser();
if (user != null) {
  print('Logged in as: ${user.name}');
  print('Role: ${user.role}');
}
```

### Logout User
```dart
AuthService.logout();
// Navigate to login screen
Navigator.pushReplacement(
  context,
  MaterialPageRoute(builder: (_) => const LoginScreen()),
);
```

---

## 🚗 Vehicle Operations

### Get All Vehicles
```dart
final vehicles = await VehicleService.getAllVehicles();
for (var vehicle in vehicles) {
  print('${vehicle.registrationNumber}: ${vehicle.availableSeats} seats');
}
```

### Get Available Vehicles
```dart
final availableVehicles = await VehicleService.getAvailableVehicles();
// Shows only vehicles with available seats
```

### Book Seats
```dart
final success = await VehicleService.bookSeats(
  vehicleId: 'vehicle_1',
  seatsToBook: 3,
  passengerId: 'passenger_123',
);

if (success) {
  print('Seats booked successfully');
}
```

### Update Vehicle Status
```dart
await VehicleService.updateVehicleStatus(
  vehicleId: 'vehicle_1',
  status: VehicleStatus.onTrip,
);
```

---

## 📝 Booking Operations

### Create Booking
```dart
final bookingId = await BookingService.createBooking(
  passengerId: 'passenger_123',
  vehicleId: 'vehicle_1',
  pickupLocation: 'Central Station',
  dropLocation: 'Airport',
  fare: 450.0,
  seatsBooked: 3,
  paymentMethod: 'digital',
);

if (bookingId != null) {
  print('Booking created: $bookingId');
}
```

### Get Passenger Bookings
```dart
final bookings = await BookingService.getBookingsByPassenger('passenger_123');
for (var booking in bookings) {
  print('${booking.pickupLocation} → ${booking.dropLocation}');
  print('Status: ${booking.status}');
  print('Fare: ₹${booking.fare}');
}
```

### Update Booking Status
```dart
final success = await BookingService.updateBookingStatus(
  bookingId: 'booking_123',
  status: BookingStatus.confirmed,
);
```

### Cancel Booking
```dart
final success = await BookingService.cancelBooking('booking_123');
if (success) {
  print('Booking cancelled');
}
```

---

## 🗺️ Route Operations

### Get All Routes
```dart
final routes = await RouteService.getAllRoutes();
for (var route in routes) {
  print('${route.name}: ${route.startPoint} → ${route.endPoint}');
  print('Distance: ${route.distance}km, Time: ${route.estimatedTime}min');
}
```

### Search Routes
```dart
final routes = await RouteService.searchRoutes(
  startPoint: 'Central Station',
  endPoint: 'Airport',
);
```

### Get Routes by Stop
```dart
final routes = await RouteService.getRoutesByStop('Shopping Mall');
// Returns all routes that pass through Shopping Mall
```

---

## 🎨 UI Components

### App Bar
```dart
AppBar(
  title: const Text('My Screen'),
  elevation: 0,
  actions: [
    IconButton(
      icon: const Icon(Icons.logout),
      onPressed: () {
        AuthService.logout();
        // Navigate to login
      },
    ),
  ],
)
```

### Card
```dart
Card(
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
  ),
  child: Padding(
    padding: const EdgeInsets.all(16),
    child: Text('Card content'),
  ),
)
```

### Button
```dart
ElevatedButton(
  onPressed: () {
    // Action here
  },
  child: const Text('Click Me'),
)
```

### Text Field
```dart
TextField(
  controller: _emailController,
  decoration: InputDecoration(
    labelText: 'Email',
    prefixIcon: const Icon(Icons.email),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  ),
)
```

### List View
```dart
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) {
    return ListTile(
      title: Text(items[index].name),
      onTap: () {
        // Handle item tap
      },
    );
  },
)
```

### Future Builder
```dart
FutureBuilder<List<Vehicle>>(
  future: VehicleService.getAllVehicles(),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const CircularProgressIndicator();
    }
    
    if (snapshot.hasError) {
      return Text('Error: ${snapshot.error}');
    }
    
    final vehicles = snapshot.data ?? [];
    return ListView(
      children: vehicles.map((v) => Text(v.registrationNumber)).toList(),
    );
  },
)
```

---

## 🧭 Navigation

### Push to New Screen
```dart
Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => const MyScreen()),
);
```

### Push with Replacement
```dart
Navigator.pushReplacement(
  context,
  MaterialPageRoute(builder: (_) => const DashboardScreen()),
);
```

### Pop Back
```dart
Navigator.pop(context);
```

### Route-based Navigation
```dart
// In main.dart
routes: {
  '/home': (_) => const HomeScreen(),
  '/bookings': (_) => const BookingsScreen(),
},

// In screen
Navigator.pushNamed(context, '/bookings');
```

---

## ⚡ State Management

### setState in Stateful Widget
```dart
class MyScreen extends StatefulWidget {
  @override
  State<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> {
  int _count = 0;
  
  void _increment() {
    setState(() {
      _count++;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: _increment,
      child: Text('Count: $_count'),
    );
  }
}
```

### Async Operation with Loading State
```dart
bool _isLoading = false;
String? _errorMessage;

void _handleBooking() async {
  setState(() {
    _isLoading = true;
    _errorMessage = null;
  });
  
  try {
    await BookingService.createBooking(...);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Success!')),
    );
  } catch (e) {
    setState(() {
      _errorMessage = 'Error: ${e.toString()}';
    });
  } finally {
    setState(() {
      _isLoading = false;
    });
  }
}
```

---

## 💬 User Feedback

### Show Snack Bar
```dart
ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(
    content: Text('Booking confirmed!'),
    backgroundColor: Colors.green,
  ),
);
```

### Show Dialog
```dart
showDialog(
  context: context,
  builder: (context) => AlertDialog(
    title: const Text('Confirm'),
    content: const Text('Are you sure?'),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      ElevatedButton(
        onPressed: () {
          // Do action
          Navigator.pop(context);
        },
        child: const Text('Confirm'),
      ),
    ],
  ),
);
```

### Show Loading Dialog
```dart
showDialog(
  context: context,
  barrierDismissible: false,
  builder: (context) => AlertDialog(
    content: Row(
      children: [
        const CircularProgressIndicator(),
        const SizedBox(width: 16),
        const Text('Processing...'),
      ],
    ),
  ),
);
```

---

## 📊 Data Formatting

### Format Currency
```dart
final fare = 450.50;
print('₹${fare.toStringAsFixed(2)}'); // Output: ₹450.50
```

### Format Date
```dart
import 'package:intl/intl.dart';

final date = DateTime.now();
print(DateFormat('dd/MM/yyyy HH:mm').format(date));
// Output: 03/02/2026 14:30
```

### Format Number
```dart
final distance = 25.5;
print('${distance.toStringAsFixed(1)} km'); // Output: 25.5 km
```

---

## 🔍 Validation

### Validate Email
```dart
bool _isValidEmail(String email) {
  return email.contains('@') && email.contains('.');
}
```

### Validate Password
```dart
bool _isValidPassword(String password) {
  return password.length >= 6;
}
```

### Validate Field
```dart
void _validateForm() {
  if (_nameController.text.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Name is required')),
    );
    return;
  }
  
  if (_emailController.text.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Email is required')),
    );
    return;
  }
  
  // Proceed
}
```

---

## 🎯 Common Patterns

### Responsive Grid
```dart
GridView.count(
  crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
  children: [...],
)
```

### Conditional Rendering
```dart
if (user.role == UserRole.passenger) {
  // Show passenger widgets
} else if (user.role == UserRole.driver) {
  // Show driver widgets
} else {
  // Show conductor widgets
}
```

### Loading with FutureBuilder
```dart
FutureBuilder<List<Booking>>(
  future: BookingService.getBookingsByPassenger(userId),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (snapshot.hasError) {
      return Center(child: Text('Error: ${snapshot.error}'));
    }
    
    final bookings = snapshot.data ?? [];
    
    if (bookings.isEmpty) {
      return const Center(child: Text('No bookings'));
    }
    
    return ListView.builder(
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        return ListTile(title: Text(bookings[index].id));
      },
    );
  },
)
```

### Form with Validation
```dart
void _submitForm() {
  if (_formKey.currentState!.validate()) {
    // All fields are valid
    // Proceed with action
  }
}

Form(
  key: _formKey,
  child: Column(
    children: [
      TextFormField(
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'This field is required';
          }
          return null;
        },
      ),
      ElevatedButton(
        onPressed: _submitForm,
        child: const Text('Submit'),
      ),
    ],
  ),
)
```

---

## 🐛 Debugging

### Print Debug Info
```dart
print('Debug: $variable');
debugPrint('Debug message');
log('Message', name: 'MyScreen');
```

### Add Breakpoints
```dart
// Click line number in VS Code to add breakpoint
// Or add this in code:
assert(variable != null, 'Variable should not be null');
```

### Check Widget Tree
```dart
// In debug console:
// Run: debugPrintBeginFrame()
// Or use Flutter DevTools
```

---

## 📝 Models

### Create User Model
```dart
class User {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  
  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role.toString(),
    };
  }
  
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      role: UserRole.values.firstWhere(
        (e) => e.toString() == json['role'],
      ),
    );
  }
}
```

---

## 🚀 Tips for Efficient Coding

### Use Constants
```dart
const double _defaultPadding = 16.0;
const double _borderRadius = 8.0;

Padding(
  padding: const EdgeInsets.all(_defaultPadding),
  child: Container(
    borderRadius: BorderRadius.circular(_borderRadius),
  ),
)
```

### Use Extracting Widgets
```dart
// Instead of duplicating code, create a method:
Widget _buildVehicleCard(Vehicle vehicle) {
  return Card(
    child: Text(vehicle.registrationNumber),
  );
}

// Use it multiple times:
ListView.builder(
  itemBuilder: (_, i) => _buildVehicleCard(vehicles[i]),
)
```

### Use Null-Coalescing
```dart
// Instead of:
String name = user != null ? user.name : 'Guest';

// Do this:
String name = user?.name ?? 'Guest';
```

### Use Spread Operator
```dart
// Instead of:
List<String> stops = route.stops;
stops.add('New Stop');

// Do this:
List<String> stops = [...route.stops, 'New Stop'];
```

---

## 🔗 External Integration Examples

### Make HTTP Request
```dart
import 'package:http/http.dart' as http;
import 'dart:convert';

Future<List<Vehicle>> fetchVehicles() async {
  final response = await http.get(
    Uri.parse('https://api.example.com/vehicles'),
  );
  
  if (response.statusCode == 200) {
    final List<dynamic> data = json.decode(response.body);
    return data.map((v) => Vehicle.fromJson(v)).toList();
  } else {
    throw Exception('Failed to load vehicles');
  }
}
```

### Firebase Firestore
```dart
import 'package:cloud_firestore/cloud_firestore.dart';

// Get data
final doc = await FirebaseFirestore.instance
    .collection('bookings')
    .doc('booking_id')
    .get();

final booking = Booking.fromJson(doc.data() ?? {});

// Save data
await FirebaseFirestore.instance
    .collection('bookings')
    .doc('booking_id')
    .set(booking.toJson());
```

---

**Copy-paste these snippets to speed up your development!**

For more examples, check the actual code in `lib/` folder.
