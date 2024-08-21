import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class PaymentOptionsScreen extends StatefulWidget {
  @override
  _PaymentOptionsScreenState createState() => _PaymentOptionsScreenState();
}

class _PaymentOptionsScreenState extends State<PaymentOptionsScreen> {
  Map<String, dynamic>? paymentIntentData;

  @override
  void initState() {
    super.initState();
    Stripe.publishableKey = 'pk_test_51Pln5V090zoxmxdf9Fq8cV2X0u0OVUKErGqfGgHKJvSEvu3xCbDPU6bX2UIFF6VsJT6Nb20IejwKQAUdSL6vZgam00O2msDgxl'; // Add your Stripe publishable key here
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(child: Text('Payment Options')),
        backgroundColor: Color.fromARGB(255, 238, 238, 241),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton(
                onPressed: () {
                  _launchURL(context, 'https://www.mahsa.edu.my/epay/online-payment.php');
                },
                child: Text('Finance Link Payment'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  _showQRCodeDialog(context);
                },
                child: Text('QR Code Payment'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  _showCashPaymentDialog(context);
                },
                child: Text('Cash Payment'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  _payWithCard(context);
                },
                child: Text('Pay with Card'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Payment Status: ',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                'Payment Successful',
                style: TextStyle(fontSize: 18, color: Colors.green),
              ),
              Container(
                width: 250,
                child: ElevatedButton(
                  onPressed: () {
                    // Retry payment logic
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      'Just a friendly reminder: Parking entry fee is only: \n',
                      style: TextStyle(color: Colors.black, fontSize: 18),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    backgroundColor: Color.fromARGB(255, 248, 248, 245),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              SizedBox(height: 25),
            ],
          ),
        ),
      ),
    );
  }

  void _launchURL(BuildContext context, String url) async {
    Uri uri = Uri.parse(url);
    if (await canLaunch(uri.toString())) {
      await launch(uri.toString());
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch $url')),
      );
    }
  }

  void _showQRCodeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('QR Code Payment'),
        content: Text('Scan the QR code to make your payment.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showCashPaymentDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cash Payment'),
        content: Text('Please go to the Booth counter to pay in cash.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _payWithCard(BuildContext context) async {
    try {
      // Create payment intent on the server and get the client_secret
      paymentIntentData = await createPaymentIntent('3', 'myr'); // Adjust the amount and currency as needed
      if (paymentIntentData == null) {
        throw Exception("Failed to create payment intent");
      }

      // Use the client_secret obtained from the payment intent creation
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentIntentData!['client_secret'], // Correctly assign the dynamic client_secret here
          googlePay: PaymentSheetGooglePay(merchantCountryCode: 'MY'),
          style: ThemeMode.dark,
          merchantDisplayName: 'MAHSA University',
        ),
      );
      
      await displayPaymentSheet(context);

      // Update payment status in Firebase after successful payment
      if (paymentIntentData != null) {
        await _updatePaymentStatusInFirebase();
      }
    } catch (e) {
      print('Payment error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment failed: $e')),
      );
    }
  }

  displayPaymentSheet(BuildContext context) async {
    try {
      await Stripe.instance.presentPaymentSheet();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Payment successful")),
      );
    } catch (e) {
      print('Error presenting payment sheet: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Payment failed: $e")),
      );
    }
  }

  Future<Map<String, dynamic>> createPaymentIntent(String amount, String currency) async {
    try {
      Map<String, dynamic> body = {
        'amount': calculateAmount(amount),
        'currency': currency,
        'payment_method_types[]': 'card',
      };
      var response = await http.post(
        Uri.parse('https://api.stripe.com/v1/payment_intents'),
        headers: {
          'Authorization': 'Bearer sk_test_51Pln5V090zoxmxdf0W6QjGcTzMbB7RzeY2nTvLW4MFKaYGPO3o9YI7p9VvOYxKIZteso74jD4c8fW01G99N4Ygms00iktIeA1w', // Replace with your actual secret key
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: body,
      );

      if (response.statusCode != 200) {
        print('Error creating payment intent: ${response.body}');
        throw Exception('Failed to create payment intent');
      }

      return jsonDecode(response.body);
    } catch (err) {
      print('Error: $err');
      throw err;
    }
  }

  String calculateAmount(String amount) {
    final calculatedAmount = (int.parse(amount)) * 100;
    return calculatedAmount.toString();
  }

  Future<void> _updatePaymentStatusInFirebase() async {
    String plateNumber = "ABC123"; // Replace with the actual plate number
    try {
      await FirebaseFirestore.instance.collection('cars').doc(plateNumber).update({
        'paid': true,
        'paid_time': FieldValue.serverTimestamp(),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment status updated in Firebase.')),
      );
    } catch (e) {
      print('Failed to update payment status in Firebase: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update payment status in Firebase.')),
      );
    }
  }
}