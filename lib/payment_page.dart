import 'package:flutter/material.dart';
import 'cimb_bank_login_page.dart';

class PaymentPage extends StatefulWidget {
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
  final double totalPrice;
  final List<Map<String, dynamic>> priceBreakdown;
  final int duration;

  const PaymentPage({
    super.key,
    required this.customerName,
    required this.customerEmail,
    required this.customerPhone,
    required this.carName,
    required this.carType,
    required this.gearType,
    required this.plateNo,
    required this.seats,
    required this.pickupDate,
    required this.returnDate,
    required this.pickupLocation,
    required this.returnLocation,
    required this.totalPrice,
    required this.priceBreakdown,
    required this.duration,
  });

  @override
  _PaymentPageState createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  String? selectedBank;

  List<Map<String, String>> banks = [
    {'name': 'Maybank2u', 'logo': 'assets/maybank_logo2.png'},
    {'name': 'CIMB Octo', 'logo': 'assets/cimb_logo.png'},
  ];

  void _navigateToBankLoginPage() {
    if (selectedBank != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CimbBankLoginPage(
            totalPrice: widget.totalPrice,
            bankName: selectedBank!,
            customerName: widget.customerName,
            customerEmail: widget.customerEmail,
            customerPhone: widget.customerPhone,
            carName: widget.carName,
            carType: widget.carType,
            gearType: widget.gearType,
            plateNo: widget.plateNo,
            seats: widget.seats,
            pickupDate: widget.pickupDate,
            returnDate: widget.returnDate,
            pickupLocation: widget.pickupLocation,
            returnLocation: widget.returnLocation,
            priceBreakdown: widget.priceBreakdown,
            duration: widget.duration,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a bank before proceeding.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      appBar: AppBar(
        title: const Text('Payment Page'),
        backgroundColor: Color.fromARGB(255, 130, 23, 23),
        foregroundColor: Colors.white,),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start, // Align everything to the start (left)
          children: [
            Text(
              'Total Price: RM${widget.totalPrice.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: size.height * 0.04),
            const Text(
              'Choose Payment Method:',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: size.height * 0.01),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  selectedBank = null;
                });
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text('Select Bank'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: banks.map((bank) {
                          return ListTile(
                            leading: Image.asset(
                              bank['logo']!,
                              width: 24,
                              height: 24,
                              fit: BoxFit.cover,
                            ),
                            title: Text(bank['name']!),
                            onTap: () {
                              setState(() {
                                selectedBank = bank['name'];
                              });
                              Navigator.pop(context);
                            },
                          );
                        }).toList(),
                      ),
                    );
                  },
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 255, 255,
                    255), // Set the dropdown button color to white
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.account_balance,
                      color: Color.fromARGB(255, 130, 23, 23)),
                  const SizedBox(width: 8),
                  const Text('Online Banking',
                      style:
                          TextStyle(color: Color.fromARGB(255, 130, 23, 23))),
                ],
              ),
            ),
            SizedBox(height: size.height * 0.035),
            if (selectedBank != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment
                    .start, // Align everything in the new column to the start
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const Text(
                        'Selected Bank:',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(width: size.width * 0.02),
                      Image.asset(
                        selectedBank == 'Maybank2u'
                            ? 'assets/maybank_logo2.png'
                            : 'assets/cimb_logo.png',
                        width: 24,
                        height: 24,
                        fit: BoxFit.cover,
                      ),
                      SizedBox(width: size.width * 0.02),
                      Text(
                        selectedBank!,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                  SizedBox(height: size.height * 0.01),
                  Align(
                    alignment: Alignment.topLeft,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Color.fromARGB(255, 130, 23, 23)),
                      onPressed: _navigateToBankLoginPage,
                      child: const Text(
                        'Pay',
                        style: TextStyle(
                            color: Color.fromARGB(255, 225, 225, 225)),
                      ),
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
