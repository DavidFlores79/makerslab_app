# OTP Registration Flow Documentation

## Overview
The registration process now requires phone number verification via OTP (One-Time Password) before a user can access the application.

## Registration Flow

### 1. User Signup (POST `/api/auth/signup`)

**Request Body:**
```json
{
  "name": "John Doe",
  "email": "john@example.com",
  "phone": "+1234567890",
  "password": "password123",
  "image": "optional-image-url",
  "role": "optional-role-id"
}
```

**Response (Success - 201):**
```json
{
  "message": "OTP sent successfully. Please verify your phone number to complete registration.",
  "registrationId": "507f1f77bcf86cd799439011"
}
```

**What happens:**
- User is created in database with `status: false` (inactive)
- OTP is generated and saved to user document
- OTP expires in 5 minutes
- OTP is sent via Twilio SMS to the provided phone number
- Returns `registrationId` for the next step

**Frontend Action:**
- Store the `registrationId`
- Redirect user to OTP verification screen
- Display input for 6-digit OTP code

---

### 2. Verify OTP (POST `/api/auth/verify-registration`)

**Request Body:**
```json
{
  "registrationId": "507f1f77bcf86cd799439011",
  "otp": "123456"
}
```

**Response (Success - 200):**
```json
{
  "message": "Registration completed successfully",
  "data": {
    "id": "507f1f77bcf86cd799439011",
    "name": "John Doe",
    "email": "john@example.com",
    "phone": "+1234567890",
    "image": "...",
    "role": {
      "id": "...",
      "name": "USER_ROLE"
    },
    "status": true,
    "createdAt": "...",
    "updatedAt": "..."
  },
  "jwt": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

**Response (Error - 400):**
```json
{
  "message": "Invalid OTP"
}
// or
{
  "message": "OTP has expired. Please request a new one."
}
```

**What happens:**
- Validates the OTP code
- Checks if OTP has expired
- Activates user account (`status: true`)
- Clears OTP fields from user document
- Generates JWT token
- Sends notification email to admins
- Returns user data and JWT

**Frontend Action:**
- Store JWT token in localStorage/secure storage
- Redirect user to home page/dashboard
- User is now logged in

---

### 3. Resend OTP (POST `/api/auth/resend-code`)

**Request Body:**
```json
{
  "registrationId": "507f1f77bcf86cd799439011"
}
```

**Response (Success - 200):**
```json
{
  "registrationId": "507f1f77bcf86cd799439011",
  "message": "OTP resent successfully"
}
```

**What happens:**
- Generates a new OTP
- Updates expiration time (5 minutes from now)
- Sends new OTP via SMS
- Previous OTP is invalidated

**Frontend Action:**
- Show success message
- Reset OTP input field
- Restart countdown timer

---

## Frontend Implementation Examples

### Flutter Implementation

#### Step 1: Signup Screen (Flutter)

**Model Class:**
```dart
class SignupRequest {
  final String name;
  final String email;
  final String phone;
  final String password;
  final String? image;
  final String? role;

  SignupRequest({
    required this.name,
    required this.email,
    required this.phone,
    required this.password,
    this.image,
    this.role,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'email': email,
    'phone': phone,
    'password': password,
    if (image != null) 'image': image,
    if (role != null) 'role': role,
  };
}

class SignupResponse {
  final String message;
  final String registrationId;

  SignupResponse({required this.message, required this.registrationId});

  factory SignupResponse.fromJson(Map<String, dynamic> json) {
    return SignupResponse(
      message: json['message'],
      registrationId: json['registrationId'],
    );
  }
}
```

**Service Method:**
```dart
import 'package:http/http.dart' as http;
import 'dart:convert';

class AuthService {
  final String baseUrl = 'https://your-api.com/api/auth';

  Future<SignupResponse> signup(SignupRequest request) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 201) {
        return SignupResponse.fromJson(jsonDecode(response.body));
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Registration failed');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}
```

**UI Implementation:**
```dart
class SignupScreen extends StatefulWidget {
  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isLoading = false;

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final request = SignupRequest(
        name: _nameController.text,
        email: _emailController.text,
        phone: _phoneController.text, // Format: +1234567890
        password: _passwordController.text,
      );

      final response = await _authService.signup(request);

      // Navigate to OTP verification screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => OTPVerificationScreen(
            registrationId: response.registrationId,
            phoneNumber: _phoneController.text,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Sign Up')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Name'),
              validator: (v) => v?.isEmpty ?? true ? 'Name is required' : null,
            ),
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            TextFormField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: 'Phone',
                hintText: '+1234567890',
              ),
              keyboardType: TextInputType.phone,
              validator: (v) => v?.isEmpty ?? true ? 'Phone is required' : null,
            ),
            TextFormField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
              validator: (v) {
                if (v?.isEmpty ?? true) return 'Password is required';
                if (v!.length < 6) return 'Password must be at least 6 characters';
                return null;
              },
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _handleSignup,
              child: _isLoading
                  ? CircularProgressIndicator()
                  : Text('Sign Up'),
            ),
          ],
        ),
      ),
    );
  }
}
```

#### Step 2: OTP Verification Screen (Flutter)

**Model Classes:**
```dart
class VerifyOTPRequest {
  final String registrationId;
  final String otp;

  VerifyOTPRequest({required this.registrationId, required this.otp});

  Map<String, dynamic> toJson() => {
    'registrationId': registrationId,
    'otp': otp,
  };
}

class User {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String image;
  final Role role;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.image,
    required this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'] ?? '',
      phone: json['phone'],
      image: json['image'],
      role: Role.fromJson(json['role']),
    );
  }
}

class Role {
  final String id;
  final String name;

  Role({required this.id, required this.name});

  factory Role.fromJson(Map<String, dynamic> json) {
    return Role(id: json['id'], name: json['name']);
  }
}

class VerifyOTPResponse {
  final String message;
  final User data;
  final String jwt;

  VerifyOTPResponse({
    required this.message,
    required this.data,
    required this.jwt,
  });

  factory VerifyOTPResponse.fromJson(Map<String, dynamic> json) {
    return VerifyOTPResponse(
      message: json['message'],
      data: User.fromJson(json['data']),
      jwt: json['jwt'],
    );
  }
}
```

**Service Methods:**
```dart
class AuthService {
  final String baseUrl = 'https://your-api.com/api/auth';

  Future<VerifyOTPResponse> verifyOTP(VerifyOTPRequest request) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/verify-registration'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 200) {
        return VerifyOTPResponse.fromJson(jsonDecode(response.body));
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Verification failed');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<void> resendOTP(String registrationId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/resend-code'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'registrationId': registrationId}),
      );

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to resend OTP');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}
```

**UI Implementation:**
```dart
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pinput/pinput.dart'; // Add to pubspec.yaml: pinput: ^2.2.0

class OTPVerificationScreen extends StatefulWidget {
  final String registrationId;
  final String phoneNumber;

  OTPVerificationScreen({
    required this.registrationId,
    required this.phoneNumber,
  });

  @override
  _OTPVerificationScreenState createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final _authService = AuthService();
  final _otpController = TextEditingController();
  
  bool _isLoading = false;
  bool _isResending = false;
  int _countdown = 300; // 5 minutes in seconds
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _timer?.cancel();
    _countdown = 300;
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() => _countdown--);
      } else {
        timer.cancel();
      }
    });
  }

  String get _countdownText {
    final minutes = _countdown ~/ 60;
    final seconds = _countdown % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _handleVerifyOTP() async {
    if (_otpController.text.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter 6-digit OTP')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final request = VerifyOTPRequest(
        registrationId: widget.registrationId,
        otp: _otpController.text,
      );

      final response = await _authService.verifyOTP(request);

      // Save JWT token
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('jwt', response.jwt);
      await prefs.setString('userId', response.data.id);

      // Navigate to home screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleResendOTP() async {
    setState(() => _isResending = true);

    try {
      await _authService.resendOTP(widget.registrationId);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('OTP resent successfully')),
      );
      
      _otpController.clear();
      _startCountdown();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      setState(() => _isResending = false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 56,
      height: 56,
      textStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: Text('Verify OTP')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Enter the 6-digit code sent to',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              widget.phoneNumber,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 32),
            Pinput(
              controller: _otpController,
              length: 6,
              defaultPinTheme: defaultPinTheme,
              focusedPinTheme: defaultPinTheme.copyWith(
                decoration: defaultPinTheme.decoration!.copyWith(
                  border: Border.all(color: Colors.blue),
                ),
              ),
              onCompleted: (pin) => _handleVerifyOTP(),
            ),
            SizedBox(height: 24),
            Text(
              'Code expires in: $_countdownText',
              style: TextStyle(color: _countdown < 60 ? Colors.red : Colors.grey),
            ),
            SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _handleVerifyOTP,
              child: _isLoading
                  ? CircularProgressIndicator()
                  : Text('Verify OTP'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
              ),
            ),
            SizedBox(height: 16),
            TextButton(
              onPressed: _isResending ? null : _handleResendOTP,
              child: _isResending
                  ? CircularProgressIndicator()
                  : Text('Resend OTP'),
            ),
          ],
        ),
      ),
    );
  }
}
```

**Dependencies for Flutter (pubspec.yaml):**
```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.1.0
  shared_preferences: ^2.2.2
  pinput: ^2.2.0  # For OTP input UI
```

---

### JavaScript/Web Implementation

#### Step 1: Signup Screen (JavaScript)
```javascript
const handleSignup = async (formData) => {
  try {
    const response = await fetch('/api/auth/signup', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(formData)
    });
    
    const data = await response.json();
    
    if (response.ok) {
      // Store registrationId
      localStorage.setItem('registrationId', data.registrationId);
      
      // Redirect to OTP verification
      navigate('/verify-otp');
    } else {
      // Show error message
      showError(data.message);
    }
  } catch (error) {
    showError('Registration failed');
  }
};
```

#### Step 2: OTP Verification Screen (JavaScript)
```javascript
const handleVerifyOTP = async (otp) => {
  try {
    const registrationId = localStorage.getItem('registrationId');
    
    const response = await fetch('/api/auth/verify-registration', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ registrationId, otp })
    });
    
    const data = await response.json();
    
    if (response.ok) {
      // Store JWT token
      localStorage.setItem('jwt', data.jwt);
      localStorage.removeItem('registrationId');
      
      // Redirect to home
      navigate('/home');
    } else {
      // Show error message
      showError(data.message);
    }
  } catch (error) {
    showError('Verification failed');
  }
};

const handleResendOTP = async () => {
  try {
    const registrationId = localStorage.getItem('registrationId');
    
    const response = await fetch('/api/auth/resend-code', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ registrationId })
    });
    
    const data = await response.json();
    
    if (response.ok) {
      showSuccess('OTP resent successfully');
      // Reset timer, clear input
    } else {
      showError(data.message);
    }
  } catch (error) {
    showError('Failed to resend OTP');
  }
};
```

## Important Notes

1. **User Status**: Users are created with `status: false` and only activated after OTP verification
2. **OTP Expiration**: OTP codes expire after 5 minutes
3. **Duplicate Registrations**: If a user tries to register again with same phone before verifying, their data is updated and a new OTP is sent
4. **Security**: Users cannot login until they verify their phone number
5. **Twilio**: Ensure Twilio credentials are properly configured in environment variables

## Environment Variables Required
```
TWILIO_ACCOUNT_SID=your_account_sid
TWILIO_AUTH_TOKEN=your_auth_token
TWILIO_PHONE_NUMBER=your_twilio_phone_number
```

## Error Handling

| Error | Status | Message |
|-------|--------|---------|
| Duplicate phone (active user) | 400 | "El registro está duplicado" |
| Invalid OTP | 400 | "Invalid OTP" |
| Expired OTP | 400 | "OTP has expired. Please request a new one." |
| User not found | 400 | "Registration not found" |
| Already verified | 400 | "User already verified. Please login." |
| Twilio error | 500 | "Failed to send OTP" |
