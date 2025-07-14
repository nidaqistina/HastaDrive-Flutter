import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'booking_page.dart';
import 'booking_page2.dart';
import 'order_history_page.dart';
import 'profile_page.dart';
import 'car_details_page.dart';

final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

class CustomerHomePage extends StatefulWidget {
  const CustomerHomePage({super.key});

  @override
  _CustomerHomePageState createState() => _CustomerHomePageState();
}

class _CustomerHomePageState extends State<CustomerHomePage> with RouteAware {
  String carType = 'Car Type';
  String gearType = 'Gear Type';
  String numberOfSeats = 'No of Seats';
  bool isFilterVisible = false;
  String searchQuery = '';
  int _currentIndex = 0;
  String? userId;

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });

    switch (index) {
      case 0:
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const OrderHistoryPage()),
        );
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ProfilePage()),
        );
        break;
    }
  }

  // Reset _currentIndex when returning to the home page
  @override
  void didPopNext() {
    // This method is triggered when you return to this page after navigating away
    setState(() {
      _currentIndex = 0; // Reset to Home tab
    });
  }

  // Subscribe to the RouteObserver
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  // Unsubscribe from the RouteObserver when the page is disposed
  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  Future<double> _calculateAverageRating(String plateNumber) async {
    final reviews = await FirebaseFirestore.instance
        .collection('reviews')
        .where('plateNumber', isEqualTo: plateNumber)
        .get();

    if (reviews.docs.isEmpty) {
      return 0.0; // No reviews
    }

    final ratings =
        reviews.docs.map((doc) => (doc.data()['rating'] ?? 0) as num).toList();

    final averageRating = ratings.reduce((a, b) => a + b) / ratings.length;
    return averageRating.toDouble();
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
    required IconData icon,
    required BoxConstraints constraints,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                items: items.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(
                      value,
                      style: TextStyle(
                        color: value == items.first
                            ? Colors.grey.shade600
                            : Colors.black87,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: onChanged,
                icon: Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;

    return Scaffold(
      backgroundColor: Color.fromARGB(255, 245, 245, 245),
      appBar: AppBar(
        toolbarHeight: screenWidth * 0.25,
        backgroundColor: const Color.fromARGB(255, 128, 0, 0),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // Search Field
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search by Car Name', // Placeholder text
                  hintStyle: TextStyle(
                    color:
                        Colors.grey[700], // Adjust the color of the hint text
                    fontSize: screenWidth * 0.035,
                    fontWeight: FontWeight.w600,
                  ),
                  filled: true,
                  fillColor: const Color.fromARGB(255, 231, 231, 231),
                  prefixIcon: Icon(
                    Icons.search,
                    color: const Color.fromARGB(255, 130, 23, 23),
                    size: screenWidth * 0.06,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25.0),
                    borderSide: BorderSide(
                      color: const Color.fromARGB(255, 130, 23, 23),
                      width: screenWidth * 0.002,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25.0),
                    borderSide: BorderSide(
                      color: const Color.fromARGB(255, 130, 23, 23),
                      width: screenWidth * 0.0015,
                    ),
                  ),
                ),
                cursorColor: const Color.fromARGB(255, 130, 23, 23),
                onChanged: (value) {
                  setState(() {
                    searchQuery = value.toLowerCase();
                  });
                },
              ),
            ),

            SizedBox(width: screenWidth * 0.02),
            // Filter Button
            ElevatedButton(
              onPressed: () {
                setState(() {
                  isFilterVisible = !isFilterVisible;
                });
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: const Color.fromARGB(255, 130, 23, 23),
                backgroundColor: const Color.fromARGB(255, 231, 231, 231),
                elevation: 0,
              ),
              child: Icon(
                isFilterVisible ? Icons.close : Icons.filter_list_alt,
                color: const Color.fromARGB(255, 130, 23, 23),
                size: screenWidth * 0.06,
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              SizedBox(height: screenWidth * 0.05),
              // Filter Content

              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(userId)
                    .snapshots(),
                builder: (context, snapshot) {
                  // Check connection state
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  // Handle errors
                  if (snapshot.hasError) {
                    return const Center(
                      child: Text(
                        'An error occurred while fetching user data.',
                        style: TextStyle(fontSize: 16, color: Colors.red),
                      ),
                    );
                  }

                  // Handle missing data
                  if (!snapshot.hasData ||
                      snapshot.data == null ||
                      !snapshot.data!.exists) {
                    return const Center(
                      child: Text(
                        'User not found.',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    );
                  }

                  // Extract username from Firestore
                  final userDoc = snapshot.data!;
                  final String username = userDoc['username'] ??
                      'User'; // Default if username is missing

                  return Center(
                    child: Text.rich(
                      TextSpan(
                        text: 'Welcome, $username!', // Regular text
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 130, 23, 23),
                        ),
                      ),
                    ),
                  );
                },
              ),
              SizedBox(
                height: 5,
              ),
              // Pricing Table
              const PricingTable(),

              // Fetch and display car data from Firestore
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream:
                      FirebaseFirestore.instance.collection('cars').snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data == null) {
                      return const Center(child: Text("No data available"));
                    }

                    var filteredCars = snapshot.data!.docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>?;
                      if (data == null) {
                        return false; // Skip if document data is null
                      }

                      final carName =
                          data['name']?.toString().toLowerCase() ?? '';
                      return (carType == 'Car Type' ||
                              data['type'] == carType) &&
                          (gearType == 'Gear Type' ||
                              data['gear'] == gearType) &&
                          (numberOfSeats == 'No of Seats' ||
                              data['seats']?.toString() == numberOfSeats) &&
                          (searchQuery.isEmpty ||
                              carName.contains(searchQuery));
                    }).toList();

                    if (filteredCars.isEmpty) {
                      return const Center(
                          child: Text("No cars match the filter criteria"));
                    }

                    return ListView.builder(
                      itemCount: filteredCars.length,
                      itemBuilder: (context, index) {
                        final carDoc = filteredCars[index];
                        final carData = carDoc.data() as Map<String, dynamic>?;

                        // Check if carData is null or if mandatory fields are missing
                        if (carData == null ||
                            !carData.containsKey('name') ||
                            !carData.containsKey('plateNo') ||
                            !carData.containsKey('type') ||
                            !carData.containsKey('gear') ||
                            !carData.containsKey('seats') ||
                            !carData.containsKey('pricePerDay') ||
                            !carData.containsKey('mainImage')) {
                          return const SizedBox
                              .shrink(); // Skip this item if the data is invalid
                        }

                        return Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: screenHeight * 0.005,
                            horizontal: screenWidth * 0.03,
                          ),
                          child: Container(
                            width: double.infinity,
                            height: screenHeight * 0.2,
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 140, 20, 20),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: screenWidth * 0.3,
                                  height: screenHeight * 0.18,
                                  margin: EdgeInsets.all(screenWidth * 0.03),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    image: DecorationImage(
                                      image: carData['mainImage'] != null &&
                                              carData['mainImage'].isNotEmpty
                                          ? Uri.tryParse(carData['mainImage'])
                                                      ?.isAbsolute ==
                                                  true
                                              ? NetworkImage(carData[
                                                  'mainImage']) // Use NetworkImage if it's a valid URL
                                              : AssetImage(carData['mainImage'])
                                                  as ImageProvider // Use AssetImage if it's a local path
                                          : const AssetImage(
                                              'assets/images/default_car.jpg'), // Fallback to default image if no valid URL or asset path
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(height: screenHeight * 0.04),
                                      Text(
                                        carData['name'],
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: screenWidth * 0.04,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                      SizedBox(height: screenHeight * 0.01),
                                      FutureBuilder<double>(
                                        future: _calculateAverageRating(
                                            carData['plateNo']),
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState ==
                                              ConnectionState.waiting) {
                                            return Text(
                                              "Loading rating...",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: screenWidth * 0.035,
                                              ),
                                            );
                                          }
                                          final rating = snapshot.data ?? 0.0;
                                          return Row(
                                            children: [
                                              RatingBarIndicator(
                                                rating: rating,
                                                itemBuilder: (context, index) =>
                                                    const Icon(
                                                  Icons.star,
                                                  color: Colors.amber,
                                                ),
                                                itemCount: 5,
                                                itemSize: screenWidth *
                                                    0.05, // Adjust the size of the stars
                                                direction: Axis.horizontal,
                                              ),
                                              SizedBox(
                                                  width: screenWidth * 0.02),
                                              Text(
                                                rating.toStringAsFixed(1),
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: screenWidth * 0.035,
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                      SizedBox(height: screenHeight * 0.01),
                                      Row(
                                        children: [
                                          ElevatedButton(
                                            onPressed: () {
                                              // Check if 'pricePerHour' exists and is not null in carData
                                              if (carData.containsKey(
                                                      'pricePerHour') &&
                                                  carData['pricePerHour'] !=
                                                      null) {
                                                // Navigate to BookingPage if 'pricePerHour' exists
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        BookingPage(
                                                      carName: carData['name'],
                                                      plateNo:
                                                          carData['plateNo'],
                                                      carType: carData['type'],
                                                      gearType: carData['gear'],
                                                      seats: carData['seats']
                                                          .toString(),
                                                      pricePerDay: carData[
                                                          'pricePerDay'],
                                                      pricePerHour: carData[
                                                                  'pricePerHour']
                                                              is Map<String,
                                                                  dynamic>
                                                          ? Map<String,
                                                                  double>.from(
                                                              carData[
                                                                  'pricePerHour'])
                                                          : {},
                                                      mainImage:
                                                          carData['mainImage'],
                                                    ),
                                                  ),
                                                );
                                              } else {
                                                // Navigate to BookingPage2 if 'pricePerHour' does not exist
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        BookingPage2(
                                                      carName: carData['name'],
                                                      plateNo:
                                                          carData['plateNo'],
                                                      carType: carData['type'],
                                                      gearType: carData['gear'],
                                                      seats: carData['seats']
                                                          .toString(),
                                                      pricePerDay: carData[
                                                          'pricePerDay'],
                                                      mainImage:
                                                          carData['mainImage'],
                                                    ),
                                                  ),
                                                );
                                              } 
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.white,
                                              foregroundColor:
                                                  const Color.fromARGB(
                                                      255, 130, 23, 23),
                                            ),
                                            child: Text(
                                              'Book',
                                              style: TextStyle(
                                                  fontSize:
                                                      screenWidth * 0.035),
                                            ),
                                          ),
                                          SizedBox(width: screenWidth * 0.025),
                                          ElevatedButton(
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      CarDetailsPage(
                                                    carId: carDoc.id,
                                                  ),
                                                ),
                                              );
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  const Color.fromARGB(
                                                      255, 225, 225, 225),
                                              foregroundColor:
                                                  const Color.fromARGB(
                                                      255, 130, 23, 23),
                                            ),
                                            child: Text(
                                              'More Details',
                                              style: TextStyle(
                                                  fontSize:
                                                      screenWidth * 0.035),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              )
            ],
          ),
          Visibility(
            visible: isFilterVisible,
            child: Container(
              margin: EdgeInsets.symmetric(
                vertical: screenHeight * 0.005,
                horizontal: screenWidth * 0.04,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 2,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: EdgeInsets.all(screenWidth * 0.04),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Determine if we should use vertical layout
                  bool useVerticalLayout = constraints.maxWidth < 600;

                  return SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!useVerticalLayout)
                          // Horizontal layout for larger screens
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0),
                                  child: _buildDropdown(
                                    value: carType,
                                    items: const [
                                      'Car Type',
                                      'Compact Hatchback',
                                      'Sedan',
                                      'Minivan'
                                    ],
                                    onChanged: (String? newValue) {
                                      setState(() {
                                        carType = newValue!;
                                      });
                                    },
                                    icon: Icons.directions_car,
                                    constraints: constraints,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0),
                                  child: _buildDropdown(
                                    value: gearType,
                                    items: const [
                                      'Gear Type',
                                      'Automatic',
                                      'Manual'
                                    ],
                                    onChanged: (String? newValue) {
                                      setState(() {
                                        gearType = newValue!;
                                      });
                                    },
                                    icon: Icons.settings,
                                    constraints: constraints,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0),
                                  child: _buildDropdown(
                                    value: numberOfSeats,
                                    items: const ['No of Seats', '5', '9'],
                                    onChanged: (String? newValue) {
                                      setState(() {
                                        numberOfSeats = newValue!;
                                      });
                                    },
                                    icon: Icons.event_seat,
                                    constraints: constraints,
                                  ),
                                ),
                              ),
                            ],
                          )
                        else
                          // Vertical layout for smaller screens
                          Column(
                            children: [
                              _buildDropdown(
                                value: carType,
                                items: const [
                                  'Car Type',
                                  'Compact Hatchback',
                                  'Sedan',
                                  'Minivan'
                                ],
                                onChanged: (String? newValue) {
                                  setState(() {
                                    carType = newValue!;
                                  });
                                },
                                icon: Icons.directions_car,
                                constraints: constraints,
                              ),
                              const SizedBox(height: 12),
                              _buildDropdown(
                                value: gearType,
                                items: const [
                                  'Gear Type',
                                  'Automatic',
                                  'Manual'
                                ],
                                onChanged: (String? newValue) {
                                  setState(() {
                                    gearType = newValue!;
                                  });
                                },
                                icon: Icons.settings,
                                constraints: constraints,
                              ),
                              const SizedBox(height: 12),
                              _buildDropdown(
                                value: numberOfSeats,
                                items: const ['No of Seats', '5', '9'],
                                onChanged: (String? newValue) {
                                  setState(() {
                                    numberOfSeats = newValue!;
                                  });
                                },
                                icon: Icons.event_seat,
                                constraints: constraints,
                              ),
                            ],
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white70,
        currentIndex: _currentIndex, // Tracks the selected tab
        onTap: _onItemTapped, // Handles tab changes
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home, size: 24),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history, size: 24),
            label: 'My Bookings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person, size: 24),
            label: 'Profile',
          ),
        ],
        selectedItemColor: const Color.fromARGB(255, 130, 23, 23),
        unselectedItemColor: Colors.grey,
        showSelectedLabels: true,
        showUnselectedLabels: true,
      ),
    );
  }
}

class PricingTable extends StatelessWidget {
  const PricingTable({super.key});

  @override
  Widget build(BuildContext context) {
    final hours = [1, 3, 5, 7, 9, 12, 24];
    final axiaRates = [30, 50, 60, 65, 70, 80, 110];
    final bezzaMyviSagaRates = [35, 55, 65, 70, 75, 85, 120];
    final List<String> carNames = [
      'Toyota Vios',
      'Honda City',
      'Hyundai Starex'
    ];
    final dailyPrices = [300, 300, 550];
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;

    return Padding(
      padding: EdgeInsets.symmetric(
          vertical: screenHeight * 0.01, horizontal: screenWidth * 0.03),
      child: LayoutBuilder(
        builder: (context, constraints) {
          double firstColumnWidth = constraints.maxWidth * 0.2;
          double remainingWidth = constraints.maxWidth - firstColumnWidth;
          double otherCellWidth = remainingWidth / hours.length;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DefaultTabController(
                length: 3,
                child: Column(
                  children: [
                    const TabBar(
                      labelColor: Color.fromARGB(255, 130, 23, 23),
                      indicatorColor: Color.fromARGB(255, 130, 23, 23),
                      tabs: [
                        Tab(text: 'Axia'),
                        Tab(text: 'Bezza, Myvi'),
                        Tab(text: 'Others'),
                      ],
                    ),
                    SizedBox(
                      height: 100, // Adjust height as needed
                      child: TabBarView(
                        children: [
                          // Axia Table
                          buildHourlyTable(
                            firstColumnWidth: firstColumnWidth,
                            otherCellWidth: otherCellWidth,
                            hours: hours,
                            rates: axiaRates,
                          ),
                          // Bezza, Myvi, Saga Table
                          buildHourlyTable(
                            firstColumnWidth: firstColumnWidth,
                            otherCellWidth: otherCellWidth,
                            hours: hours,
                            rates: bezzaMyviSagaRates,
                          ),
                          // Others Table
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12.0),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              clipBehavior: Clip.hardEdge,
                              child: Table(
                                columnWidths: {
                                  0: FixedColumnWidth(firstColumnWidth),
                                  for (int i = 1; i <= carNames.length; i++)
                                    i: FixedColumnWidth(
                                        (remainingWidth / carNames.length)),
                                },
                                children: [
                                  TableRow(
                                    children: [
                                      Container(
                                        color: const Color.fromARGB(
                                            255, 130, 23, 23),
                                        padding: const EdgeInsets.all(5.0),
                                        height: 50.0,
                                        child: const Align(
                                          alignment: Alignment.center,
                                          child: Text('Car Name',
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white)),
                                        ),
                                      ),
                                      for (var name in carNames)
                                        Container(
                                          color: const Color.fromARGB(
                                              255, 225, 225, 225),
                                          padding: const EdgeInsets.all(5.0),
                                          height: 50.0,
                                          child: Align(
                                            alignment: Alignment.center,
                                            child: Text(name,
                                                style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color.fromARGB(
                                                        255, 130, 23, 23))),
                                          ),
                                        ),
                                    ],
                                  ),
                                  TableRow(
                                    children: [
                                      Container(
                                        color: const Color.fromARGB(
                                            255, 130, 23, 23),
                                        padding: const EdgeInsets.all(5.0),
                                        height: 50.0,
                                        child: const Align(
                                          alignment: Alignment.center,
                                          child: Text('Price/Day (RM)',
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white)),
                                        ),
                                      ),
                                      for (var price in dailyPrices)
                                        Container(
                                          color: const Color.fromARGB(
                                              255, 231, 231, 231),
                                          padding: const EdgeInsets.all(5.0),
                                          height: 50.0,
                                          child: Align(
                                            alignment: Alignment.center,
                                            child: Text(
                                              '$price',
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.normal,
                                                  color: Color.fromARGB(
                                                      255, 130, 23, 23)),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget buildHourlyTable({
    required double firstColumnWidth,
    required double otherCellWidth,
    required List<int> hours,
    required List<int> rates,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10.0),
      child: Container(
        decoration: BoxDecoration(
            //borderRadius: BorderRadius.circular(10.0),
            ),
        clipBehavior: Clip.hardEdge,
        child: Table(
          columnWidths: {
            0: FixedColumnWidth(firstColumnWidth),
            for (int i = 1; i <= hours.length; i++)
              i: FixedColumnWidth(otherCellWidth),
          },
          children: [
            TableRow(
              children: [
                Container(
                  color: const Color.fromARGB(255, 130, 23, 23),
                  padding: const EdgeInsets.all(5.0),
                  height: 50.0,
                  child: const Align(
                    alignment: Alignment.center,
                    child: Text('Hour',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                  ),
                ),
                for (var hour in hours)
                  Container(
                    color: const Color.fromARGB(255, 225, 225, 225),
                    padding: const EdgeInsets.all(5.0),
                    height: 50.0,
                    child: Align(
                      alignment: Alignment.center,
                      child: Text('$hour',
                          style: const TextStyle(
                              fontWeight: FontWeight.normal,
                              color: Color.fromARGB(255, 130, 23, 23))),
                    ),
                  ),
              ],
            ),
            TableRow(
              children: [
                Container(
                  color: const Color.fromARGB(255, 130, 23, 23),
                  padding: const EdgeInsets.all(5.0),
                  height: 50.0,
                  child: const Align(
                    alignment: Alignment.center,
                    child: Text('Rate (RM)',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                  ),
                ),
                for (var rate in rates)
                  Container(
                    color: const Color.fromARGB(255, 225, 225, 225),
                    padding: const EdgeInsets.all(5.0),
                    height: 50.0,
                    child: Align(
                      alignment: Alignment.center,
                      child: Text('$rate',
                          style: const TextStyle(
                              fontWeight: FontWeight.normal,
                              color: Color.fromARGB(255, 130, 23, 23))),
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
