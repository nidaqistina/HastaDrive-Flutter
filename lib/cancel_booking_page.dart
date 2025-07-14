import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'order_history_page.dart';

class CancelBookingPage extends StatefulWidget {
  final String orderId;
  final String mainImage;

  const CancelBookingPage({
    super.key,
    required this.orderId,
    required this.mainImage,
  });

  @override
  _CancelBookingPageState createState() => _CancelBookingPageState();
}

class _CancelBookingPageState extends State<CancelBookingPage> {
  String? customerName;
  String? customerPhone;
  String? carName;
  double? totalPrice;
  int? duration;

  String? _selectedReason;
  final List<String> _cancellationReasons = [
    'Found a better deal',
    'Changes of plan',
    'Booking by mistake',
    'Other',
  ];

  bool isCancelled = false; // Track if booking is cancelled

  @override
  void initState() {
    super.initState();
    _fetchCustomerDetails();
  }

  Future<void> _fetchCustomerDetails() async {
    try {
      final bookingDoc = await FirebaseFirestore.instance
          .collection('bookings')
          .doc(widget.orderId)
          .get();

      if (bookingDoc.exists) {
        final bookings = bookingDoc.data()!;
        setState(() {
          customerName = bookings['customerName'];
          customerPhone = bookings['customerPhone'];
          carName = bookings['carName'];
          totalPrice = bookings['totalPrice'];
          duration = bookings['duration'];
          isCancelled = bookings['status'] == 'Cancelled';
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking not found')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching booking data: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 130, 23, 23),
        foregroundColor: Colors.white,
        title: Text('Cancellation Page'),
      ),
      body: customerName == null || customerPhone == null || carName == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Color.fromARGB(255, 130, 23, 23),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Booking Information:',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Row(
                            children: [
                              (widget.mainImage.startsWith('http') ||
                                      widget.mainImage.startsWith('https'))
                                  ? Image.network(
                                      widget.mainImage,
                                      height: 80,
                                      width: 80,
                                      fit: BoxFit.contain,
                                    )
                                  : Image.asset(
                                      widget.mainImage,
                                      height: 80,
                                      width: 80,
                                      fit: BoxFit.contain,
                                    ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Name: $customerName',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      'Phone: $customerPhone',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      'Car Name: $carName',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      'Rent Duration: $duration hours',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      'Total Price: RM${totalPrice?.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Please select a reason for cancellation:',
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 10),
                    ..._cancellationReasons.map((reason) {
                      return RadioListTile<String>(
                        fillColor: WidgetStatePropertyAll(Color.fromARGB(255, 130, 23, 23)),
                        title: Text(reason),
                        value: reason,
                        groupValue: _selectedReason,
                        onChanged: (String? value) {
                          setState(() {
                            _selectedReason = value;
                          });
                        },
                      );
                    }),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _selectedReason == null
                          ? null
                          : () {
                              _showConfirmationDialog(context);
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Confirm Cancellation'),
                    ),
                    if (isCancelled) ...[
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          _showRevertConfirmationDialog(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Revert Cancellation'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  void _showRevertConfirmationDialog(BuildContext parentContext) {
    showDialog(
      context: parentContext,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Revert Cancellation Confirmation'),
          content: const Text(
              'Are you sure you want to revert this cancellation and make the booking available again?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _performRevertCancellation(context);
              },
              child: const Text('OK'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _performRevertCancellation(BuildContext context) async {
    try {
      await _revertCancellation(context, widget.orderId);
      if (mounted) {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (context) => OrderHistoryPage()));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error during revert: $e')),
        );
      }
    }
  }

  Future<void> _revertCancellation(BuildContext context, String orderId) async {
    try {
      final bookingDoc = await FirebaseFirestore.instance
          .collection('bookings')
          .doc(orderId)
          .get();

      if (!bookingDoc.exists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Booking not found')),
          );
        }
        return;
      }

      final bookingData = bookingDoc.data()!;
      DateTime pickupDate = (bookingData['pickupDate'] as Timestamp).toDate();
      DateTime returnDate = (bookingData['returnDate'] as Timestamp).toDate();
      String carName = bookingData['carName'];

      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(orderId)
          .update({
        'status': 'Incomplete',
        'cancellationReason': null,
      });

      final carDoc = await FirebaseFirestore.instance
          .collection('cars')
          .doc(carName)
          .get();

      if (carDoc.exists) {
        List<DateTime> bookedDates = [];
        if (carDoc.data()!['bookedDates'] != null) {
          bookedDates = List<DateTime>.from(
            (carDoc.data()!['bookedDates'] as List<dynamic>)
                .map((e) => (e as Timestamp).toDate()),
          );
        }

        bookedDates.addAll([pickupDate, returnDate]);

        await FirebaseFirestore.instance
            .collection('cars')
            .doc(carName)
            .update({'bookedDates': bookedDates});
      }
    } catch (e) {
      throw Exception('Error during revert cancellation: $e');
    }
  }

  void _showConfirmationDialog(BuildContext parentContext) {
    showDialog(
      context: parentContext,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.grey[300],
          title: const Text('Cancel Confirmation'),
          content: const Text('Are you sure you want to cancel your booking?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _performCancellation(parentContext);
              },
              child: const Text('OK', style: TextStyle(color: Color.fromARGB(255, 130, 23, 23)),),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel', style: TextStyle(color: Colors.red),),
            ),
          ],
        );
      },
    );
  }

  void _performCancellation(BuildContext context) async {
    try {
      await _cancelBooking(context, widget.orderId);
      if (mounted) {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (context) => OrderHistoryPage()));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error during cancellation: $e')),
        );
      }
    }
  }

  Future<void> _cancelBooking(BuildContext context, String orderId) async {
    try {
      final bookingDoc = await FirebaseFirestore.instance
          .collection('bookings')
          .doc(orderId)
          .get();

      if (!bookingDoc.exists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Booking not found')),
          );
        }
        return;
      }

      final bookingData = bookingDoc.data()!;
      DateTime pickupDate = (bookingData['pickupDate'] as Timestamp).toDate();
      DateTime returnDate = (bookingData['returnDate'] as Timestamp).toDate();
      String carName = bookingData['carName'];

      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(orderId)
          .update({
        'status': 'Cancelled',
        'cancellationReason': _selectedReason,
      });

      final carDoc = await FirebaseFirestore.instance
          .collection('cars')
          .doc(carName)
          .get();

      if (carDoc.exists) {
        List<DateTime> bookedDates = [];
        if (carDoc.data()!['bookedDates'] != null) {
          bookedDates = List<DateTime>.from(
            (carDoc.data()!['bookedDates'] as List<dynamic>)
                .map((e) => (e as Timestamp).toDate()),
          );
        }

        bookedDates.removeWhere(
          (date) => date.isAtSameMomentAs(pickupDate) ||
              date.isAtSameMomentAs(returnDate),
        );

        await FirebaseFirestore.instance
            .collection('cars')
            .doc(carName)
            .update({'bookedDates': bookedDates});
      }
    } catch (e) {
      throw Exception('Error during cancellation: $e');
    }
  }
}
