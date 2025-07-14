import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_car_details_page.dart';
import 'add_car_page.dart'; // Import AddCarPage

class CarInventoryPage extends StatefulWidget {
  const CarInventoryPage({super.key});

  @override
  State<StatefulWidget> createState() => _CarInventoryPageState();
}

class _CarInventoryPageState extends State<CarInventoryPage> {
  String? carId;

  Future<void> _deleteCar(String? carId) async {
    try {
      DocumentReference carDoc =
          FirebaseFirestore.instance.collection('cars').doc(carId);

      await carDoc.delete();

      setState(() {});
    } catch (e) {
      print("Error deleting car: $e");
    }
  }

  Future<void> _DeleteConfirmationDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap a button to dismiss
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[200],
          title: const Text('Confirm Deletation'),
          content: const Text('Are you sure you want to delete the car?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Cancel', style: TextStyle(color: Colors.red),),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                _deleteCar(carId);
              },
              child: const Text('Yes', style: TextStyle(color: Color.fromARGB(255, 19, 25, 37)),),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 19, 25, 37),
        foregroundColor: Colors.white,
        title: const Text('Car Inventory',),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('cars').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No cars available'));
          }

          final cars = snapshot.data!.docs;

          return ListView.builder(
            itemCount: cars.length,
            itemBuilder: (context, index) {
              final car = cars[index];
              final carName = car['name'] ?? 'Unnamed';
              final carType = car['type'] ?? 'Unknown';
              final carMainImage = car['mainImage'] ?? '';

              return Card(
                color: Colors.grey[200],
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: ListTile(
                  leading: carMainImage.isNotEmpty
                      ? Uri.tryParse(carMainImage)?.isAbsolute == true
                          ? Image.network(
                              carMainImage,
                              width: 50,
                              height: 50,
                              fit: BoxFit.contain,
                            )
                          : Image.asset(
                              carMainImage,
                              width: 50,
                              height: 50,
                              fit: BoxFit.contain,
                            )
                      : const Icon(Icons.directions_car),
                  title: Text(carName), 
                  subtitle: Text(carType),
                  trailing: SizedBox(
                    width: 100,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    AdminCarDetailsPage(carId: car.id),
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.delete,
                          color: Colors.red),
                          onPressed: () {
                            _DeleteConfirmationDialog(context);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      // Floating Action Button to navigate to AddCarPage
      floatingActionButton: FloatingActionButton(
        backgroundColor: Color.fromARGB(255, 19, 25, 37),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddCarPage()),
          );
        },
        tooltip: 'Add New Car',
        child: Icon(
          Icons.add,
          color: Colors.white,
          ),
      ),
    );
  }
}
