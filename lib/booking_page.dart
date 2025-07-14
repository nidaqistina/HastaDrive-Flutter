//booking_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:table_calendar/table_calendar.dart';
import 'agreement_confirmation_page.dart';

class BookingPage extends StatefulWidget {
  final String carName;
  final String plateNo;
  final String carType;
  final String gearType;
  final String seats;
  final double pricePerDay;
  final Map<String, double> pricePerHour;
  final String mainImage;

  const BookingPage({
    super.key,
    required this.carName,
    required this.plateNo,
    required this.carType,
    required this.gearType,
    required this.seats,
    required this.pricePerDay,
    required this.pricePerHour,
    required this.mainImage,
  });

  @override
  _BookingPageState createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  final _pickupLocationController = TextEditingController();
  final _returnLocationController = TextEditingController();
  DateTime? _pickupDate;
  DateTime? _returnDate;
  String? customerName;
  String? customerEmail;
  String? customerPhone;
  double totalPrice = 0.0;
  double officehour = 0.0;
  String? _pickupLocation;
  String? _returnLocation;
  String? _customPickupLocation;
  String? _customReturnLocation;
  double customLocation = 0.0;

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
          date.isBefore(endDate) || date.isAtSameMomentAs(endDate);
          date = date.add(const Duration(days: 1))) {
        dates.add(date);
      }
    }
    setState(() {
      bookedDates = dates;
    });
  }

  bool _isDateBooked(DateTime date) {
    // Checks if a date is in the bookedDates list by comparing only the date part
    return bookedDates.any((bookedDate) =>
        bookedDate.year == date.year &&
        bookedDate.month == date.month &&
        bookedDate.day == date.day);
  }

  Future<void> _selectPickupDate() async {
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
                  'Select Pickup Date and Time',
                  style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16.0),
                SizedBox(
                  height: 330,
                  width: 300,
                  child: SingleChildScrollView(
                    child: TableCalendar(
                      firstDay: _pickupDate ?? DateTime.now(),
                      lastDay: DateTime(2100),
                      focusedDay: _pickupDate ?? DateTime.now(),
                      selectedDayPredicate: (day) =>
                          _pickupDate?.day == day.day,
                      onDaySelected: (selectedDay, focusedDay) async {
                        if (!_isDateBooked(selectedDay)) {
                          final now = DateTime.now();

                          // Determine the initial time for the time picker
                          TimeOfDay initialTime =
                              (selectedDay.year == now.year &&
                                      selectedDay.month == now.month &&
                                      selectedDay.day == now.day)
                                  ? TimeOfDay(
                                      hour: now.hour,
                                      minute: (now.minute / 30).ceil() * 30,
                                    )
                                  : const TimeOfDay(hour: 8, minute: 0);

                          final pickedTime = await showTimePicker(
                            context: context,
                            initialTime: initialTime,
                            builder: (context, child) {
                              return MediaQuery(
                                data: MediaQuery.of(context)
                                    .copyWith(alwaysUse24HourFormat: true),
                                child: child!,
                              );
                            },
                          );

                          if (pickedTime != null) {
                            // Combine selected date and time for validation
                            final selectedDateTime = DateTime(
                              selectedDay.year,
                              selectedDay.month,
                              selectedDay.day,
                              pickedTime.hour,
                              pickedTime.minute,
                            );

                            // Validate that the selected time is not in the past
                            if (selectedDateTime.isBefore(now)) {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Invalid Time'),
                                  content: const Text(
                                      'You cannot select a time in the past.'),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(),
                                      child: const Text('OK'),
                                    ),
                                  ],
                                ),
                              );
                              return;
                            }

                            setState(() {
                              _pickupDate = selectedDateTime;
                              _calculateTotalPrice();
                            });
                            Navigator.pop(context);
                          }
                        }
                      },
                      headerStyle: const HeaderStyle(
                        formatButtonVisible: false,
                        titleTextStyle: TextStyle(fontSize: 16.0),
                        titleCentered: true,
                      ),
                      calendarBuilders: CalendarBuilders(
                        defaultBuilder: (context, day, focusedDay) {
                          if (_isDateBooked(day)) {
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
                          }
                          return null;
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
                  'Select Return Date and Time',
                  style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16.0),
                SizedBox(
                  height: 330,
                  width: 300,
                  child: SingleChildScrollView(
                    child: TableCalendar(
                      firstDay: _pickupDate ?? DateTime.now(),
                      lastDay: DateTime(2100),
                      focusedDay:
                          _returnDate ?? (_pickupDate ?? DateTime.now()),
                      selectedDayPredicate: (day) =>
                          _returnDate?.day == day.day,
                      onDaySelected: (selectedDay, focusedDay) async {
                        if (!_isDateBooked(selectedDay)) {
                          final now = DateTime.now();

                          // Determine the initial time for the time picker
                          TimeOfDay initialTime = (selectedDay.year ==
                                      now.year &&
                                  selectedDay.month == now.month &&
                                  selectedDay.day == now.day)
                              ? TimeOfDay(
                                  hour: now.hour,
                                  minute: (now.minute / 30).ceil() * 30,
                                )
                              : (_pickupDate != null &&
                                      selectedDay.year == _pickupDate!.year &&
                                      selectedDay.month == _pickupDate!.month &&
                                      selectedDay.day == _pickupDate!.day)
                                  ? TimeOfDay(
                                      hour: _pickupDate!.hour,
                                      minute: _pickupDate!.minute,
                                    )
                                  : const TimeOfDay(hour: 8, minute: 0);

                          final pickedTime = await showTimePicker(
                            context: context,
                            initialTime: initialTime,
                            builder: (context, child) {
                              return MediaQuery(
                                data: MediaQuery.of(context)
                                    .copyWith(alwaysUse24HourFormat: true),
                                child: child!,
                              );
                            },
                          );

                          if (pickedTime != null) {
                            // Combine selected date and time for validation
                            final selectedDateTime = DateTime(
                              selectedDay.year,
                              selectedDay.month,
                              selectedDay.day,
                              pickedTime.hour,
                              pickedTime.minute,
                            );

                            // Validate that the selected time is not before the pickup time or now
                            if (selectedDateTime.isBefore(now) ||
                                (_pickupDate != null &&
                                    selectedDateTime.isBefore(_pickupDate!))) {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Invalid Time'),
                                  content: const Text(
                                      'Return time cannot be in the past or before the pickup time.'),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(),
                                      child: const Text('OK'),
                                    ),
                                  ],
                                ),
                              );
                              return;
                            }

                            setState(() {
                              _returnDate = selectedDateTime;
                              _calculateTotalPrice();
                            });
                            Navigator.pop(context);
                          }
                        }
                      },
                      headerStyle: const HeaderStyle(
                        formatButtonVisible: false,
                        titleTextStyle: TextStyle(fontSize: 16.0),
                        titleCentered: true,
                      ),
                      calendarBuilders: CalendarBuilders(
                        defaultBuilder: (context, day, focusedDay) {
                          if (_isDateBooked(day)) {
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
                          }
                          return null;
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
    priceBreakdown.clear();
    if (_pickupDate != null && _returnDate != null) {
      final duration = _returnDate!.difference(_pickupDate!);
      final totalHours = duration.inHours;
      final totalDays = duration.inDays;
      double total = 0.0;

      if (totalDays > 0) {
        total += widget.pricePerDay * totalDays;
        priceBreakdown.add({
          'description':
              '$totalDays Day(s) at RM${widget.pricePerDay.toStringAsFixed(2)} each',
          'amount': widget.pricePerDay * totalDays,
        });
      }

      final remainingHours = totalHours % 24;

      if (remainingHours > 0) {
        if (remainingHours <= 1) {
          total += widget.pricePerHour['1']!;
          priceBreakdown.add({
            'description': '1 Hour',
            'amount': widget.pricePerHour['1'],
          });
        } else if (remainingHours <= 3) {
          total += widget.pricePerHour['3']!;
          priceBreakdown.add({
            'description': 'Up to 3 Hours',
            'amount': widget.pricePerHour['3'],
          });
        } else if (remainingHours <= 5) {
          total += widget.pricePerHour['5']!;
          priceBreakdown.add({
            'description': 'Up to 5 Hours',
            'amount': widget.pricePerHour['5'],
          });
        } else if (remainingHours <= 7) {
          total += widget.pricePerHour['7']!;
          priceBreakdown.add({
            'description': 'Up to 7 Hours',
            'amount': widget.pricePerHour['7'],
          });
        } else if (remainingHours <= 9) {
          total += widget.pricePerHour['9']!;
          priceBreakdown.add({
            'description': 'Up to 9 Hours',
            'amount': widget.pricePerHour['9'],
          });
        } else if (remainingHours <= 12) {
          total += widget.pricePerHour['12']!;
          priceBreakdown.add({
            'description': 'Up to 12 Hours',
            'amount': widget.pricePerHour['12'],
          });
        } else {
          total += widget.pricePerHour['24']!;
          priceBreakdown.add({
            'description': 'Up to 24 Hours',
            'amount': widget.pricePerHour['24'],
          });
        }
      }

      final pickupHour = _pickupDate!.hour;
      final returnHour = _returnDate!.hour;

      // Calculate outside office hours fee
      if ((pickupHour < 9 || pickupHour >= 17) &&
          (returnHour < 9 || returnHour >= 17)) {
        total += 20.0;
        officehour = 20.0;
        priceBreakdown.add({
          'description':
              'Outside Office Hours Fee (Both pickup and return time)',
          'amount': 20.0,
        });
      } else if ((pickupHour < 9 || pickupHour >= 17) ||
          (returnHour < 9 || returnHour >= 17)) {
        total += 10.0;
        officehour = 10.0;
        priceBreakdown.add({
          'description':
              'Outside Office Hours Fee (Either pickup and return time)',
          'amount': 10.0,
        });
      }

      // Custom location fee
      if ((_pickupLocation == 'Others' &&
              _pickupLocationController.text.isNotEmpty) &&
          (_returnLocation == 'Others' &&
              _returnLocationController.text.isNotEmpty)) {
        total += 10.0;
        customLocation = 10.0;
        priceBreakdown.add({
          'description':
              'Custom Location Fee (Both pickup and return location)',
          'amount': 10.0,
        });
      } else if ((_pickupLocation == 'Others' &&
              _pickupLocationController.text.isNotEmpty) ||
          (_returnLocation == 'Others' &&
              _returnLocationController.text.isNotEmpty)) {
        total += 5.0;
        customLocation = 5.0;
        priceBreakdown.add({
          'description':
              'Custom Location Fee (Either pickup or return location)',
          'amount': 5.0,
        });
      } else {
        customLocation = 0.0; // Reset if no custom location is selected
      }

      setState(() {
        totalPrice = total;
      });
    }
  }

  Future<void> _confirmBooking() async {
    final duration = _returnDate!.difference(_pickupDate!).inHours;
    if (_pickupDate == null || _returnDate == null) {
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

    // Navigate to the Agreement & Confirmation Page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AgreementConfirmationPage(
          carName: widget.carName, // Ensure all these values are non-null
          plateNo: widget.plateNo,
          carType: widget.carType,
          gearType: widget.gearType,
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
          duration: duration,
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
        .where('returnDate', isGreaterThan: pickupDate)
        .get();

    // If any bookings are found, there is an overlap
    return bookingQuery.docs.isEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 130, 23, 23),
        title: const Text(
          'Booking Details',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(
            vertical: size.height * 0.012, horizontal: size.width * 0.05),
        child: ListView(
          children: [
            // Display the car image
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

            // Display car details
            Text(widget.carName,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: size.height * 0.01),

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
                      'Plate No: ${widget.plateNo}',
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
                      'Gear Type: ${widget.gearType}',
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
                  ],
                ),
              ),
            ),
            SizedBox(height: 12),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Dropdown for Pickup Location
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Pickup Location',
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
                const SizedBox(
                    height: 10), // Space between dropdown and custom input

                // Custom Pickup Location Input Field
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
                      setState(() {}); // Rebuild to capture changes
                    },
                  ),
              ],
            ),
            const SizedBox(height: 15),

            // Similar setup for Return Location
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Dropdown for Pickup Location
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Return Location',
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
                const SizedBox(
                    height: 10), // Space between dropdown and custom input

                // Custom Pickup Location Input Field
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
                      setState(() {}); // Rebuild to capture changes
                    },
                  ),
              ],
            ),
            const SizedBox(height: 18),

            // Button to select pickup date & time
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
                    ? 'Select Pickup Date & Time'
                    : 'Pickup Date & Time: ${DateFormat.yMMMd().add_jm().format(_pickupDate!)}',
              ),
            ),
            const SizedBox(height: 8),

            // Button to select return date & time
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
              child: Text(_returnDate == null
                  ? 'Select Return Date & Time'
                  : 'Return Date & Time: ${DateFormat.yMMMd().add_jm().format(_returnDate!)}'),
            ),
            const SizedBox(height: 15),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Duration, Total Price, and Notes all in a Card
                if (_pickupDate != null && _returnDate != null ||
                    totalPrice > 0)
                  Card(
                    margin:
                        EdgeInsets.symmetric(vertical: 10.0, horizontal: 8.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    color: Color.fromARGB(255, 225, 225, 225),
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_pickupDate != null && _returnDate != null)
                            Text(
                              'Duration: ${_returnDate!.difference(_pickupDate!).inHours} hour(s)',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color.fromARGB(255, 130, 23, 23)),
                            ),
                          const SizedBox(height: 5),

                          // Notes: Conditional pricing information
                          if (totalPrice > 0) ...[
                            if (officehour == 20)
                              Text(
                                'RM20 fee added for both pickup and return outside of office hours (9 a.m. - 5 p.m.).',
                                style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500),
                              ),
                            if (officehour == 10)
                              Text(
                                'RM10 fee added either for pickup or return outside of office hours (9 a.m. - 5 p.m.).',
                                style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500),
                              ),
                            const SizedBox(height: 8),
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
                          const SizedBox(height: 15),

                          // Total Price
                          Text(
                            'Total Price: RM${totalPrice.toStringAsFixed(2)}',
                            style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: const Color.fromARGB(255, 130, 23, 23)),
                          ),
                          const SizedBox(height: 15),

                          Center(
                            child: ElevatedButton(
                              onPressed: _confirmBooking,
                              style: ElevatedButton.styleFrom(
                                foregroundColor:
                                    const Color.fromARGB(255, 225, 225, 225),
                                backgroundColor:
                                    const Color.fromARGB(255, 130, 23, 23),
                                shadowColor: Colors.redAccent,
                                elevation: 5,
                                padding: EdgeInsets.symmetric(
                                    horizontal: 30.0, vertical: 16.0),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(500.0),
                                ),
                              ),
                              child: Text(
                                'Confirm Booking',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
              ],
            )
          ],
        ),
      ),
    );
  }
}
