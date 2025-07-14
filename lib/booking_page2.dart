//booking_page2.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:table_calendar/table_calendar.dart';
import 'agreement_confirmation_page2.dart';

class BookingPage2 extends StatefulWidget {
  final String carName;
  final String carType;
  final String gearType;
  final String plateNo;
  final String seats;
  final double pricePerDay;
  final String mainImage;

  const BookingPage2({
    super.key,
    required this.carName,
    required this.carType,
    required this.gearType,
    required this.plateNo,
    required this.seats,
    required this.pricePerDay,
    required this.mainImage,
  });

  @override
  _BookingPage2State createState() => _BookingPage2State();
}

class _BookingPage2State extends State<BookingPage2> {
  final _pickupLocationController = TextEditingController();
  final _returnLocationController = TextEditingController();
  DateTime? _pickupDate;
  DateTime? _returnDate;
  String? customerName;
  String? customerEmail;
  String? customerPhone;
  String? _pickupLocation;
  String? _returnLocation;
  String? _customPickupLocation;
  String? _customReturnLocation;
  double customLocation = 0.0;
  double rentalDays = 0;
  double totalPrice = 0.0;

  List<Map<String, dynamic>> priceBreakdown = [];
  List<DateTime> bookedDates = []; // Store all booked dates for this car

  @override
  void initState() {
    super.initState();
    _fetchCustomerDetails();
    _fetchBookedDates(); // Fetch booked dates when the page initializes
  }

  Future<void> _fetchCustomerDetails() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      setState(() {
        customerName = userDoc.get('name');
        customerEmail = userDoc.get('email');
        customerPhone = userDoc.get('phone');
      });
    }
  }

  Future<void> _fetchBookedDates() async {
    final bookingQuery = await FirebaseFirestore.instance
        .collection('bookings')
        .where('carName', isEqualTo: widget.carName)
        .get();

    List<DateTime> dates = [];
    for (var doc in bookingQuery.docs) {
      DateTime startDate = (doc['pickupDate'] as Timestamp).toDate();
      DateTime endDate = (doc['returnDate'] as Timestamp).toDate();

      // Include each day in the range from startDate to endDate
      for (DateTime date = startDate;
          date.isBefore(endDate.add(const Duration(days: 1)));
          date = date.add(const Duration(days: 1))) {
        dates.add(date);
      }
    }
    setState(() {
      bookedDates = dates;
      //print(bookedDates); // Add this line to confirm booked dates
    });
  }

  bool _isDateBooked(DateTime date) {
    return bookedDates.any((bookedDate) =>
        bookedDate.year == date.year &&
        bookedDate.month == date.month &&
        bookedDate.day == date.day);
  }

  Future<void> _selectPickupDate() async {
    final size = MediaQuery.of(context).size;

    await showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Container(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Select Pickup Date',
                  style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: size.height * 0.005),
                SizedBox(
                  height: 350,
                  width: 300,
                  child: SingleChildScrollView(
                    child: TableCalendar(
                      firstDay: DateTime.now(),
                      lastDay: DateTime(2100),
                      focusedDay: _pickupDate ?? DateTime.now(),
                      selectedDayPredicate: (day) =>
                          _pickupDate?.day == day.day &&
                          _pickupDate?.month == day.month &&
                          _pickupDate?.year == day.year,
                      onDaySelected: (selectedDay, focusedDay) {
                        if (_isDateBooked(selectedDay)) {
                          // Show error message if the selected date is already booked
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Invalid Date'),
                              content: const Text(
                                  'The car is already booked for the selected date.'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('OK'),
                                ),
                              ],
                            ),
                          );
                          return;
                        }

                        final now = DateTime.now();
                        if (selectedDay
                            .isBefore(now.add(const Duration(days: 2)))) {
                          // Prevent selecting today and the next two days
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Invalid Date'),
                              content: const Text(
                                  'You cannot select today or the next two days.'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('OK'),
                                ),
                              ],
                            ),
                          );
                          return;
                        }
                        setState(() {
                          _pickupDate = selectedDay;
                          _returnDate = null;
                        });
                        Navigator.pop(context);
                      },
                      headerStyle: const HeaderStyle(
                        formatButtonVisible: false,
                        titleCentered: true,
                      ),
                      calendarBuilders: CalendarBuilders(
                        todayBuilder: (context, day, focusedDay) {
                          final now = DateTime.now();
                          return Container(
                            margin: const EdgeInsets.all(2.0),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: day.year == now.year &&
                                      day.month == now.month &&
                                      day.day == now.day
                                  ? Color.fromARGB(150, 130, 23, 23)
                                  : const Color.fromARGB(64, 255, 255, 255),
                              borderRadius: BorderRadius.circular(6.0),
                            ),
                            child: Text(
                              '${day.day}',
                              style: const TextStyle(color: Colors.white),
                            ),
                          );
                        },
                        defaultBuilder: (context, day, focusedDay) {
                          final now = DateTime.now();
                          if (_isDateBooked(day) ||
                              day.isBefore(now.add(const Duration(days: 2)))) {
                            return Container(
                              margin: const EdgeInsets.all(2.0),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Color.fromARGB(255, 211, 210, 210),
                                borderRadius: BorderRadius.circular(6.0),
                              ),
                              child: Text(
                                '${day.day}',
                                style: const TextStyle(color: Colors.white),
                              ),
                            );
                          } else {
                            return Container(
                              margin: const EdgeInsets.all(4.0),
                              alignment: Alignment.center,
                              child: Text(
                                '${day.day}',
                                style: const TextStyle(color: Colors.black),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _selectReturnDate() async {
    if (_pickupDate == null) {
      // Show error message if pickup date is not selected
      _showAlertDialog('Please select a pickup date first.');
      return;
    }

    await showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Container(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Select Return Date',
                  style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16.0),
                SizedBox(
                  height: 330,
                  width: 300,
                  child: SingleChildScrollView(
                    child: TableCalendar(
                      firstDay: (_pickupDate != null)
                          ? _pickupDate!.add(const Duration(days: 1))
                          : DateTime.now().add(const Duration(days: 3)),
                      lastDay: DateTime(2100),
                      focusedDay: (_returnDate != null &&
                              (_returnDate!
                                  .isAfter(_pickupDate ?? DateTime.now())))
                          ? _returnDate!
                          : (_pickupDate != null
                              ? _pickupDate!.add(const Duration(days: 1))
                              : DateTime.now().add(const Duration(days: 3))),
                      selectedDayPredicate: (day) =>
                          _returnDate?.day == day.day &&
                          _returnDate?.month == day.month &&
                          _returnDate?.year == day.year,
                      onDaySelected: (selectedDay, focusedDay) {
                        if (_isDateBooked(selectedDay)) {
                          // Show error message if the selected date is already booked
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Invalid Date'),
                              content: const Text(
                                  'The car is already booked for the selected date.'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('OK'),
                                ),
                              ],
                            ),
                          );
                          return;
                        }
                        if (_pickupDate != null &&
                            selectedDay.isBefore(
                                _pickupDate!.add(const Duration(days: 1)))) {
                          // Prevent selecting a return date earlier than the next day after pickup
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Invalid Date'),
                              content: const Text(
                                  'The return date must be at least one day after the pickup date.'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('OK'),
                                ),
                              ],
                            ),
                          );
                          return;
                        }
                        setState(() {
                          _returnDate = selectedDay;
                          _calculateTotalPrice();
                        });
                        Navigator.pop(context);
                      },
                      headerStyle: const HeaderStyle(
                        formatButtonVisible: false,
                        titleTextStyle: TextStyle(
                          fontSize: 16.0,
                        ),
                        titleCentered: true,
                      ),
                      calendarBuilders: CalendarBuilders(
                        todayBuilder: (context, day, focusedDay) {
                          final now = DateTime.now();
                          return Container(
                            margin: const EdgeInsets.all(2.0),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: day.year == now.year &&
                                      day.month == now.month &&
                                      day.day == now.day
                                  ? Colors.orange
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(6.0),
                            ),
                            child: Text(
                              '${day.day}',
                              style: const TextStyle(color: Colors.white),
                            ),
                          );
                        },
                        defaultBuilder: (context, day, focusedDay) {
                          if (_isDateBooked(day) ||
                              (_pickupDate != null &&
                                  day.isBefore(_pickupDate!
                                      .add(const Duration(days: 1))))) {
                            return Container(
                              margin: const EdgeInsets.all(4.0),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.grey,
                                borderRadius: BorderRadius.circular(6.0),
                              ),
                              child: Text(
                                '${day.day}',
                                style: const TextStyle(color: Colors.white),
                              ),
                            );
                          } else {
                            return Container(
                              margin: const EdgeInsets.all(4.0),
                              alignment: Alignment.center,
                              child: Text(
                                '${day.day}',
                                style: const TextStyle(color: Colors.black),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _calculateTotalPrice() {
    _calculateRentalDuration();
    double total = widget.pricePerDay * rentalDays;

    priceBreakdown = [
      {
        'description': 'Rental Cost (${rentalDays.toInt()} days)',
        'amount': widget.pricePerDay * rentalDays,
      },
    ];
    // Custom location fee
    if ((_pickupLocation == 'Others' &&
            _pickupLocationController.text.isNotEmpty) &&
        (_returnLocation == 'Others' &&
            _returnLocationController.text.isNotEmpty)) {
      total += 10.0;
      customLocation = 10.0;
      priceBreakdown.add({
        'description': 'Custom Location Fee (Both pickup and return location)',
        'amount': 10.0,
      });
    } else if ((_pickupLocation == 'Others' &&
            _pickupLocationController.text.isNotEmpty) ||
        (_returnLocation == 'Others' &&
            _returnLocationController.text.isNotEmpty)) {
      total += 5.0;
      customLocation = 5.0;
      priceBreakdown.add({
        'description': 'Custom Location Fee (Either pickup or return location)',
        'amount': 5.0,
      });
    } else {
      customLocation = 0.0; // Reset if no custom location is selected
    }

    setState(() {
      totalPrice = total;
    });
  }

  Future<void> _confirmBooking() async {
    final rentalDays = _returnDate!.difference(_pickupDate!).inHours;
    if (_pickupDate == null && _returnDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select both pickup and return dates.')),
      );
      return;
    }

    // Check if the selected dates overlap with any existing bookings
    bool isAvailable = await _checkDateAvailability(_pickupDate!, _returnDate!);
    if (!isAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('This car is already booked for the selected dates.')),
      );
      return;
    }

    // Check if "Others" is selected for pickup and if the input is empty
    if (_pickupLocation == 'Others' && _pickupLocationController.text.isEmpty) {
      _showAlertDialog('Please fill in the custom pickup location.');
      return;
    }
    if (_returnLocation == 'Others' && _returnLocationController.text.isEmpty) {
      _showAlertDialog('Please fill in the custom return location.');
      return;
    }

    _calculateTotalPrice();

    _customPickupLocation = _pickupLocationController.text.trim();
    _customReturnLocation = _returnLocationController.text.trim();

    // Show confirmation page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AgreementConfirmationPage2(
          carName: widget.carName, // Ensure all these values are non-null
          carType: widget.carType,
          gearType: widget.gearType,
          plateNo: widget.plateNo,
          seats: widget.seats,
          pickupDate: _pickupDate!,
          returnDate: _returnDate!,
          customerName: customerName ?? '',
          customerEmail: customerEmail ?? '',
          customerPhone: customerPhone ?? '',
          pickupLocation: _pickupLocation == 'Others'
              ? _customPickupLocation ?? ''
              : _pickupLocation ?? '',
          returnLocation: _returnLocation == 'Others'
              ? _customReturnLocation ?? ''
              : _returnLocation ?? '',
          customPickupLocation: _customPickupLocation ?? '',
          customReturnLocation: _customReturnLocation ?? '',
          totalPrice: totalPrice,
          priceBreakdown: priceBreakdown,
          duration: rentalDays,
        ),
      ),
    );
  }

  void _showAlertDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Input Required'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<bool> _checkDateAvailability(
      DateTime pickupDate, DateTime returnDate) async {
    // Query Firestore for any existing bookings of this car that overlap with the selected dates
    final bookingQuery = await FirebaseFirestore.instance
        .collection('bookings')
        .where('carName', isEqualTo: widget.carName)
        .where('pickupDate', isLessThanOrEqualTo: returnDate)
        .where('returnDate', isGreaterThanOrEqualTo: pickupDate)
        .get();

    // If any bookings are found, there is an overlap
    return bookingQuery.docs.isEmpty;
  }

  void _calculateRentalDuration() {
    if (_pickupDate == null && _returnDate == null) {
      rentalDays = 0; // Default to 1 day if no dates are selected
      //_showErrorMessage("Please select both pickup and return dates.");
      return;
    }

    // Ensure the return date is later than the pickup date
    if (_returnDate!.isAfter(_pickupDate!)) {
      rentalDays = _returnDate!.difference(_pickupDate!).inDays.toDouble();
    } else {
      rentalDays = 0; // Default to 1 day if return date is before pickup date
      _showErrorMessage("Return date must be later than pickup date.");
    }
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: Text("Booking Details",
        style: TextStyle(
          color: Colors.white
        ),),
        backgroundColor: Color.fromARGB(255, 130, 23, 23),
        leading: IconButton(
              icon: const Icon(Icons.arrow_back,
              color: Colors.white,),
              onPressed: () => Navigator.of(context).pop(),
            ),
        ),
      body: Padding(
        padding: EdgeInsets.symmetric(
            vertical: size.height * 0.012, horizontal: size.width * 0.05),
        child: ListView(
          children: [
            widget.mainImage.isNotEmpty
                ? Uri.tryParse(widget.mainImage)?.isAbsolute == true
                    ? Image.network(
                        widget.mainImage, // Use the network URL
                        height: size.height * 0.2,
                        width: size.width * 0.8,
                        fit: BoxFit.contain,
                      )
                    : Image.asset(
                        widget.mainImage, // Use the asset path
                        height: size.height * 0.2,
                        width: size.width * 0.8,
                        fit: BoxFit.contain,
                      )
                : Image.asset(
                    'assets/images/default_car.jpg', // Fallback to default image if no valid URL or asset path
                    height: size.height * 0.2,
                    width: size.width * 0.8,
                    fit: BoxFit.contain,
                  ),
            SizedBox(height: size.height * 0.01),

            Text(widget.carName,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: size.height * 0.01),

            // Car details
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15.0),
              ),
              color: Color.fromARGB(255, 130, 23, 23),
              margin:
                  const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10.0),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Plate No.: ${widget.plateNo}',
                      style: const TextStyle(
                          fontSize: 16,
                          color: Color.fromARGB(255, 231, 231, 231)),
                    ),
                    Text(
                      'Car Type: ${widget.carType}',
                      style: const TextStyle(
                          fontSize: 16,
                          color: Color.fromARGB(255, 231, 231, 231)),
                    ),
                    Text(
                      'Seats: ${widget.seats}',
                      style: const TextStyle(
                          fontSize: 16,
                          color: Color.fromARGB(255, 231, 231, 231)),
                    ),
                    Text(
                      'Gear Type: ${widget.gearType}',
                      style: const TextStyle(
                          fontSize: 16,
                          color: Color.fromARGB(255, 231, 231, 231)),
                    ),
                    Text(
                      'Price per Day: RM${widget.pricePerDay}',
                      style: const TextStyle(
                          fontSize: 16,
                          color: Color.fromARGB(255, 231, 231, 231)),
                    ),
                  ],
                ),
              ),
            ),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                //location
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Pickup Location',
                    labelStyle: TextStyle(
                        color: Color.fromARGB(150, 130, 23, 23),
                        fontWeight: FontWeight.w600),
                    filled: true,
                    fillColor: const Color.fromARGB(255, 231, 231, 231),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: BorderSide(
                          color: const Color.fromARGB(255, 231, 231, 231),
                          width: 0.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: BorderSide(
                          color: const Color.fromARGB(255, 130, 23, 23),
                          width: 2.0),
                    ),
                    prefixIcon: Icon(
                      Icons.location_on,
                      color: const Color.fromARGB(255, 130, 23, 23),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 16.0),
                  ),
                  value: _pickupLocation,
                  dropdownColor: const Color.fromARGB(255, 231, 231, 231),
                  icon: Icon(
                    Icons.arrow_drop_down,
                    color: const Color.fromARGB(255, 130, 23, 23),
                  ),
                  onChanged: (String? newValue) {
                    setState(() {
                      _pickupLocation = newValue;
                      _pickupLocationController.clear();
                      _calculateTotalPrice();
                    });
                  },
                  items: <String>['Student Mall', 'Others']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(
                        value,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color.fromARGB(255, 130, 23, 23),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),

// If "Others" is selected for Pickup Location, show custom input field
                if (_pickupLocation == 'Others')
                  TextField(
                    controller: _pickupLocationController,
                    decoration: InputDecoration(
                      labelText: 'Enter Custom Pickup Location',
                      labelStyle: TextStyle(
                        color: const Color.fromARGB(150, 130, 23, 23),
                        fontWeight: FontWeight.w600,
                      ),
                      filled: true,
                      fillColor: const Color.fromARGB(255, 231, 231, 231),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        borderSide: BorderSide(
                            color: const Color.fromARGB(255, 231, 231, 231),
                            width: 0.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide(
                            color: const Color.fromARGB(255, 130, 23, 23),
                            width: 2.0),
                      ),
                      prefixIcon: Icon(
                        Icons.edit_location_alt,
                        color: const Color.fromARGB(255, 130, 23, 23),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20.0, vertical: 16.0),
                    ),
                    cursorColor: const Color.fromARGB(255, 130, 23, 23),
                    onChanged: (String value) {
                      setState(() {}); // Rebuild to capture changes
                    },
                  ),
              ],
            ),
            const SizedBox(height: 15),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Similar setup for Return Location
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Return Location',
                    labelStyle: TextStyle(
                      color: const Color.fromARGB(150, 130, 23, 23),
                      fontWeight: FontWeight.w600,
                    ),
                    filled: true,
                    fillColor: Color.fromARGB(255, 231, 231, 231),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: BorderSide(
                          color: const Color.fromARGB(255, 231, 231, 231),
                          width: 0.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: BorderSide(
                          color: const Color.fromARGB(255, 130, 23, 23),
                          width: 2.0),
                    ),
                    prefixIcon: Icon(
                      Icons.location_on,
                      color: const Color.fromARGB(255, 130, 23, 23),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20.0, vertical: 16.0),
                  ),
                  value: _returnLocation,
                  dropdownColor: const Color.fromARGB(255, 231, 231, 231),
                  icon: Icon(
                    Icons.arrow_drop_down,
                    color: const Color.fromARGB(255, 130, 23, 23),
                  ),
                  onChanged: (String? newValue) {
                    setState(() {
                      _returnLocation = newValue;
                      _returnLocationController.clear();
                      _calculateTotalPrice(); // Clear custom return location text if dropdown changes
                    });
                  },
                  items: <String>['Student Mall', 'Others']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(
                        value,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color.fromARGB(255, 130, 23, 23),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),

// If "Others" is selected for Return Location, show custom input field
                if (_returnLocation == 'Others')
                  TextField(
                    controller: _returnLocationController,
                    decoration: InputDecoration(
                      labelText: 'Enter Custom Return Location',
                      labelStyle: TextStyle(
                        color: const Color.fromARGB(150, 130, 23, 23),
                        fontWeight: FontWeight.w600,
                      ),
                      filled: true,
                      fillColor: const Color.fromARGB(255, 231, 231, 231),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide(
                            color: const Color.fromARGB(255, 231, 231, 231),
                            width: 0.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide(
                            color: const Color.fromARGB(255, 130, 23, 23),
                            width: 2.0),
                      ),
                      prefixIcon: Icon(
                        Icons.edit_location_alt,
                        color: const Color.fromARGB(255, 130, 23, 23),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20.0, vertical: 16.0),
                    ),
                    cursorColor: const Color.fromARGB(255, 130, 23, 23),
                    onChanged: (String value) {
                      setState(() {
                        _calculateTotalPrice();
                      }); //automatically calc total
                    },
                  ),
              ],
            ),
            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: _selectPickupDate,
              style: ElevatedButton.styleFrom(
                foregroundColor: const Color.fromARGB(255, 130, 23, 23),
                backgroundColor: const Color.fromARGB(255, 231, 231, 231),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                      8.0), // Adjust the radius value here
                ),
              ),
              child: Text(
                _pickupDate == null
                    ? 'Select Pickup Date'
                    : 'Pickup Date: ${DateFormat('yyyy-MM-dd').format(_pickupDate!)}',
              ),
            ),
            SizedBox(height: 15.0),

            ElevatedButton(
              onPressed: _selectReturnDate,
              style: ElevatedButton.styleFrom(
                foregroundColor: const Color.fromARGB(255, 130, 23, 23),
                backgroundColor: const Color.fromARGB(255, 231, 231, 231),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                      8.0), // Adjust the radius value here
                ),
              ),
              child: Text(
                _returnDate == null
                    ? 'Select Return Date'
                    : 'Return Date: ${DateFormat('yyyy-MM-dd').format(_returnDate!)}',
              ),
            ),
            SizedBox(height: 15.0),

            Column(
              children: [
                Text(
                  'Please pick up and return the car at the same time, between 9:00 AM and 5:00 PM, ensuring both occur during office hours.', // Display rental days
                  style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.redAccent),
                ),
              ],
            ),
            SizedBox(height: 20.0),

            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Card(
                  margin: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  color: Color.fromARGB(255, 225, 225, 225),
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Rental Days: ${rentalDays.toInt()}', // Display rental days
                          style: TextStyle(
                              fontSize: 16.0,
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(255, 130, 23, 23)),
                        ),
                        SizedBox(height: 5.0),

                        if (totalPrice > 0) ...[
                          if (customLocation == 5)
                            Text(
                              'RM5 fee added for either pickup or return location not in Student Mall.',
                              style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500),
                            ),
                          if (customLocation == 10)
                            Text(
                              'RM10 fee added for both pickup and return location not in Student Mall.',
                              style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500),
                            ),
                          const SizedBox(height: 5),
                        ],

                        Text(
                          'Total Price: RM $totalPrice',
                          style: TextStyle(
                              fontSize: 16.0,
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(255, 130, 23, 23)),
                        ),
                        SizedBox(height: 15),
                        // Confirm Booking Button
                        ElevatedButton(
                          onPressed: _confirmBooking,
                          style: ElevatedButton.styleFrom(
                            foregroundColor:
                                const Color.fromARGB(255, 225, 225, 225),
                            backgroundColor:
                                const Color.fromARGB(255, 130, 23, 23),
                            shadowColor: Colors.redAccent,
                            elevation: 5,
                            padding: EdgeInsets.symmetric(
                                vertical: size.height * 0.015),
                            textStyle: TextStyle(fontSize: size.width * 0.05),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50.0),
                            ),
                          ),
                          child: Center(
                            child: SizedBox(
                              width: double
                                  .infinity, // Makes the text expand to fill the button width
                              child: Text(
                                'Confirm Booking',
                                textAlign: TextAlign
                                    .center, // Aligns the text to the center
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
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
