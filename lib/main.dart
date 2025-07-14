//main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_page.dart';
import 'car_inventory_page.dart';
import 'customer_home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await registerHasta(); // Register the hasta admin account only once
  await addCarsToFirestore(); // Add cars to Firestore initially (comment out after first run)

  runApp(const MyApp());
}

// Function to register hasta admin user
Future<void> registerHasta() async {
  const String adminEmail = 'hastaad2425@gmail.com';
  const String adminPassword = 'Duck12345';
  const String adminUsername = 'hastaAdmin';

  try {
    DocumentSnapshot userDoc =
        await FirebaseFirestore.instance.collection('users').doc('hasta').get();

    if (!userDoc.exists) {
      try {
        UserCredential userCredential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: adminEmail,
          password: adminPassword,
        );

        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
          'email': adminEmail,
          'username': adminUsername,
          'userType': 'hasta',
        });

        print(
            'Hasta admin account created successfully in Firebase Auth and Firestore.');
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          print('Admin email already in use.');
        } else {
          print('Error creating admin in Firebase Auth: ${e.message}');
        }
      }
    } else {
      print('Hasta admin already exists in Firestore.');
    }
  } catch (e) {
    print('Error during hasta registration: $e');
  }
}

// Function to add car data to Firestore
Future<void> addCarsToFirestore() async {
  CollectionReference cars = FirebaseFirestore.instance.collection('cars');

  List<Map<String, dynamic>> carData = [
    {
      'name': 'PERODUA AXIA 1.0',
      'modelYear': "2023",
      'make': "Perodua",
      'model': "Axia",
      'type': 'Compact Hatchback',
      'gear': 'Automatic',
      'color': "Green",
      'status': "Used",
      'fuelLevel': "3 bars",
      'plateNo': "UTM1234",
      'seats': 5,
      'pricePerDay': 110.0,
      'pricePerHour': {
        '1': 30.0,
        '3': 50.0,
        '5': 60.0,
        '7': 65.0,
        '9': 70.0,
        '12': 80.0,
        '24': 110.0,
      },
      'mainImage': 'assets/axia.png',
      'additionalImages': [
        "https://hastatravel.com/assets/img/kereta/axia/Axia-1.jpg",
        "https://hastatravel.com/assets/img/kereta/axia/Axia-2.jpg",
        "https://hastatravel.com/assets/img/kereta/axia/Axia-3.jpg",
        "https://hastatravel.com/assets/img/kereta/axia/Axia-5.jpg",
      ],
      'lastMaintenance': '2024-10-01',
    },
    {
      'name': 'PERODUA BEZZA 1.3',
      'modelYear': "2023",
      'make': "Perodua",
      'model': "Bezza",
      'type': 'Sedan',
      'gear': 'Automatic',
      'color': "Glittering Silver",
      'status': "New",
      'fuelLevel': "Full",
      'plateNo': "ABC1234",
      'seats': 5,
      'pricePerDay': 120.0,
      'pricePerHour': {
        '1': 35.0,
        '3': 55.0,
        '5': 65.0,
        '7': 70.0,
        '9': 75.0,
        '12': 85.0,
        '24': 120.0,
      },
      'mainImage': 'assets/bezza.png',
      'additionalImages': [
        "https://hastatravel.com/assets/img/kereta/bezza/bezza_1.jpg",
        "https://hastatravel.com/assets/img/kereta/bezza/bezza_2.jpg",
        "https://hastatravel.com/assets/img/kereta/bezza/bezza_3.jpg",
        "https://hastatravel.com/assets/img/kereta/bezza/bezza_4.jpg",
        "https://hastatravel.com/assets/img/kereta/bezza/bezza_5.jpeg",
      ],
      'lastMaintenance': '2024-10-01',
    },
    {
      'name': 'PERODUA MYVI 1.3',
      'modelYear': "2023",
      'make': "Perodua",
      'model': "Myvi",
      'type': 'Compact Hatchback',
      'gear': 'Automatic',
      'color': "Ivory White",
      'status': "New",
      'fuelLevel': "Full",
      'plateNo': "XYZ1234",
      'seats': 5,
      'pricePerDay': 120.0,
      'pricePerHour': {
        '1': 35.0,
        '3': 55.0,
        '5': 65.0,
        '7': 70.0,
        '9': 75.0,
        '12': 85.0,
        '24': 120.0,
      },
      'mainImage': 'assets/myvi.png',
      'additionalImages': [
        "https://hastatravel.com/assets/img/kereta/myvi/myvi_1.jpg",
        "https://hastatravel.com/assets/img/kereta/myvi/myvi_2.jpg",
        "https://hastatravel.com/assets/img/kereta/myvi/myvi_3.jpg",
        "https://hastatravel.com/assets/img/kereta/myvi/myvi_4.jpg",
      ],
      'lastMaintenance': '2024-10-01',
    },
    {
      'name': 'TOYOTA VIOS',
      'modelYear': "2021",
      'make': "Toyota",
      'model': "Vios",
      'type': 'Sedan',
      'gear': 'Automatic',
      'color': "Silver",
      'status': "Used",
      'fuelLevel': "Quarter",
      'plateNo': "DEF5678",
      'seats': 5,
      'pricePerDay': 300.0,
      'mainImage': 'assets/vios.png',
      'additionalImages': [
        "https://b2c-cdn.carsome.my/cdn-cgi/image/format=auto,quality=50,width=3200/B2C/73ca4d9d-ccce-4f36-964f-6d8dfdaf5c83.jpg",
        "https://b2c-cdn.carsome.my/cdn-cgi/image/format=auto,quality=50,width=3200/B2C/1b300c86-94d5-4ebc-8d61-8b9d19c18e53.jpg",
        "https://b2c-cdn.carsome.my/cdn-cgi/image/format=auto,quality=50,width=3200/B2C/2135119a-86f6-4f03-a45b-dd3788e4ecd7.jpg",
        "https://b2c-cdn.carsome.my/cdn-cgi/image/format=auto,quality=50,width=3200/B2C/91d3eaa4-246a-4995-86ed-2b799bf93324.jpg",
        "https://b2c-cdn.carsome.my/cdn-cgi/image/format=auto,quality=50,width=3200/B2C/f1825170-4c20-4c6c-a11e-f63a0bd32cc5.jpg",
      ],
      'lastMaintenance': '2024-10-01',
    },
    {
      'name': 'HONDA CITY',
      'modelYear': "2022",
      'make': "Honda",
      'model': "City",
      'type': 'Sedan',
      'gear': 'Automatic',
      'color': "Red",
      'status': "Used",
      'fuelLevel': "Half",
      'plateNo': "JKL8901",
      'seats': 5,
      'pricePerDay': 300.0,
      'mainImage': 'assets/honda.png',
      'additionalImages': [
        "https://b2c-cdn.carsome.my/cdn-cgi/image/format=auto,quality=50,width=3200/B2C/e30bcf41-294c-4906-a3e5-941795721677.jpg",
        "https://b2c-cdn.carsome.my/cdn-cgi/image/format=auto,quality=50,width=3200/B2C/a313da64-82eb-4290-aa5b-66cade30904a.jpg",
        "https://b2c-cdn.carsome.my/cdn-cgi/image/format=auto,quality=50,width=3200/B2C/22eea523-44c1-40c6-875c-04d2e282338c.jpg",
        "https://b2c-cdn.carsome.my/cdn-cgi/image/format=auto,quality=50,width=3200/B2C/2a9ef894-d98c-4447-b0a6-63f4cac04886.jpg",
        "https://b2c-cdn.carsome.my/cdn-cgi/image/format=auto,quality=50,width=3200/B2C/502bd5d4-85ea-4ad4-b658-e6d7dc63db48.jpg",
        "https://b2c-cdn.carsome.my/cdn-cgi/image/format=auto,quality=50,width=3200/B2C/02e25eb1-42cf-448d-9244-76bc40b58cc4.jpg",
      ],
      'lastMaintenance': '2024-10-01',
    },
    {
      'name': 'STAREX 2.5',
      'modelYear': "2023",
      'make': "Hyundai",
      'model': "Starex",
      'type': 'Minivan',
      'gear': 'Automatic',
      'color': "Black",
      'status': "New",
      'fuelLevel': "Full",
      'plateNo': "XYZ5678",
      'seats': 9,
      'pricePerDay': 550.0,
      'mainImage': 'assets/starex.png',
      'additionalImages': [
        "https://hastatravel.com/assets/img/kereta/starex/starex-1.jpg",
        "https://hastatravel.com/assets/img/kereta/starex/starex-2.jpg",
        "https://hastatravel.com/assets/img/kereta/starex/starex-3.jpg",
        "https://hastatravel.com/assets/img/kereta/starex/starex-4.jpg",
        "https://hastatravel.com/assets/img/kereta/starex/starex-5.jpg",
      ],
      'lastMaintenance': '2024-10-01',
    },
  ];

  for (var car in carData) {
    // Check if the car already exists using the name as a document ID
    DocumentReference carDoc = cars.doc(car['name']);
    DocumentSnapshot existingCar = await carDoc.get();

    if (!existingCar.exists) {
      // If the car does not exist, add it
      await carDoc.set(car);
      print('Added car: ${car['name']} to Firestore.');
    } else {
      print('Car already exists: ${car['name']}. Skipping.');
    }
  }
  print('Car data processed for Firestore.');
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorObservers: [routeObserver], // Register RouteObserver here
      title: 'Hasta Rental',
      routes: {
        '/carInventory': (context) => CarInventoryPage(),
        '/logout': (context) => LoginPage(),
        '/customerHomepage': (context) => CustomerHomePage(),
      },
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const LoginPage(),
    );
  }
}