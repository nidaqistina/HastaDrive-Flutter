import 'package:chewie/chewie.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:video_player/video_player.dart';
import 'booking_page.dart';
import 'booking_page2.dart';
import 'cancel_booking_page.dart';
import 'ratings_reviews_page.dart'; // Ensure this import is correct
import 'customer_home_page.dart'; // Make sure you import your homepage

class OrderHistoryPage extends StatefulWidget {
  const OrderHistoryPage({super.key});

  @override
  _OrderHistoryPageState createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> {
  String selectedStatus = 'All'; // Selected status filter
  final List<String> statusOptions = [
    'All',
    'Incomplete',
    'Completed',
    'Cancelled'
  ];

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (canPop, result) {
        if (!canPop) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const CustomerHomePage()),
          );
        }
      },
      child: Scaffold(
        backgroundColor: Color.fromARGB(255, 245, 245, 245),
        appBar: AppBar(
          title: Text('Order History',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          centerTitle: true,
          backgroundColor: const Color(0xFF800000),
          foregroundColor: Colors.white,
        ),
        body: Column(
          children: [
            // Scrollable filter for status
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: statusOptions.map((String status) {
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedStatus = status;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0, vertical: 8.0),
                              margin: const EdgeInsets.only(right: 8.0),
                              decoration: BoxDecoration(
                                color: selectedStatus == status
                                    ? const Color.fromARGB(255, 130, 23, 23)
                                    : Colors.grey[200],
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              child: Text(
                                status,
                                style: TextStyle(
                                  color: selectedStatus == status
                                      ? const Color.fromARGB(255, 231, 231, 231)
                                      : Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 2),

            Text(
              'Notes! Cancellation Can Only Be Done A DAY Before Pickup Date',
              textAlign: TextAlign.left,
              style: TextStyle(fontSize: 12, color: Colors.redAccent),
            ),

            // Display bookings based on the selected status filter
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _fetchUserBookingsStream(statusFilter: selectedStatus),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No orders found.'));
                  }

                  final bookings = snapshot.data!.docs.map((doc) {
                    final bookingData = doc.data();
                    bookingData['orderId'] = doc.id;

                    if (bookingData['pickupDate'] is Timestamp) {
                      bookingData['pickupDate'] =
                          (bookingData['pickupDate'] as Timestamp).toDate();
                    }

                    if (bookingData['returnDate'] is Timestamp) {
                      bookingData['returnDate'] =
                          (bookingData['returnDate'] as Timestamp).toDate();
                    }

                    return bookingData;
                  }).toList();

                  return FutureBuilder<List<Map<String, dynamic>>>(
                    future: _addCarImagesToBookings(bookings),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(child: Text('No orders found.'));
                      }

                      final bookingsWithImages = snapshot.data!;
                      bookingsWithImages.sort((a, b) {
                        DateTime returnDateA = a['returnDate'];
                        DateTime returnDateB = b['returnDate'];
                        DateTime currentDate = DateTime.now();

                        bool isAIncompleteOrNear = a['status'] ==
                                'Incomplete' ||
                            returnDateA
                                .isBefore(currentDate.add(Duration(hours: 24)));
                        bool isBIncompleteOrNear = b['status'] ==
                                'Incomplete' ||
                            returnDateB
                                .isBefore(currentDate.add(Duration(hours: 24)));

                        if (isAIncompleteOrNear && !isBIncompleteOrNear) {
                          return -1;
                        }
                        if (!isAIncompleteOrNear && isBIncompleteOrNear) {
                          return 1;
                        }

                        return b['pickupDate'].compareTo(a['pickupDate']);
                      });

                      return ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: bookingsWithImages.length,
                        itemBuilder: (context, index) {
                          final booking = bookingsWithImages[index];
                          return OrderCard(
                            orderId: booking['orderId'] ?? '',
                            carName: booking['carName'] ?? 'Unknown Car',
                            pickupDate: _formatTimestamp(
                                booking['pickupDate'] ?? DateTime.now()),
                            returnDate: _formatTimestamp(
                                booking['returnDate'] ?? DateTime.now()),
                            status: booking['status'] ?? 'Unknown Status',
                            totalPrice:
                                (booking['totalPrice'] ?? 0).toStringAsFixed(2),
                            mainImage:
                                booking['mainImage'] ?? '', // Pass image URL
                            pickupLocation: booking['pickupLocation'] ?? '',
                            returnLocation: booking['returnLocation'] ?? '',
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _addCarImagesToBookings(
      List<Map<String, dynamic>> bookings) async {
    for (var booking in bookings) {
      try {
        final carDoc = await FirebaseFirestore.instance
            .collection('cars')
            .doc(booking['carName'])
            .get();

        if (carDoc.exists) {
          booking['mainImage'] = carDoc.data()?['mainImage'] ?? '';
        } else {
          booking['mainImage'] = ''; // Default or empty if no image
        }
      } catch (e) {
        booking['mainImage'] = ''; // Handle error with default or empty
      }
    }
    return bookings;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _fetchUserBookingsStream(
      {String? statusFilter}) {
    final userEmail = FirebaseAuth.instance.currentUser?.email;
    if (userEmail == null) {
      return Stream.empty();
    }

    var query = FirebaseFirestore.instance
        .collection('bookings')
        .where('customerEmail', isEqualTo: userEmail);

    if (statusFilter != null && statusFilter != 'All') {
      query = query.where('status', isEqualTo: statusFilter);
    }

    return query.snapshots();
  }

  String _formatTimestamp(DateTime timestamp) {
    final dateTime = timestamp;
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute}';
  }
}

class OrderCard extends StatefulWidget {
  final String orderId;
  final String carName;
  final String pickupDate;
  final String returnDate;
  final String status;
  final String totalPrice;
  final String mainImage; // New parameter for car image URL
  final String pickupLocation;
  final String returnLocation;

  const OrderCard({
    super.key,
    required this.orderId,
    required this.carName,
    required this.pickupDate,
    required this.returnDate,
    required this.status,
    required this.totalPrice,
    required this.mainImage,
    required this.pickupLocation,
    required this.returnLocation,
  });

  @override
  _OrderCardState createState() => _OrderCardState();
}

class _OrderCardState extends State<OrderCard> {
  bool hasReview = false; // Track whether a review exists
  Map<String, dynamic>? reviewData; // Store review details

  @override
  void initState() {
    super.initState();
    _checkForReview();
  }

  Future<void> _revertBooking(BuildContext context, String orderId) async {
    try {
      // Fetch the booking document
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

      // Update the booking status and include cancellation reason
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(orderId)
          .update({
        'status': 'Incomplete',
      });

      // Update the car's availability
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

        // Remove the cancelled booking dates
        bookedDates.removeWhere(
          (date) => date.isAfter(pickupDate) && date.isBefore(returnDate),
        );

        await FirebaseFirestore.instance
            .collection('cars')
            .doc(carName)
            .update({'bookedDates': bookedDates});
      }
    } catch (e) {
      throw Exception('Error during booking cancellation: $e');
    }
  }

  void _rateUs(BuildContext context, String bookingId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RatingsReviewsPage(
          orderId: bookingId,
          mainImage: widget.mainImage,
        ),
      ),
    );
    _checkForReview();
  }

  Future<void> _checkForReview() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('reviews')
          .where('orderId', isEqualTo: widget.orderId)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // Review exists
        setState(() {
          hasReview = true;
          reviewData = querySnapshot.docs.first.data(); // Retrieve review data

          if (reviewData?['rating'] != null) {
            reviewData!['rating'] = (reviewData!['rating'] as num).toInt();
          }
        });
      } else {
        // No review found
        setState(() {
          hasReview = false;
        });
      }
    } catch (e) {
      print('Error checking review: $e');
    }
  }

  void _showReviewDialog(double screenWidth, double screenHeight) {
    if (reviewData == null) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Your Review for ${widget.carName}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (reviewData?['rating'] != null)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: List.generate(
                      (reviewData!['rating'] as num).toInt(),
                      (index) => const Icon(
                        Icons.star,
                        color: Colors.amber,
                        size: 20.0,
                      ),
                    ),
                  ),
                SizedBox(height: screenHeight * 0.02),
                if (reviewData?['review'] != null)
                  Align(
                    alignment: Alignment.topLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${reviewData!['review']}',
                          textAlign: TextAlign.left,
                          style: TextStyle(fontSize: screenWidth * 0.035),
                        ),
                      ],
                    ),
                  ),
                SizedBox(height: screenHeight * 0.02),
                if ((reviewData?['videoUrl'] != null &&
                        reviewData?['videoUrl'] != '') ||
                    (reviewData?['imageUrl'] != null &&
                        reviewData?['imageUrl'] != ''))
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      if (reviewData?['videoUrl'] != null)
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => FullScreenViewer(
                                  mediaType: 'video',
                                  mediaUrl: reviewData!['videoUrl'],
                                ),
                              ),
                            );
                          },
                          child: Container(
                            width: screenWidth * 0.3,
                            height: screenWidth * 0.3,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.play_circle_fill,
                                color: Colors.grey,
                                size: screenWidth * 0.1,
                              ),
                            ),
                          ),
                        ),
                      SizedBox(width: 5),
                      if (reviewData?['imageUrl'] != null)
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => FullScreenViewer(
                                  mediaType: 'image',
                                  mediaUrl: reviewData!['imageUrl'],
                                ),
                              ),
                            );
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              reviewData!['imageUrl'],
                              width: screenWidth * 0.3,
                              height: screenWidth * 0.3,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                    ],
                  ),
                if (reviewData?['replies'] != null &&
                    reviewData!['replies'].isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12.0),
                      Text(
                        'Admin Reply:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: screenWidth * 0.04,
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        reviewData!['replies'],
                        style: TextStyle(fontSize: screenWidth * 0.035),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Close',
                style: TextStyle(
                  color: Colors.red,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final DateFormat inputFormat = DateFormat('d/M/yyyy \'at\' H:m');
    final DateFormat timeFormatter = DateFormat('dd MMM yyyy, hh:mm a');
    final DateTime pickupDateTime = inputFormat.parse(widget.pickupDate);
    final DateTime returnDateTime = inputFormat.parse(widget.returnDate);

    return Card(
      color: Colors.grey[300],
      margin: const EdgeInsets.only(bottom: 12.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // Car Image and Details in a Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Car Image
                (widget.mainImage.startsWith('http') ||
                        widget.mainImage.startsWith('https'))
                    ? Image.network(
                        widget.mainImage,
                        height: screenSize.height * 0.1,
                        width: screenSize.width * 0.2,
                        fit: BoxFit.fitWidth,
                      )
                    : Image.asset(
                        widget.mainImage,
                        height: screenSize.height * 0.1,
                        width: screenSize.width * 0.2,
                        fit: BoxFit.fitWidth,
                      ),
                SizedBox(width: screenWidth * 0.05), // Space between image and name
                // Car Name
                Text(
                    widget.carName.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
            //SizedBox(height: screenHeight * 0.01), // Space between name and details

            // Row for Details
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Order ID: ${widget.orderId}'),
                    Text(
                        'Pickup Time: ${timeFormatter.format(pickupDateTime)}'),
                    Text(
                        'Return Time: ${timeFormatter.format(returnDateTime)}'),
                    Text('Status: ${widget.status}'),
                    Text('Total Price: RM${widget.totalPrice}'),
                    Text('Pickup Location: ${widget.pickupLocation}'),
                    Text('Return Location: ${widget.returnLocation}'),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                if (widget.status == 'Incomplete') ...[
                  SizedBox(
                    width: screenWidth * 0.38,
                    height: screenHeight * 0.05,
                    child: ElevatedButton(
                      onPressed: () {
                        if (context.mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CancelBookingPage(
                                orderId: widget.orderId,
                                mainImage: widget.mainImage,
                              ),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(
                        'Cancel Booking',
                        style: TextStyle(fontSize: screenWidth * 0.035),
                      ),
                    ),
                  ),
                ],
                if (widget.status == 'Cancelled') ...[
                  SizedBox(
                    width: screenWidth * 0.38,
                    height: screenHeight * 0.05,
                    child: ElevatedButton(
                      onPressed: () => _revertBooking(context, widget.orderId),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(
                        'Revert Booking',
                        style: TextStyle(fontSize: screenWidth * 0.035),
                      ),
                    ),
                  ),
                ],
                if (widget.status == 'Completed') ...[
                  if (hasReview) ...[
                    SizedBox(
                      width: screenWidth * 0.38,
                      height: screenHeight * 0.05,
                      child: ElevatedButton(
                        onPressed: () =>
                            _showReviewDialog(screenWidth, screenHeight),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color.fromARGB(255, 231, 231, 231),
                          foregroundColor: Colors.black.withOpacity(0.8),
                        ),
                        child: Text(
                          'Your Review',
                          style: TextStyle(fontSize: screenWidth * 0.035),
                        ),
                      ),
                    ),
                  ] else ...[
                    SizedBox(
                      width: screenWidth * 0.25,
                      height: screenHeight * 0.05,
                      child: ElevatedButton(
                        onPressed: () {
                          if (context.mounted) {
                            _rateUs(context, widget.orderId);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 99, 15, 4),
                        ),
                        child: Text(
                          'Rate Us',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: screenWidth * 0.035,
                          ),
                        ),
                      ),
                    ),
                  ],
                  SizedBox(width: screenWidth * 0.03),
                  SizedBox(
                    width: screenHeight * 0.18,
                    height: screenHeight * 0.05,
                    child: ElevatedButton(
                      onPressed: () async {
                        final carDoc = await FirebaseFirestore.instance
                            .collection('cars')
                            .doc(widget.carName)
                            .get();

                        if (!carDoc.exists) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Car details not found')),
                          );
                          return;
                        }

                        final carData = carDoc.data();
                        if (carData != null) {
                          if (carData.containsKey('pricePerHour')) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BookingPage(
                                  carName: widget.carName,
                                  plateNo: carData['plateNo'] ?? 'N/A',
                                  carType: carData['type'] ?? 'N/A',
                                  gearType: carData['gear'] ?? 'N/A',
                                  seats: carData['seats'].toString(),
                                  pricePerDay: carData['pricePerDay'] ?? 0.0,
                                  pricePerHour: Map<String, double>.from(
                                      carData['pricePerHour']),
                                  mainImage: carData['mainImage'] ?? '',
                                ),
                              ),
                            );
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BookingPage2(
                                  carName: widget.carName,
                                  plateNo: carData['plateNo'] ?? 'N/A',
                                  carType: carData['type'] ?? 'N/A',
                                  gearType: carData['gear'] ?? 'N/A',
                                  seats: carData['seats'].toString(),
                                  pricePerDay: carData['pricePerDay'] ?? 0.0,
                                  mainImage: carData['mainImage'] ?? '',
                                ),
                              ),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                        foregroundColor: Colors.white,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.history, size: screenWidth * 0.04),
                          SizedBox(width: screenWidth * 0.02),
                          Text(
                            'Book Again',
                            style: TextStyle(fontSize: screenWidth * 0.035),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class FullScreenViewer extends StatelessWidget {
  final String mediaType; // 'image' or 'video'
  final String mediaUrl;

  const FullScreenViewer({
    super.key,
    required this.mediaType,
    required this.mediaUrl,
  });

  @override
  Widget build(BuildContext context) {
    if (mediaType == 'image') {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: InteractiveViewer(
            child: Image.network(mediaUrl, fit: BoxFit.contain),
          ),
        ),
      );
    } else if (mediaType == 'video') {
      final videoController = VideoPlayerController.networkUrl(
        Uri.parse(mediaUrl),
      );
      final chewieController = ChewieController(
        videoPlayerController: videoController,
        aspectRatio: 9 / 16,
        autoInitialize: true,
        looping: false,
        errorBuilder: (context, errorMessage) {
          return Center(child: Text('Error: $errorMessage'));
        },
      );

      return Scaffold(
        appBar: AppBar(),
        body: Chewie(controller: chewieController),
      );
    } else {
      return const SizedBox.shrink(); // Fallback
    }
  }
}
