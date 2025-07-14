import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:video_player/video_player.dart';
import 'all_reviews_page.dart';
import 'admin_reply_page.dart';

class HastaHomePage extends StatefulWidget {
  const HastaHomePage({super.key});

  @override
  _HastaHomePageState createState() => _HastaHomePageState();
}

class _HastaHomePageState extends State<HastaHomePage> {
  int _currentPage = 0;
  String _selectedYear = DateTime.now().year.toString();
  final List<String> _years = [];
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _initializeYears();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _initializeYears() {
    int currentYear = DateTime.now().year;
    for (int year = 2022; year <= currentYear; year++) {
      _years.add(year.toString());
    }
  }

  void _onYearChanged(String? newYear) {
    if (newYear != null) {
      setState(() {
        _selectedYear = newYear;
      });
    }
  }

  double _getMaxY(List<Map<String, dynamic>> carBookings) {
    double maxY = 0;
    for (var car in carBookings) {
      for (var value in car['monthlyBookings']) {
        if (value > maxY) {
          maxY = value;
        }
      }
    }
    return maxY;
  }

  Widget _ratingSectionPlaceholder(double screenWidth, double screenHeight) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                height: screenHeight * 0.06,
                margin: EdgeInsets.only(left: 16.0, right: 16.0),
                decoration: BoxDecoration(
                  color: Color.fromARGB(255, 19, 25, 37), // Background color
                  borderRadius: BorderRadius.circular(10.0), // Rounded corners
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Ratings and Review',
                  style: TextStyle(
                    fontSize: screenWidth * 0.05,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: screenHeight * 0.02),
          StreamBuilder<QuerySnapshot>(
            stream:
                FirebaseFirestore.instance.collection('reviews').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              //reviews and filter for those that have not been replied to
              var reviews = snapshot.data!.docs.where((review) {
                // Check if 'replies' exists and is not empty; otherwise, consider it as not replied
                final data = review.data() as Map<String, dynamic>;
                return !data.containsKey('replies') ||
                    data['replies'] == null ||
                    data['replies'].isEmpty;
              }).toList();
              reviews.sort((a, b) {
                return (a['rating'] as double).compareTo(b['rating'] as double);
              });

              // Get the bottom 3 reviews
              var bottomReviews = reviews.take(3).toList();

              return Column(
                children: [
                  // Display the bottom 3 reviews in cards
                  for (var review in bottomReviews)
                    Card(
                      margin:
                          EdgeInsets.symmetric(vertical: screenHeight * 0.01),
                      color: Colors.grey.shade200,
                      child: Padding(
                        padding: EdgeInsets.all(screenWidth * 0.03),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                FutureBuilder<DocumentSnapshot>(
                                  future: FirebaseFirestore.instance
                                      .collection('cars')
                                      .doc(review[
                                          'carName']) // Fetch based on carName
                                      .get(),
                                  builder: (context, carSnapshot) {
                                    if (!carSnapshot.hasData) {
                                      return const Center(
                                        child: CircularProgressIndicator(),
                                      );
                                    }

                                    var carData = carSnapshot.data!;
                                    var mainImage = carData['mainImage'] ?? '';

                                    return ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: (mainImage.startsWith('http') ||
                                              mainImage.startsWith('https'))
                                          ? Image.network(
                                              mainImage,
                                              width: 60,
                                              height: 60,
                                              fit: BoxFit.contain,
                                            )
                                          : Image.asset(
                                              mainImage,
                                              width: 60,
                                              height: 60,
                                              fit: BoxFit.contain,
                                            ),
                                    );
                                  },
                                ),
                                SizedBox(width: screenWidth * 0.04,),
                                Text(
                                  '${review['carName']}',
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.045,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: screenHeight * 0.01),
                            Text(
                              'By ${review['username']}',
                              style: TextStyle(fontSize: screenWidth * 0.04),
                            ),
                            SizedBox(height: screenHeight * 0.01),
                            RatingBarIndicator(
                              rating: review['rating'] ?? 0.0,
                              itemBuilder: (context, index) => Icon(
                                Icons.star,
                                color: Colors.amber,
                              ),
                              itemCount: 5,
                              itemSize: screenWidth * 0.06,
                              direction: Axis.horizontal,
                            ),
                            SizedBox(height: screenHeight * 0.01),
                            Text(
                              '${review['review']}',
                              style: TextStyle(fontSize: screenWidth * 0.04),
                            ),
                            SizedBox(height: screenHeight * 0.015),
                            if ((review['videoUrl'] != null &&
                                    review['videoUrl'] != '') ||
                                (review['imageUrl'] != null &&
                                    review['imageUrl'] != ''))
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  if (review['videoUrl'] != null &&
                                      review['videoUrl'] != '')
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                FullScreenViewer(
                                              mediaType: 'video',
                                              mediaUrl: review['videoUrl'],
                                            ),
                                          ),
                                        );
                                      },
                                      child: Container(
                                        width: screenWidth * 0.3,
                                        height: screenWidth * 0.3,
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade300,
                                          borderRadius:
                                              BorderRadius.circular(8),
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
                                  SizedBox(width: screenWidth * 0.02),
                                  if (review['imageUrl'] != null &&
                                      review['imageUrl'] != '')
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                FullScreenViewer(
                                              mediaType: 'image',
                                              mediaUrl: review['imageUrl'],
                                            ),
                                          ),
                                        );
                                      },
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          review['imageUrl'],
                                          width: screenWidth * 0.3,
                                          height: screenWidth * 0.3,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            Align(
                              alignment: Alignment.bottomRight,
                              child: TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => AdminReplyPage(
                                        reviewId: review.id,
                                        carName: review['carName'],
                                      ),
                                    ),
                                  );
                                },
                                child: Text(
                                  'Reply',
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.04,
                                    color: Color.fromARGB(255, 19, 25, 37),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  // View More button
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AllReviewsPage(),
                        ),
                      );
                    },
                    child: Text(
                      'View More',
                      style: TextStyle(
                        fontSize: screenWidth * 0.045,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 19, 25, 37),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.grey[300],
      appBar: AppBar(
        toolbarHeight: screenHeight * 0.1,
        backgroundColor: const Color.fromARGB(255, 19, 25, 37),
        title: Text(
          'Welcome Admin!',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      drawer: Drawer(
        backgroundColor: Colors.grey[300],
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Color.fromARGB(255, 19, 25, 37),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image.asset(
                    'assets/hasta2.png',
                    width: screenWidth * 0.25,
                  ),
                  SizedBox(height: screenHeight * 0.01),
                  Text(
                    'Hasta Admin',
                    style: TextStyle(
                      fontSize: screenWidth * 0.05,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title:
                  Text('Home', style: TextStyle(fontSize: screenWidth * 0.04)),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.bar_chart),
              title: Text('Car Inventory',
                  style: TextStyle(fontSize: screenWidth * 0.04)),
              onTap: () {
                Navigator.pushNamed(context, '/carInventory');
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: Text('Logout',
                  style: TextStyle(fontSize: screenWidth * 0.04)),
              onTap: () {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/logout',
                  (Route<dynamic> route) => false,
                );
              },
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.04,
          vertical: screenHeight * 0.02,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Total Cars and Sales with red icons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _statCard(
                  context,
                  screenWidth * 1.2,
                  screenHeight,
                  icon: Icons.car_rental,
                  title: 'Total Cars',
                  iconColor: Color.fromARGB(255, 19, 25, 37),
                  stream:
                      FirebaseFirestore.instance.collection('cars').snapshots(),
                  valueBuilder: (snapshot) => snapshot.docs.length.toString(),
                ),
                _statCard(
                  context,
                  screenWidth * 1.2,
                  screenHeight,
                  icon: Icons.attach_money,
                  title: 'Total Sales',
                  iconColor: Color.fromARGB(255, 19, 25, 37),
                  stream: FirebaseFirestore.instance
                      .collection('bookings')
                      .snapshots(),
                  valueBuilder: (snapshot) {
                    double totalSales = 0.0;
                    for (var doc in snapshot.docs) {
                      // Fix: Use .docs and .data() properly
                      totalSales +=
                          (doc.data() as Map<String, dynamic>)['totalPrice']
                              .toDouble();
                    }

                    // Format the total sales with commas and two decimal places
                    return 'RM ${NumberFormat('#,##0.00', 'en_US').format(totalSales)}';
                  },
                ),
              ],
            ),
            SizedBox(height: screenHeight * 0.015),
            // Year filter dropdown
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(),
                  child: Padding(
                    padding: EdgeInsets.all(screenWidth * 0.003),
                    child: DropdownButton<String>(
                      value: _selectedYear,
                      items: _years.map((year) {
                        return DropdownMenuItem(
                          value: year,
                          child: Text(year),
                        );
                      }).toList(),
                      onChanged: _onYearChanged,
                      underline: SizedBox(), // Removes default underline
                      icon: Icon(
                        Icons.arrow_drop_down, // Custom icon
                        color: Colors.black87,
                      ),
                      style: TextStyle(
                        color: Colors.black87, // Selected text color
                        fontSize: 16.0,
                      ),
                      dropdownColor: Colors
                          .grey.shade200, // Dropdown menu background color
                    ),
                  ),
                ),
              ],
            ),
            // Car Bookings Chart
            SizedBox(
              width: screenWidth < screenHeight ? screenWidth : screenHeight,
              height: screenWidth < screenHeight ? screenWidth : screenHeight,
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('bookings')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final bookingData = snapshot.data!.docs;
                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('cars')
                        .snapshots(),
                    builder: (context, carSnapshot) {
                      if (!carSnapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final carData = carSnapshot.data!.docs;
                      List<Map<String, dynamic>> carBookings = [];
                      for (var carDoc in carData) {
                        String carName = carDoc['name'];
                        String mainImage = carDoc['mainImage'];
                        List<double> monthlyBookings = List.filled(12, 0);
                        for (var bookingDoc in bookingData) {
                          if (bookingDoc['carName'] == carName &&
                              _getYearFromTimestamp(bookingDoc['pickupDate']) ==
                                  int.parse(_selectedYear)) {
                            int month = _getMonthFromTimestamp(
                                bookingDoc['pickupDate']);
                            monthlyBookings[month - 1] +=
                                bookingDoc['totalPrice'].toDouble();
                          }
                        }
                        carBookings.add({
                          'name': carName,
                          'mainImagef': mainImage,
                          'monthlyBookings': monthlyBookings,
                        });
                      }
                      double maxY = _getMaxY(carBookings);
                      List<Map<String, dynamic>> visibleCars =
                          carBookings.skip(_currentPage * 6).take(6).toList();
                      return Column(
                        children: [
                          Expanded(
                            child: Stack(
                              children: [
                                LineChart(
                                  LineChartData(
                                    maxY: maxY,
                                    lineBarsData: visibleCars.map((car) {
                                      List<Color> lineColors = [
                                        Color.fromARGB(255, 19, 25, 37),
                                        Color.fromARGB(255, 41, 54, 80),
                                        Color.fromARGB(255, 42, 65, 112),
                                        Color.fromARGB(255, 42, 85, 171),
                                        Color.fromARGB(255, 60, 116, 229),
                                        Color.fromARGB(255, 96, 149, 255),
                                      ];
                                      Color lineColor = lineColors[
                                          visibleCars.indexOf(car) %
                                              lineColors.length];

                                      return LineChartBarData(
                                        spots: (car['monthlyBookings']
                                                as List<double>)
                                            .asMap()
                                            .entries
                                            .map((entry) {
                                          return FlSpot(entry.key.toDouble(),
                                              entry.value);
                                        }).toList(),
                                        isCurved: false,
                                        color: lineColor,
                                        barWidth: 1.5,
                                        belowBarData: BarAreaData(show: false),
                                        dotData: FlDotData(
                                          show: true,
                                          getDotPainter:
                                              (spot, percent, barData, index) {
                                            return FlDotCrossPainter(
                                              size: 6,
                                              color: lineColor,
                                              width: 1, // thickness of cross
                                            );
                                          },
                                        ),
                                      );
                                    }).toList(),
                                    gridData: FlGridData(show: false),
                                    titlesData: FlTitlesData(
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          getTitlesWidget:
                                              (double value, TitleMeta meta) {
                                            List<String> monthNames = [
                                              'Jan',
                                              'Feb',
                                              'Mar',
                                              'Apr',
                                              'May',
                                              'Jun',
                                              'Jul',
                                              'Aug',
                                              'Sep',
                                              'Oct',
                                              'Nov',
                                              'Dec'
                                            ];

                                            String monthName =
                                                monthNames[value.toInt()];

                                            return SideTitleWidget(
                                              axisSide: meta.axisSide,
                                              space: 15.0,
                                              angle: 37,
                                              child: Text(
                                                monthName,
                                                style: TextStyle(
                                                  color: Colors.black,
                                                  fontSize: screenWidth * 0.03,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            );
                                          },
                                          interval: 1,
                                          reservedSize: 40,
                                        ),
                                      ),
                                      topTitles: AxisTitles(
                                        sideTitles:
                                            SideTitles(showTitles: false),
                                      ),
                                      rightTitles: AxisTitles(
                                        sideTitles:
                                            SideTitles(showTitles: false),
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 20,
                                  left: 70,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: visibleCars.map((car) {
                                      List<Color> legendColors = [
                                        Color.fromARGB(255, 19, 25, 37),
                                        Color.fromARGB(255, 41, 54, 80),
                                        Color.fromARGB(255, 42, 65, 112),
                                        Color.fromARGB(255, 42, 85, 171),
                                        Color.fromARGB(255, 60, 116, 229),
                                        Color.fromARGB(255, 96, 149, 255),
                                      ];
                                      Color legendColor = legendColors[
                                          visibleCars.indexOf(car) %
                                              legendColors.length];

                                      // Ensure 'carModel' is not null and provide a fallback value if it is
                                      String carModel = car['name'] ??
                                          'Unknown Car'; // Default fallback value

                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 5),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 10,
                                              height: 10,
                                              color: legendColor,
                                            ),
                                            SizedBox(width: screenWidth * 0.05),
                                            Text(
                                              carModel, // Use the fallback value if 'carModel' is null
                                              style: TextStyle(
                                                fontSize: screenWidth * 0.03,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_left),
                                onPressed: _currentPage > 0
                                    ? () {
                                        setState(() {
                                          _currentPage--;
                                        });
                                      }
                                    : null,
                              ),
                              IconButton(
                                icon: const Icon(Icons.arrow_right),
                                onPressed: ((_currentPage + 1) * 3 <
                                        carBookings.length)
                                    ? () {
                                        setState(() {
                                          _currentPage++;
                                        });
                                      }
                                    : null,
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
            _ratingSectionPlaceholder(screenWidth, screenHeight),
          ],
        ),
      ),
    );
  }

  // Helper methods
  int _getYearFromTimestamp(Timestamp timestamp) {
    return timestamp.toDate().year;
  }

  int _getMonthFromTimestamp(Timestamp timestamp) {
    return timestamp.toDate().month;
  }

  Widget _statCard(
    BuildContext context,
    double screenWidth,
    double screenHeight, {
    required IconData icon,
    required String title,
    required Color iconColor,
    required Stream<QuerySnapshot> stream,
    required String Function(QuerySnapshot snapshot) valueBuilder,
  }) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        String value = snapshot.hasData ? valueBuilder(snapshot.data!) : '...';
        return Card(
          color: Colors.grey.shade200,
          child: Padding(
            padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.05, vertical: screenHeight * 0.03),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: iconColor, size: screenWidth * 0.1),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: screenWidth * 0.05,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: screenWidth * 0.04,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Center(
          child: InteractiveViewer(
            panEnabled: true, // Allow panning
            boundaryMargin: const EdgeInsets.all(20.0),
            minScale: 0.5,
            maxScale: 5.0,
            child: Image.network(
              mediaUrl,
              fit: BoxFit.contain,
            ),
          ),
        ),
      );
    } else if (mediaType == 'video') {
      final videoController =
          VideoPlayerController.networkUrl(Uri.parse(mediaUrl));
      final chewieController = ChewieController(
        videoPlayerController: videoController,
        aspectRatio:
            9 / 16, // Default aspect ratio; dynamic adjustment possible
        autoInitialize: true,
        looping: false,
        errorBuilder: (context, errorMessage) {
          return Center(child: Text('Error: $errorMessage'));
        },
      );

      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Center(
          child: Chewie(controller: chewieController),
        ),
      );
    } else {
      return const SizedBox.shrink(); // Fallback for invalid mediaType
    }
  }
}
