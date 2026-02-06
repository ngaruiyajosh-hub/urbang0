# Urban Go - FAQ (Frequently Asked Questions)

## Getting Started

### Q1: How do I run the app?
**A:** 
```bash
# Navigate to project directory
cd c:\Users\JOASH\urban_go

# Install dependencies
flutter pub get

# Run on emulator or device
flutter run
```

### Q2: What are the demo credentials?
**A:** 
```
Passenger:  passenger@demo.com / password123
Driver:     driver@demo.com / password123
Conductor:  conductor@demo.com / password123
```

### Q3: Where are the files?
**A:** All files are in `lib/` folder:
- Models in `lib/models/`
- Services in `lib/services/`
- Screens in `lib/screens/`

### Q4: How do I understand the code?
**A:** Read in this order:
1. `PROJECT_SUMMARY.md` - Overview
2. `TUTORIAL.md` - Learn concepts
3. `ARCHITECTURE.md` - Understand structure
4. `GUIDE.md` - Complete reference

---

## Understanding the Code

### Q5: What is a Model?
**A:** A model is a class that defines the structure of data. For example:
```dart
class User {
  String name;
  String email;
  UserRole role;
  // ... other properties
}
```
Models represent "what the data looks like".

### Q6: What is a Service?
**A:** A service contains business logic - the rules of how your app works. For example:
```dart
class AuthService {
  // Logic for login
  // Logic for registration
  // Logic for logout
}
```
Services represent "how things work".

### Q7: What is a Screen?
**A:** A screen is what users see - the User Interface. For example:
```dart
class LoginScreen extends StatelessWidget {
  // Build the UI
  // Handle user input
  // Call services
}
```
Screens represent "what users interact with".

### Q8: What does "async/await" mean?
**A:** It means "wait for this to finish before continuing":
```dart
// This takes time (simulating network request)
Future<bool> login() async {
  await Future.delayed(Duration(milliseconds: 500));
  return true;
}

// Use it like this:
final result = await AuthService.login();
```

---

## Building Features

### Q9: How do I add a new field to User?
**A:** 
1. Open `lib/models/user_model.dart`
2. Add the field:
```dart
class User {
  String id;
  String name;
  String email;
  // ADD THIS:
  String address; // ← New field
}
```
3. Update the constructor and JSON methods
4. Use the new field in services and screens

### Q10: How do I create a new screen?
**A:**
```dart
// 1. Create new file: lib/screens/my_screen.dart
import 'package:flutter/material.dart';

class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('My Screen')),
      body: Text('Hello World'),
    );
  }
}

// 2. Navigate to it from another screen:
Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => MyScreen()),
);
```

### Q11: How do I add a new feature to a service?
**A:**
```dart
// In lib/services/user_service.dart
class UserService {
  // Add new method:
  static Future<bool> updateUserProfile({required User user}) async {
    await Future.delayed(Duration(milliseconds: 300));
    
    // Update logic here
    
    return true;
  }
}

// Use it in screen:
await UserService.updateUserProfile(user: currentUser);
```

### Q12: How do I call a service from a screen?
**A:**
```dart
class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        // Call service
        final result = await MyService.doSomething();
        
        if (result) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Success!')),
          );
        }
      },
      child: Text('Click Me'),
    );
  }
}
```

---

## App Behavior

### Q13: How does authentication work?
**A:**
1. User enters email and password on LoginScreen
2. Clicks "Login"
3. LoginScreen calls `AuthService.login(email, password)`
4. AuthService checks if credentials match
5. If match, sets `_currentUser` and returns true
6. LoginScreen checks result and navigates to dashboard

### Q14: How does booking work?
**A:**
1. Passenger searches for vehicles
2. Selects a vehicle and seats
3. Enters payment method
4. Clicks "Confirm & Book"
5. Two things happen:
   - `BookingService.createBooking()` creates booking record
   - `VehicleService.bookSeats()` reduces available seats
6. Booking is confirmed and saved

### Q15: Why are there 3 dashboards?
**A:** Each user type has different needs:
- **Passenger**: Book rides, view bookings, manage wallet
- **Driver**: Manage vehicle, track earnings, view trips
- **Conductor**: Manage passengers, collect fares, view collections

### Q16: How do I add a new user role?
**A:**
```dart
// 1. Add to enum in lib/models/user_model.dart:
enum UserRole {
  driver,
  conductor,
  passenger,
  admin, // ← New role
}

// 2. Create new dashboard file:
// lib/screens/admin/admin_dashboard.dart

// 3. Update login navigation in lib/screens/auth/login_screen.dart:
if (user.role == UserRole.admin) {
  Navigator.pushReplacement(...AdminDashboard());
}
```

---

## Debugging

### Q17: How do I find errors?
**A:** Look in these places:
1. **VS Code Problems Tab** - Shows errors/warnings
2. **Terminal** - Shows runtime errors
3. **Device Log** - Real device errors
4. Use `print()` to debug:
```dart
void myFunction() {
  print('Debug point 1'); // Add print statements
  final result = doSomething();
  print('Debug point 2');
  print('Result: $result');
}
```

### Q18: App crashed, what do I do?
**A:**
1. Check the error in terminal/console
2. Read the error message carefully
3. Google the error
4. Fix the issue
5. Run: `flutter clean && flutter pub get && flutter run`

### Q19: How do I add debug prints?
**A:**
```dart
import 'dart:developer';

// Use print:
print('Debug: $variable');

// Or use log:
log('Debug message', name: 'MyScreen');

// Or use debugPrint:
debugPrint('Debug: $variable');
```

### Q20: How do I use Flutter DevTools?
**A:**
```bash
# Install DevTools
flutter pub global activate devtools

# Run DevTools
devtools

# Then open the link in browser
# Useful for: checking widget tree, performance, memory
```

---

## Styling & UI

### Q21: How do I change colors?
**A:**
```dart
// In screens, use Theme colors:
Container(
  color: Theme.of(context).primaryColor,
  child: Text('Text'),
)

// Or use Colors directly:
Container(
  color: Colors.blue,
  child: Text('Text'),
)

// Or use custom colors:
Container(
  color: Color(0xFF123456), // Hex color
  child: Text('Text'),
)
```

### Q22: How do I change fonts?
**A:**
```dart
// In main.dart, add fonts to theme:
theme: ThemeData(
  fontFamily: 'Roboto', // Use system fonts
),

// Or use in specific text:
Text(
  'Hello',
  style: TextStyle(
    fontFamily: 'CustomFont',
    fontSize: 16,
    fontWeight: FontWeight.bold,
  ),
)
```

### Q23: How do I make a responsive layout?
**A:**
```dart
// Use MediaQuery for screen size:
double screenWidth = MediaQuery.of(context).size.width;

// Responsive grid:
GridView.count(
  crossAxisCount: screenWidth > 600 ? 3 : 2,
  children: [...],
)

// Responsive padding:
Padding(
  padding: EdgeInsets.all(screenWidth * 0.05),
  child: Text('Content'),
)
```

### Q24: How do I add images?
**A:**
1. Create `assets/images/` folder
2. Add images there
3. Update `pubspec.yaml`:
```yaml
flutter:
  assets:
    - assets/images/
```
4. Use in code:
```dart
Image.asset('assets/images/my_image.png'),
```

---

## Advanced Topics

### Q25: How do I use FutureBuilder?
**A:**
```dart
FutureBuilder<List<Vehicle>>(
  future: VehicleService.getAllVehicles(),
  builder: (context, snapshot) {
    // While loading
    if (snapshot.connectionState == ConnectionState.waiting) {
      return CircularProgressIndicator();
    }
    
    // If error
    if (snapshot.hasError) {
      return Text('Error: ${snapshot.error}');
    }
    
    // Show data
    final vehicles = snapshot.data ?? [];
    return ListView(
      children: vehicles.map((v) => Text(v.registrationNumber)).toList(),
    );
  },
)
```

### Q26: How do I handle state management?
**A:** Current app uses setState (simple). For complex apps, use:
- **Provider** (recommended for beginners)
- **Bloc** (for larger apps)
- **Riverpod** (modern approach)

Example with Provider:
```dart
// Create provider
final userProvider = StateNotifierProvider<UserNotifier, User?>(...);

// Use in widget:
final user = ref.watch(userProvider);

// Update:
ref.read(userProvider.notifier).updateUser(newUser);
```

### Q27: How do I make HTTP requests?
**A:**
```dart
// Add http package to pubspec.yaml:
// http: ^1.1.0

import 'package:http/http.dart' as http;

Future<void> fetchData() async {
  final response = await http.get(
    Uri.parse('https://api.example.com/data'),
  );
  
  if (response.statusCode == 200) {
    final data = json.decode(response.body);
  }
}
```

### Q28: How do I use Firebase?
**A:**
```dart
// 1. Add firebase_core to pubspec.yaml
// 2. Setup Firebase project
// 3. Add to main.dart:

import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

// 4. Use Firebase services:
final users = await FirebaseFirestore.instance
    .collection('users')
    .doc('user_id')
    .get();
```

### Q29: How do I implement real payment?
**A:**
```dart
// Add payment package (e.g., pay package):
// pay: ^1.0.0

// Handle payment:
GestureDetector(
  onTap: () async {
    final result = await showPaymentSheet();
    if (result == true) {
      // Payment successful
      updateBookingStatus();
    }
  },
  child: Text('Pay Now'),
)
```

### Q30: How do I deploy to Play Store?
**A:**
```bash
# 1. Build release APK:
flutter build apk --release

# 2. Or build App Bundle:
flutter build appbundle --release

# 3. Sign with key store
# 4. Upload to Google Play Console
# 5. Follow Play Store guidelines

# Resources:
# https://flutter.dev/docs/deployment/android
```

---

## Best Practices

### Q31: What naming conventions should I follow?
**A:**
- **Files**: `snake_case` (my_file.dart)
- **Classes**: `PascalCase` (MyClass)
- **Variables**: `camelCase` (myVariable)
- **Constants**: `camelCase` (const myConstant)
- **Enums**: `PascalCase` (enum MyEnum)

### Q32: How do I write good comments?
**A:**
```dart
// ✓ Good comments explain WHY, not WHAT
// We use camelCase for readability in our UI framework
String userName;

// ✗ Bad comments just repeat the code
// Set userName
String userName;

/// Use triple slash for documentation
/// Explains the purpose of a function or class
Future<bool> login({required String email}) async {
  // Implementation here
}
```

### Q33: How do I handle errors properly?
**A:**
```dart
try {
  final result = await AuthService.login(email: email, password: password);
  
  if (!result) {
    // Show user-friendly error
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Invalid credentials')),
    );
  }
} catch (e) {
  // Log error for debugging
  print('Login error: $e');
  
  // Show generic error to user
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Something went wrong')),
  );
}
```

### Q34: How do I test my app?
**A:**
```dart
// Create test file: test/widget_test.dart

void main() {
  testWidgets('Login screen works', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    
    // Find widgets
    expect(find.byType(TextField), findsWidgets);
    
    // Enter text
    await tester.enterText(find.byType(TextField).first, 'test@demo.com');
    
    // Tap button
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();
    
    // Verify result
    expect(find.text('Login'), findsOneWidget);
  });
}

// Run tests:
// flutter test
```

---

## Common Problems & Solutions

### Q35: "Null safety" errors?
**A:**
```dart
// Problem: Variable might be null
String? name; // Nullable

// Solution 1: Use null-coalescing
String displayName = name ?? 'Guest';

// Solution 2: Use null-safety operator
if (name != null) {
  print(name.length);
}

// Solution 3: Use late keyword (if value assigned before use)
late String name;
name = 'John';
```

### Q36: "Hot reload" not working?
**A:**
```bash
# Try these:
1. Save file (Ctrl+S)
2. Wait for hot reload
3. If not working, use hot restart: R
4. If still not working:
   flutter clean
   flutter pub get
   flutter run
```

### Q37: App too slow?
**A:**
```dart
// Check for expensive operations in build:
@override
Widget build(BuildContext context) {
  // ✗ DON'T do expensive operations here
  // ✓ DO them in initState() or service
  
  // ✗ DON'T rebuild unnecessary widgets
  // ✓ Use const constructors
  const Text('Hello'), // Better
  Text('Hello'), // Rebuilds every time
}
```

### Q38: Data not updating?
**A:**
```dart
// Make sure to call setState() in StatefulWidget:
void _updateData() {
  setState(() {
    myData = newValue; // This triggers rebuild
  });
}

// Or use FutureBuilder properly:
FutureBuilder(
  future: getData(), // Don't call here, provide function
  builder: (context, snapshot) { ... },
)
```

---

## Resources & Help

### Q39: Where can I learn more?
**A:**
- [Official Flutter Docs](https://flutter.dev/docs)
- [Dart Language Tour](https://dart.dev/guides/language/language-tour)
- [Flutter Samples](https://flutter.github.io/samples/)
- [Medium Flutter Articles](https://medium.com/flutter)
- [YouTube Flutter Tutorials](https://www.youtube.com/results?search_query=flutter+tutorial)

### Q40: How do I get help?
**A:**
1. Check the included documentation:
   - TUTORIAL.md - Learning guide
   - ARCHITECTURE.md - Structure guide
   - GUIDE.md - Feature reference
   
2. Search online:
   - Google the error message
   - Stack Overflow
   - Flutter GitHub issues
   
3. Community:
   - Flutter Discord
   - Reddit r/Flutter
   - Flutter Discuss forum

---

**Keep learning and building!** 🚀

If you have more questions, refer to the documentation or search online. The Flutter community is very helpful!
