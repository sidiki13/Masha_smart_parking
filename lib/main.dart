import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import 'payment_options_screen.dart'; // Import your existing screen

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: 'AIzaSyDFUn0GA10hXNgxypuWmRbrzELaDQ8rhv8',
      appId: '1:497800015115:android:ba6afa9df2451e29f0060e',
      messagingSenderId: '964212159005',
      projectId: 'mahsapark-9a3a7',
      measurementId: "G-989ENKDZ0B",
    ),
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mahsa Parking',
      theme: ThemeData(
        primaryColor: Color.fromARGB(255, 224, 219, 228),
        scaffoldBackgroundColor: Color(0xFFE0F7FA), // Light blue background
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color.fromARGB(255, 20, 14, 190),
            foregroundColor: Colors.white,
          ),
        ),
        textTheme: TextTheme(
          bodyMedium: TextStyle(fontSize: 18, color: Colors.black),
        ),
      ),
      home: WelcomeScreen(), // Start with the welcome screen
    );
  }
}

class WelcomeScreen extends StatefulWidget {
  @override
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final PageController _pageController = PageController();
  final List<String> _imagePaths = [
    'assets/welcome1.png',
    'assets/welcome2.png',
    'assets/welcome3.png',
    'assets/welcome4.png',
  ];

  int _currentIndex = 0;

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _getStarted() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => CarCheckScreen()), // Replace with your main screen
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFE0F7FA), // Light blue background
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: _imagePaths.length,
            onPageChanged: _onPageChanged,
            itemBuilder: (context, index) {
              return Image.asset(
                _imagePaths[index],
                fit: BoxFit.contain, // Use BoxFit.contain to fit the image
                width: double.infinity,
                height: double.infinity,
              );
            },
          ),
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Column(
              children: [
                if (_currentIndex == _imagePaths.length - 1)
                  ElevatedButton(
                    onPressed: _getStarted,
                    child: Text('Get Started'),
                  ),
                SmoothPageIndicator(
                  controller: _pageController,
                  count: _imagePaths.length,
                  effect: WormEffect(
                    dotHeight: 12,
                    dotWidth: 12,
                    activeDotColor: Colors.blue,
                    dotColor: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CarCheckScreen extends StatefulWidget {
  @override
  _CarCheckScreenState createState() => _CarCheckScreenState();
}

class _CarCheckScreenState extends State<CarCheckScreen> {
  final TextEditingController _plateController = TextEditingController();
  String? plateNumber;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(child: Text('Mahsa Parking')),
        backgroundColor: Color.fromARGB(255, 238, 238, 241),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 20),
              TextField(
                controller: _plateController,
                decoration: InputDecoration(
                  labelText: 'Enter License Plate Number',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    plateNumber = _plateController.text.trim();
                  });
                },
                child: Text('Check Car Status'),
              ),
              SizedBox(height: 20),
              if (plateNumber != null && plateNumber!.isNotEmpty)
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('cars')
                      .doc(plateNumber)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    } else if (!snapshot.hasData || !snapshot.data!.exists) {
                      return Text('No data available for this car.');
                    } else {
                      var carData = snapshot.data!.data() as Map<String, dynamic>;
                      
                      bool checkedInStatus = carData['checked_in'] ?? false;
                      bool checkedOutStatus = carData['checked_out'] ?? false;
                      bool paidStatus = carData['paid'] ?? false;

                      // Use default empty strings if the times are null
                      String checkedInTime = carData['checkin_time'] ?? '';
                      String checkedOutTime = carData['checkout_time'] ?? '';

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildInfoBox('Car Information', plateNumber ?? 'No plate number entered'),
                          _buildInfoBoxWithTime('Checked In', checkedInStatus ? 'Yes' : 'No', checkedInTime),
                          _buildInfoBoxWithTime('Checked Out', checkedOutStatus ? 'Yes' : 'No', checkedOutTime),
                          _buildInfoBoxWithTime('Paid', paidStatus ? 'Yes' : 'No', checkedOutTime),
                          if (!paidStatus)
                            ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => PaymentOptionsScreen()),
                                );
                              },
                              child: Text('Pay Now'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                            ),
                        ],
                      );
                    }
                  },
                ),
              SizedBox(height: 1),
              Center(
                child: Text(
                  'Welcome to Mahsa University!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 14, 190, 23),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoBox(String title, String content) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8.0),
      padding: EdgeInsets.all(10.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 3,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF007F4D),
            ),
          ),
          SizedBox(height: 10),
          Text(
            content,
            style: TextStyle(fontSize: 18, color: Colors.black),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBoxWithTime(String title, String content, String timeString) {
    String formattedTime = '';
    
    // Check if the timeString is not empty before formatting
    if (timeString.isNotEmpty) {
      DateTime dateTime = DateTime.parse(timeString);
      formattedTime = DateFormat('dd/MM/yy HH:mm').format(dateTime);
    }

    return Container(
      margin: EdgeInsets.symmetric(vertical: 8.0),
      padding: EdgeInsets.all(10.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 3,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF007F4D),
                ),
              ),
              SizedBox(height: 5),
              Text(
                content,
                style: TextStyle(fontSize: 18, color: Colors.black),
              ),
            ],
          ),
          Text(
            formattedTime,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
