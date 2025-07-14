//agreement_confirmation_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; 
import 'payment_page.dart';

class AgreementConfirmationPage extends StatelessWidget {
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

  const AgreementConfirmationPage({
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
    required String customPickupLocation,
    required String customReturnLocation,
    required this.priceBreakdown,
    required this.duration,
  });
  
@override
Widget build(BuildContext context) {
  final size = MediaQuery.of(context).size;
  // Format the pickup and return dates to show only up to minutes
    String formattedPickupDate = pickupDate != null 
      ? DateFormat('dd-MM-yyyy HH:mm').format(pickupDate!) 
      : 'N/A';
    String formattedReturnDate = returnDate != null 
      ? DateFormat('dd-MM-yyyy HH:mm').format(returnDate!) 
      : 'N/A';

  return Scaffold(
    backgroundColor: Colors.grey.shade200,
    appBar: AppBar(
      title: const Text('Booking Agreement'),
      backgroundColor: Color.fromARGB(255, 130, 23, 23),
      foregroundColor: Colors.white,),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: SizedBox(
              width: size.width * 0.9,
              child: Card(
                color: Color.fromARGB(255, 225, 225, 225),
                elevation: 2.0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Customer Details:',
                        style: TextStyle(
                            color: Color.fromARGB(255, 130, 23, 23),
                            fontSize: size.width * 0.045,
                            fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8.0),
                      Text('Name: $customerName',
                          style: TextStyle(
                            color: Color.fromARGB(255, 130, 23, 23),
                            fontSize: size.width * 0.045,
                          )),
                      Text('Email: $customerEmail',
                          style: TextStyle(
                            color: Color.fromARGB(255, 130, 23, 23),
                            fontSize: size.width * 0.045,
                          )),
                      Text('Phone: $customerPhone',
                          style: TextStyle(
                            color: Color.fromARGB(255, 130, 23, 23),
                            fontSize: size.width * 0.045,
                          )),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: size.height * 0.01),
          Center(
              child: SizedBox(
            width: size.width * 0.9,
            child: Card(
              color: Color.fromARGB(255, 130, 23, 23),
              elevation: 2.0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Car Details',
                        style: TextStyle(
                            color: Color.fromARGB(255, 225, 225, 225),
                            fontSize: size.width * 0.045,
                            fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: size.height * 0.005),
                      Text('Car Name: $carName',
                          style: const TextStyle(
                              fontSize: 16.0,
                              color: Color.fromARGB(255, 225, 225, 225))),
                      Text('Plate No.: $plateNo',
                          style: const TextStyle(
                              fontSize: 16.0,
                              color: Color.fromARGB(255, 225, 225, 225))),
                      Text('Car Type: $carType',
                          style: const TextStyle(
                              fontSize: 16.0,
                              color: Color.fromARGB(255, 225, 225, 225))),
                      Text('Gear Type: $gearType',
                          style: const TextStyle(
                              fontSize: 16.0,
                              color: Color.fromARGB(255, 225, 225, 225))),
                      Text('Seats: $seats',
                          style: const TextStyle(
                              fontSize: 16.0,
                              color: Color.fromARGB(255, 225, 225, 225))),
                    ],
                  )),
            ),
          )),
          SizedBox(height: size.height * 0.02),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: size.width * 0.03),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Booking Details',
                  style: TextStyle(
                      fontSize: size.width * 0.05, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: size.height * 0.01),
                Text('Pickup Location: $pickupLocation',
            style: const TextStyle(fontSize: 16.0)),
        Text('Pickup Date & Time: $formattedPickupDate',
            style: const TextStyle(fontSize: 16.0)),
        Text('Return Location: $returnLocation',
            style: const TextStyle(fontSize: 16.0)),
        Text('Return Date & Time: $formattedReturnDate',
            style: const TextStyle(fontSize: 16.0)),
              ],
            ),
          ),
          SizedBox(height: size.height * 0.02),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: size.width * 0.03),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Price Breakdown',
                  style: TextStyle(
                      fontSize: size.width * 0.05, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: size.height * 0.01),
                ...priceBreakdown.map((item) => Padding(
                      padding:
                          EdgeInsets.symmetric(vertical: size.width * 0.015),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            item['description'],
                            style: TextStyle(fontSize: size.width * 0.03),
                          ),
                          Text(
                            'RM${item['amount'].toStringAsFixed(2)}',
                            style: TextStyle(fontSize: size.width * 0.03),
                          ),
                        ],
                      ),
                    )),
              ], 
            ),
          ),
          const Divider(thickness: 1.5),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: size.width * 0.03),
            child: Text(
              'Total Price: RM${totalPrice.toStringAsFixed(2)}',
              style: TextStyle(
                  fontSize: size.width * 0.05, fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(height: size.height * 0.02),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: size.width * 0.03),
            child: const Text(
              'Note: If there is any damage to the car, you are responsible for paying for the service charge.',
              style: TextStyle(color: Colors.red),
            ),
          ),
          SizedBox(height: size.height * 0.02),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: size.width * 0.03),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromARGB(255, 130,23,23)
                ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PaymentPage(
                      carName: carName,
                      plateNo: plateNo,
                      carType: carType,
                      gearType: gearType,
                      seats: seats,
                      pickupDate: pickupDate!,
                      returnDate: returnDate!,
                      customerName: customerName ?? '',
                      customerEmail: customerEmail ?? '',
                      customerPhone: customerPhone ?? '',
                      pickupLocation: pickupLocation,
                      returnLocation: returnLocation,
                      totalPrice: totalPrice,
                      priceBreakdown: priceBreakdown,
                      duration: duration,
                    ),
                  ),
                );
              },
              child: Text('I Agree to the Terms and Conditions',
              style: TextStyle(fontSize: size.width * 0.04,
                  color: Color.fromARGB(255, 225,225,225)
                  )
                  ),
            ),
          ),
        ],
      ),
    ),
  );
}
}