// personal_info_page.dart
import 'package:flutter/material.dart';


class p1 extends StatelessWidget {
 
  @override
  Widget build(BuildContext context) {
    return  
    MaterialApp(
    title: 'Registration App',
    theme: ThemeData(
      fontFamily: 'Roboto',
      visualDensity: VisualDensity.adaptivePlatformDensity,
      primaryColor: _primaryColor,
      colorScheme: ColorScheme.fromSwatch(
        primarySwatch: _primarySwatch,
        accentColor: _accentColor,
      ),
    ),
      home: PersonalInfoPage(),
      debugShowCheckedModeBanner:false, // Set the PersonalInfoPage as the home widget
    );
  }
}



const Color _primaryColor = Colors.blueGrey;
const Color _secondaryColor = Colors.black87;
const Color _buttonColor = Colors.orangeAccent;
const Color _textColor = Colors.white;
const Color _textFieldFillColor = Colors.white70;
const Color _iconColor = Colors.blueGrey;
const Color _accentColor = Colors.orangeAccent;

const MaterialColor _primarySwatch = MaterialColor(
  0xFF37474F, // primary color value
  <int, Color>{
    50: Color(0xFFeceff1),
    100: Color(0xFFcfd8dc),
    200: Color(0xFFb0bec5),
    300: Color(0xFF90a4ae),
    400: Color(0xFF78909c),
    500: Color(0xFF607d8b),
    600: Color(0xFF546e7a),
    700: Color(0xFF455a64),
    800: Color(0xFF37474f),
    900: Color(0xFF263238),
  },
);

class PersonalInfoPage extends StatefulWidget {
  @override
  _PersonalInfoPageState createState() => _PersonalInfoPageState();
}

class _PersonalInfoPageState extends State<PersonalInfoPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _primaryColor, // Set the background color to match gradient
      body: SingleChildScrollView(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_primaryColor, _secondaryColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.only(top: 40, bottom: 30, right:16, left:16),
          

          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo and Title
              Center(
                child: Column(
                  children: [
                    // Replace with your logo
                     Image.asset(
                      'images/logo5.png', // Update with your image path
                      // height: 250,
                      width: 500, // Adjust height as needed
                      // Adjust width as needed
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Step 1: Personal Information',
                      style: TextStyle(
                        fontSize: 34,
                        color: _textColor,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    Text(
                      'Provide your personal information',
                      style: TextStyle(
                        color: _textColor.withOpacity(0.7),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 40),
              // Full Name Field
              TextFormField(
                controller: _fullNameController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: _textFieldFillColor,
                  hintText: 'Full Name',
                  prefixIcon: Icon(Icons.person, color: _iconColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your full name';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              // Email Address Field
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: _textFieldFillColor,
                  hintText: 'Email Address',
                  prefixIcon: Icon(Icons.email, color: _iconColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email address';
                  }
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              // Phone Number Field
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: _textFieldFillColor,
                  hintText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone, color: _iconColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your phone number';
                  }
                  return null;
                },
              ),
              SizedBox(height: 32),
              // Next Button
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState?.validate() ?? false) {
                    // Handle form submission
                    // Navigator.pushNamed(context, '/account-info'); // Uncomment when navigation is set up
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _buttonColor,
                  shadowColor: Colors.black45,
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 18),
                ),
                child: Text(
                  'Next',
                  style: TextStyle(fontSize: 18, color: _textColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

