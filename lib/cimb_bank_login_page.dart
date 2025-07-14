import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:math';

import 'package:hastadrive/customer_home_page.dart';

class CimbBankLoginPage extends StatefulWidget {
  final double totalPrice;
  final String bankName;
  final String? customerName;
  final String? customerEmail;
  final String? customerPhone;
  final String carName;
  final String carType;
  final String gearType;
  final String plateNo;
  final String seats;
  final DateTime? pickupDate;
  final DateTime? returnDate;
  final String pickupLocation;
  final String returnLocation;
  final List<Map<String, dynamic>> priceBreakdown;
  final int duration;

  const CimbBankLoginPage({
    super.key,
    required this.totalPrice,
    required this.bankName,
    this.customerName,
    this.customerEmail,
    this.customerPhone,
    required this.carName,
    required this.carType,
    required this.gearType,
    required this.plateNo,
    required this.seats,
    this.pickupDate,
    this.returnDate,
    required this.pickupLocation,
    required this.returnLocation,
    required this.priceBreakdown,
    required this.duration,
  });

  @override
  _CimbBankLoginPageState createState() => _CimbBankLoginPageState();
}

class _CimbBankLoginPageState extends State<CimbBankLoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _tacController = TextEditingController();

  String generatedTacCode = '';
  bool isLoginSuccessful = false;
  bool isTacVisible = false;
  bool isTacResent = false;

  @override
  void initState() {
    super.initState();
    setupBookingStatusListener(); // Start listening for booking updates
  }

  /// Simulate the login process
  Future<void> _processLogin() async {
    if (_usernameController.text.isNotEmpty &&
        _passwordController.text.isNotEmpty) {
      // Simulate login delay
      await Future.delayed(const Duration(seconds: 2));
      setState(() {
        isLoginSuccessful = true;
        isTacVisible = false; // Reset TAC visibility
        isTacResent = false;
      });

      // Generate a secure TAC code
      generatedTacCode = (Random().nextInt(900000) + 100000).toString();

      // Update order status for the logged-in user
      //await _updateOrderStatus();

      // Show the TAC code in a pop-up window
      _showTacDialog();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your username and password.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Show TAC code in a pop-up dialog
  void _showTacDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Secure TAC Code'),
          content: Text(
            'Your secure TAC code is: $generatedTacCode',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Dismiss the dialog
                setState(() {
                  isTacVisible = true; // Show the TAC input field
                });
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  /// Simulate the payment process
  Future<void> _processPayment() async {
    if (_tacController.text == generatedTacCode) {
      setState(() {
        isLoginSuccessful = true;
      });
      _showPaymentSuccess();
      await _confirmBooking(context);

      await Future.delayed(const Duration(seconds: 1));
      Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const CustomerHomePage()),
      (route) => false,
    );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid TAC code. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Display a payment success message
  void _showPaymentSuccess() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.check_circle, color: Colors.green, size: 50),
              SizedBox(height: 10),
              Text(
                'Payment Successful!',
                style: TextStyle(fontSize: 20, color: Colors.green),
              ),
            ],
          ),
        );
      },
    );
  }

  void setupBookingStatusListener() {
    final userEmail = FirebaseAuth.instance.currentUser?.email;

    if (userEmail == null) {
      print("User not logged in");
      return;
    }

    FirebaseFirestore.instance
        .collection('bookings')
        .where('customerEmail', isEqualTo: userEmail)
        .where('status',
            isNotEqualTo: 'Cancelled') // Exclude cancelled bookings
        .snapshots()
        .listen((snapshot) {
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final returnDate = (data['returnDate'] as Timestamp).toDate();
        final currentDate = DateTime.now();
        final newStatus =
            returnDate.isBefore(currentDate) ? 'Completed' : 'Incomplete';

        if (data['status'] != newStatus) {
          doc.reference.update({'status': newStatus}).catchError((error) {
            print("Failed to update booking status: $error");
          });
        }
      }
    }, onError: (error) {
      print("Error listening to booking updates: $error");
    });
  }

  /// Confirm booking and add details to Firebase Firestore
  Future<void> _confirmBooking(BuildContext context) async {
    try {
      // Get the current user
      User? user = FirebaseAuth.instance.currentUser;

      // Add booking details to Firestore with the current time as the bookedDate
      final bookingRef =
          FirebaseFirestore.instance.collection('bookings').doc();
      await bookingRef.set({
        'carName': widget.carName,
        'plateNo': widget.plateNo,
        'carType': widget.carType,
        'gearType': widget.gearType,
        'seats': widget.seats,
        'pickupDate': widget.pickupDate,
        'returnDate': widget.returnDate,
        'customerName': widget.customerName,
        'customerEmail': widget.customerEmail,
        'customerPhone': widget.customerPhone,
        'priceBreakdown': widget.priceBreakdown,
        'totalPrice': widget.totalPrice,
        'pickupLocation': widget.pickupLocation,
        'returnLocation': widget.returnLocation,
        'duration' : widget.duration,
        'userId': user?.uid, // Add user ID to the booking document
        'bookedDate': DateTime.now(), // Set the booked date to the current time
        'status': 'Incomplete',
      });

      // Notify the user about booking success
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking Successful!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  /// Resend the TAC code to the user and show it in a dialog
  void _resendTacCode() {
    setState(() {
      generatedTacCode = (Random().nextInt(900000) + 100000).toString();
      isTacResent = true; // Mark that TAC has been resent
      _tacController.clear(); // Clear the old TAC input
    });

    // Show the new TAC code in a pop-up dialog
    _showTacDialog();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.bankName == 'CIMB Octo'
            ? 'CIMB Octo Login'
            : 'Maybank2u Login'),
        backgroundColor: widget.bankName == 'CIMB Octo'
            ? const Color.fromARGB(255, 225, 32, 39)
            : const Color.fromARGB(255, 252, 186, 3),
      ),
      body: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: widget.bankName == 'CIMB Octo'
                ? const Color.fromARGB(255, 225, 32, 39)
                : const Color.fromARGB(255, 252, 186, 3),
            width: 5,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Image.asset(
              widget.bankName == 'CIMB Octo'
                  ? 'assets/cimb_logo.png'
                  : 'assets/maybank_logo.png',
              height: 80,
            ),
            const SizedBox(height: 20),
            Text(
              'Total Price: RM${widget.totalPrice.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            if (!isLoginSuccessful)
              Column(
                children: [
                  TextField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      hintText: 'Enter your username',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      hintText: 'Enter your password',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _processLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.bankName == 'CIMB Octo'
                          ? const Color.fromARGB(255, 225, 32, 39)
                          : const Color.fromARGB(255, 252, 186, 3),
                    ),
                    child: const Text(
                      'Login and Proceed to Payment',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ],
              ),
            if (isTacVisible)
              Column(
                children: [
                  const SizedBox(height: 10),
                  TextField(
                    controller: _tacController,
                    decoration: const InputDecoration(
                      labelText: 'Secure TAC Code',
                      hintText: 'Enter the 6-digit TAC',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _processPayment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.bankName == 'CIMB Octo'
                          ? const Color.fromARGB(255, 225, 32, 39)
                          : const Color.fromARGB(255, 252, 186, 3),
                    ),
                    child: const Text(
                      'Submit TAC and Pay',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (!isTacResent)
                    ElevatedButton(
                      onPressed: _resendTacCode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.bankName == 'CIMB Octo'
                            ? const Color.fromARGB(255, 225, 32, 39)
                            : const Color.fromARGB(255, 252, 186, 3),
                      ),
                      child: const Text(
                        'Resend TAC Code',
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
