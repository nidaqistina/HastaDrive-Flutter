import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class AddCarPage extends StatefulWidget {
  const AddCarPage({super.key});

  @override
  _AddCarPageState createState() => _AddCarPageState();
}

class _AddCarPageState extends State<AddCarPage> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, dynamic> _carData = {
    'name': '',
    'modelYear': '',
    'make': '',
    'model': '',
    'type': '',
    'color': '',
    'status': '',
    'fuelLevel': '',
    'plateNo': '',
    'gear': '',
    'seats': '',
    'mainImage': '',
    'additionalImages': <String>[],
    'lastMaintenance': null,
    'pricePerDay': 0, // Add default price per day
    'pricePerHour': {}, // Optional, will be a map of hours to price
  };

  final TextEditingController _additionalImagesController =
      TextEditingController();

  Future<void> _submitCar() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // Get the car name from _carData
      final String carName = _carData['name'] ?? '';

      if (carName.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Car name cannot be empty.')),
        );
        return;
      }

      // Remove pricePerHour if it's empty
      if (_carData['pricePerHour'] == null ||
          _carData['pricePerHour'].isEmpty) {
        _carData.remove('pricePerHour');
      }

      try {
        // Reference the document with the car name as ID
        DocumentReference carDoc =
            FirebaseFirestore.instance.collection('cars').doc(carName);

        // Check if a car with the same name already exists
        DocumentSnapshot docSnapshot = await carDoc.get();
        if (docSnapshot.exists) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text('A car with the name "$carName" already exists.')),
          );
          return;
        }

        // Save car data in Firestore
        await carDoc.set(_carData);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Car added successfully!')),
        );

        Navigator.pop(context); // Navigate back after successful submission
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<String?> _uploadImageToImgBB(XFile imageFile) async {
    const String apiKey =
        '322729043822e4f733559305a853de30'; // Replace with your ImgBB API key
    final url = Uri.parse('https://api.imgbb.com/1/upload?key=$apiKey');
    final request = http.MultipartRequest('POST', url);
    final imageBytes = await imageFile.readAsBytes();

    request.files.add(
      http.MultipartFile.fromBytes('image', imageBytes,
          filename: imageFile.name),
    );

    try {
      final response = await request.send();
      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final jsonResponse = json.decode(responseData);
        return jsonResponse['data']['url'];
      } else {
        throw Exception('Failed to upload image');
      }
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
    }
  }

  Future<void> _pickMainImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? imageFile =
        await picker.pickImage(source: ImageSource.gallery);

    if (imageFile != null) {
      final int imageSize = await imageFile.length(); // Get file size in bytes

      // Check if file size exceeds 5MB (5 * 1024 * 1024 bytes)
      if (imageSize > 5 * 1024 * 1024) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image size must not exceed 5MB.')),
        );
        return;
      }

      final imageUrl = await _uploadImageToImgBB(imageFile);
      if (imageUrl != null) {
        setState(() {
          _carData['mainImage'] = imageUrl;
        });
      }
    }
  }

  Future<void> _pickAdditionalImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? imageFile =
        await picker.pickImage(source: ImageSource.gallery);

    if (imageFile != null) {
      final int imageSize = await imageFile.length(); // Get file size in bytes

      // Check if file size exceeds 5MB (5 * 1024 * 1024 bytes)
      if (imageSize > 5 * 1024 * 1024) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image size must not exceed 5MB.')),
        );
        return;
      }

      final imageUrl = await _uploadImageToImgBB(imageFile);
      if (imageUrl != null) {
        setState(() {
          _carData['additionalImages'].add(imageUrl);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.grey[300],
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 19, 25, 37),
        foregroundColor: Colors.white,
        title: const Text('Add New Car'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(screenWidth * 0.04),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                //SizedBox(height: screenHeight * 0.01),
                // Input fields for each car attribute
                _buildTextField(
                  label: 'Car Name',
                  onSave: (value) => _carData['name'] = value,
                ),
                _buildTextField(
                  label: 'Model Year',
                  onSave: (value) => _carData['modelYear'] = value,
                  keyboardType: TextInputType.number,
                ),
                _buildTextField(
                  label: 'Make',
                  onSave: (value) => _carData['make'] = value,
                ),
                _buildTextField(
                  label: 'Model',
                  onSave: (value) => _carData['model'] = value,
                ),
                _buildTextField(
                  label: 'Car Type',
                  onSave: (value) => _carData['type'] = value,
                ),
                _buildTextField(
                  label: 'Color',
                  onSave: (value) => _carData['color'] = value,
                ),
                _buildTextField(
                  label: 'Status',
                  onSave: (value) => _carData['status'] = value,
                ),
                _buildTextField(
                  label: 'Fuel Level',
                  onSave: (value) => _carData['fuelLevel'] = value,
                ),
                _buildTextField(
                  label: 'Plate No',
                  onSave: (value) => _carData['plateNo'] = value,
                ),
                _buildTextField(
                  label: 'Gear Type',
                  onSave: (value) => _carData['gear'] = value,
                ),
                _buildTextField(
                  label: 'Number of Seats',
                  onSave: (value) => _carData['seats'] = value,
                  keyboardType: TextInputType.number,
                ),
                _buildTextField(
                  label: 'Price per Day',
                  onSave: (value) => _carData['pricePerDay'] =
                      double.tryParse(value ?? '') ?? 0,
                  keyboardType: TextInputType.number,
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: screenWidth * 0.02),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Price per Hour (Optional)',
                        style: TextStyle(
                          fontSize: screenWidth * 0.04,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ..._buildPricePerHourFields(),
                      SizedBox(
                        width: double
                            .infinity, // Makes the button span the entire width of its parent
                        child: ElevatedButton(
                          onPressed: () {
                            _addPricePerHour();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color.fromARGB(255, 19, 25, 37), // Button background color
                            foregroundColor: Colors.white, // Text color
                          ),
                          child: const Text('Add Price per Hour'),
                        ),
                      ),
                    ],
                  ),
                ),

                // Main Image Picker
                Padding(
                  padding: EdgeInsets.symmetric(vertical: screenWidth * 0.02),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Main Image',
                        style: TextStyle(
                          fontSize: screenWidth * 0.04,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_carData['mainImage'].isNotEmpty)
                        Image.network(_carData['mainImage'], height: 100),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _pickMainImage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color.fromARGB(255, 19, 25, 37),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Pick Main Image'),
                        ),
                      ),
                    ],
                  ),
                ),

                // Additional Images Picker
                Padding(
                  padding: EdgeInsets.symmetric(vertical: screenWidth * 0.02),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Additional Images',
                        style: TextStyle(
                          fontSize: screenWidth * 0.04,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Wrap(
                        spacing: 8,
                        children: List.generate(
                          _carData['additionalImages'].length,
                          (index) {
                            return Chip(
                              label: Image.network(
                                _carData['additionalImages'][index],
                                height: 50,
                              ),
                              onDeleted: () {
                                setState(() {
                                  _carData['additionalImages'].removeAt(index);
                                });
                              },
                            );
                          },
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          if (_carData['additionalImages'].length >= 10) {
                            // Show message if the limit is reached
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content:
                                    Text('You can add up to 10 images only.'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          } else {
                            _pickAdditionalImage();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color.fromARGB(255, 19, 25, 37),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Add Additional Image'),
                      ),
                    ],
                  ),
                ),

                // Last Maintenance Date Picker
                Padding(
                  padding: EdgeInsets.symmetric(vertical: screenWidth * 0.02),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Last Maintenance Date',
                        style: TextStyle(
                          fontSize: screenWidth * 0.04,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            DateTime? pickedDate = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime.now(),
                            );

                            setState(() {
                              _carData['lastMaintenance'] =
                                  pickedDate?.toIso8601String();
                            });
                                                    },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color.fromARGB(255, 19, 25, 37),
                            foregroundColor: Colors.white,
                          ),
                          child: Text(
                            _carData['lastMaintenance'] != null
                                ? _carData['lastMaintenance'].substring(0, 10)
                                : 'Select Date',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: screenHeight * 0.02),

                // Submit Button
                Center(
                  child: ElevatedButton(
                    onPressed: _submitCar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color.fromARGB(255, 19, 25, 37),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Add Car'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildPricePerHourFields() {
    List<Widget> priceFields = [];
    _carData['pricePerHour'].forEach((hours, price) {
      priceFields.add(Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            Text('$hours hour(s):'),
            SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                initialValue: price.toString(),
                decoration: InputDecoration(
                  labelText: 'Price for $hours hour(s)',
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onSaved: (value) => _carData['pricePerHour'][hours] =
                    double.tryParse(value ?? '') ?? 0,
              ),
            ),
          ],
        ),
      ));
    });

    return priceFields;
  }

  void _addPricePerHour() {
    final hours = ['1', '3', '5', '7', '9', '12', '24']; // Hours options

    for (String hour in hours) {
      if (!_carData['pricePerHour'].containsKey(hour)) {
        _carData['pricePerHour'][hour] = 0; // Default price
      }
    }
    setState(() {});
  }

  // Helper function to create TextField widgets
  Widget _buildTextField({
  required String label,
  required Function(String?) onSave,
  TextInputType keyboardType = TextInputType.text,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: TextFormField(
      cursorColor: const Color.fromARGB(255, 19, 25, 37),
      decoration: InputDecoration(
        labelText: label,
        floatingLabelStyle: const TextStyle(
          color: Color.fromARGB(255, 19, 25, 37),
          fontWeight: FontWeight.bold,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: const BorderSide(
            color: Color.fromARGB(255, 19, 25, 37),
            width: 2.0,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: const BorderSide(
            color: Colors.grey,
            width: 1.5,
          ),
        ),
      ),
      keyboardType: keyboardType,
      validator: (value) =>
          value == null || value.isEmpty ? '$label is required' : null,
      onSaved: onSave,
    ),
  );
}

}
