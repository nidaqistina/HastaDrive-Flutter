import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminCarDetailsPage extends StatefulWidget {
  final String carId;

  const AdminCarDetailsPage({
    super.key,
    required this.carId,
  });

  @override
  _AdminCarDetailsPageState createState() => _AdminCarDetailsPageState();
}

class _AdminCarDetailsPageState extends State<AdminCarDetailsPage> {
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();
  final String _imgbbApiKey = '322729043822e4f733559305a853de30';

  Future<void> _pickAndUploadImage() async {
    try {
      final XFile? pickedFile =
          await _picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        File imageFile = File(pickedFile.path);

        // Check file size (e.g., limit to 5MB)
        int fileSize = await imageFile.length();
        if (fileSize > 5 * 1024 * 1024) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("File size exceeds 5MB limit.")),
          );
          return;
        }

        // Upload to ImgBB
        String? uploadedImageUrl = await _uploadToImgBB(imageFile);
        if (uploadedImageUrl != null) {
          // Update Firebase
          await _addImageToFirebase(uploadedImageUrl);
        }
      }
    } catch (e) {
      print("Error picking or uploading image: $e");
    }
  }

  // Method to pick and upload main image
  Future<void> _pickAndUploadMainImage() async {
    try {
      final XFile? pickedFile =
          await _picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        File imageFile = File(pickedFile.path);

        // Check file size (e.g., limit to 5MB)
        int fileSize = await imageFile.length();
        if (fileSize > 5 * 1024 * 1024) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("File size exceeds 5MB limit.")),
          );
          return;
        }

        // Upload to ImgBB
        String? uploadedImageUrl = await _uploadToImgBB(imageFile);
        if (uploadedImageUrl != null) {
          // Update Firebase with the new main image URL
          await _updateMainImageInFirebase(uploadedImageUrl);
        }
      }
    } catch (e) {
      print("Error picking or uploading image: $e");
    }
  }

  Future<String?> _uploadToImgBB(File imageFile) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.imgbb.com/1/upload'),
      );
      request.fields['key'] = _imgbbApiKey;
      request.files
          .add(await http.MultipartFile.fromPath('image', imageFile.path));

      var response = await request.send();
      if (response.statusCode == 200) {
        var responseBody = await http.Response.fromStream(response);
        var jsonData = json.decode(responseBody.body);
        return jsonData['data']['url'];
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to upload image to ImgBB.")),
        );
        return null;
      }
    } catch (e) {
      print("Error uploading to ImgBB: $e");
      return null;
    }
  }

  // Update Firebase with the new main image URL
  Future<void> _updateMainImageInFirebase(String imageUrl) async {
    try {
      DocumentReference carDoc =
          FirebaseFirestore.instance.collection('cars').doc(widget.carId);

      // Update the main image URL in Firebase
      await carDoc.update({'mainImage': imageUrl});
      setState(() {}); // Refresh UI

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Main image updated successfully.")),
      );
    } catch (e) {
      print("Error updating main image in Firebase: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to update main image.")),
      );
    }
  }

  Future<void> _addImageToFirebase(String imageUrl) async {
    try {
      DocumentReference carDoc =
          FirebaseFirestore.instance.collection('cars').doc(widget.carId);

      // Retrieve existing images
      DocumentSnapshot carData = await carDoc.get();
      List<dynamic> images = carData['additionalImages'] ?? [];

      if (images.length >= 10) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Cannot add more than 10 images.")),
        );
        return;
      }

      // Add the new image URL
      images.add(imageUrl);
      await carDoc.update({'additionalImages': images});
      setState(() {}); // Refresh UI

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Image added successfully.")),
      );
    } catch (e) {
      print("Error updating Firebase: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to add image to Firebase.")),
      );
    }
  }

  Future<DocumentSnapshot> _fetchCarDetails() async {
    try {
      return await FirebaseFirestore.instance
          .collection('cars')
          .doc(widget.carId)
          .get();
    } catch (e) {
      print("Error fetching car details: $e");
      rethrow;
    }
  }

  Future<void> _updateCarDetails(String field, String value) async {
    try {
      await FirebaseFirestore.instance
          .collection('cars')
          .doc(widget.carId)
          .update({field: value});
      setState(() {}); // Refresh the UI
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("$field updated successfully!")),
      );
    } catch (e) {
      print("Error updating $field: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to update $field.")),
      );
    }
  }

  void _showInputDialog(String title, String field) {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Enter new value',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final input = controller.text.trim();
                if (input.isNotEmpty) {
                  _updateCarDetails(field, input);
                  Navigator.pop(context);
                }
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  void _showDateInputDialog(String title, String field) {
    final TextEditingController controller = TextEditingController();
    String? errorText;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(title),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: 'Enter date in YYYY-MM-DD format',
                      errorText: errorText,
                    ),
                  ),
                ],
              ), 
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    final input = controller.text.trim();
                    final dateRegex = RegExp(r'^\d{4}-\d{2}-\d{2}$');

                    if (!dateRegex.hasMatch(input)) {
                      setState(() {
                        errorText = 'Invalid date format. Use YYYY-MM-DD.';
                      });
                      return;
                    }

                    _updateCarDetails(field, input);
                    Navigator.pop(context);
                  },
                  child: const Text('Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _scrollLeft() {
    _scrollController.animateTo(
      _scrollController.offset - 100,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _scrollRight() {
    _scrollController.animateTo(
      _scrollController.offset + 100,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _deleteImage(String imageUrl) async {
    try {
      DocumentReference carDoc =
          FirebaseFirestore.instance.collection('cars').doc(widget.carId);

      // Retrieve the car details
      DocumentSnapshot carData = await carDoc.get();

      // Check if the additionalImages field exists
      if (carData.exists && carData['additionalImages'] != null) {
        List<dynamic> images = List.from(carData['additionalImages']);
        images.remove(imageUrl); // Remove the image from the list

        // Update the Firestore document by removing the image
        await carDoc.update({
          'additionalImages': images,
        });

        // Rebuild the widget to reflect the changes
        setState(() {});
      }
    } catch (e) {
      print("Error deleting image: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;

    return FutureBuilder<DocumentSnapshot>(
      future: _fetchCarDetails(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Scaffold(
            body: Center(child: Text('Car details not available.')),
          );
        }

        var carData = snapshot.data!;
        DateTime? lastMaintenance = carData['lastMaintenance'] != null
            ? DateTime.parse(carData['lastMaintenance'])
            : null;

        // Debugging: Log additional images to check the data
        print("Additional Images: ${carData['additionalImages']}");

        return Scaffold(
          backgroundColor: Colors.grey[300],
          appBar: AppBar(
            backgroundColor: Color.fromARGB(255, 19, 25, 37),
            foregroundColor: Colors.white,
            title: const Text("Car Details"),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.add_a_photo),
                onPressed: _pickAndUploadImage,
              ),
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed:
                    _pickAndUploadMainImage, // Add button to change main image
              ),
            ],
          ),
          body: Padding(
            padding: EdgeInsets.all(screenWidth * 0.03),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.topCenter,
                    children: [
                      Card(
                        margin: EdgeInsets.only(top: screenHeight * 0.04),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.0),
                        ),
                        color: Color.fromARGB(255, 130, 23, 23),
                        elevation: 4,
                        child: Padding(
                          padding: EdgeInsets.all(screenWidth * 0.025),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: screenHeight * 0.05),
                              Center(
                                child: Text(
                                  carData['name'] ?? '',
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.06,
                                    fontWeight: FontWeight.bold,
                                    color: Color.fromARGB(255, 231, 231, 231),
                                  ),
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.005),
                              if (carData['additionalImages'] != null &&
                                  (carData['additionalImages'] as List)
                                      .isNotEmpty)
                                Stack(
                                  children: [
                                    SizedBox(
                                      height: screenHeight * 0.1,
                                      child: ListView.builder(
                                        controller: _scrollController,
                                        scrollDirection: Axis.horizontal,
                                        itemCount: (carData['additionalImages']
                                                as List)
                                            .length,
                                        itemBuilder: (context, index) {
                                          String imageUrl =
                                              carData['additionalImages']
                                                  [index];
                                          return Padding(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: screenWidth * 0.01),
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                              child: Stack(
                                                children: [
                                                  Image.network(
                                                    imageUrl,
                                                    width: screenWidth * 0.3,
                                                    height: screenHeight * 0.12,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (context,
                                                        error, stackTrace) {
                                                      return Icon(
                                                        Icons.error,
                                                        size: 40,
                                                        color: Colors.red,
                                                      );
                                                    },
                                                  ),
                                                  Positioned(
                                                    top: -6,
                                                    right: -6,
                                                    child: IconButton(
                                                      icon: Icon(
                                                        Icons.delete,
                                                        color: Colors.red,
                                                        size:
                                                            screenWidth * 0.06,
                                                      ),
                                                      onPressed: () =>
                                                          _deleteImage(
                                                              imageUrl),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    Positioned(
                                      left: 0,
                                      top: screenHeight * 0.04,
                                      bottom: screenHeight * 0.05,
                                      child: GestureDetector(
                                        onTap: _scrollLeft,
                                        child: Icon(
                                          Icons.arrow_back_ios,
                                          color: Colors.black.withOpacity(0.5),
                                          size: screenWidth * 0.05,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      right: 0,
                                      top: screenHeight * 0.04,
                                      bottom: screenHeight * 0.05,
                                      child: GestureDetector(
                                        onTap: _scrollRight,
                                        child: Icon(
                                          Icons.arrow_forward_ios,
                                          color: Colors.black.withOpacity(0.5),
                                          size: screenWidth * 0.05,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              SizedBox(height: screenHeight * 0.01),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        top: -screenHeight * 0.1,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: carData['mainImage'] != null &&
                                    carData['mainImage'].isNotEmpty
                                ? Uri.tryParse(carData['mainImage'])
                                            ?.isAbsolute ==
                                        true
                                    ? Image.network(
                                        carData[
                                            'mainImage']!, // Use the network URL from carData
                                        height: screenHeight * 0.2,
                                        fit: BoxFit.cover,
                                      )
                                    : Image.asset(
                                        carData[
                                            'mainImage']!, // Use the asset path from carData
                                        height: screenHeight * 0.2,
                                        fit: BoxFit.cover,
                                      )
                                : Image.asset(
                                    'assets/images/default_car.jpg', // Fallback to default image if no valid URL or asset path
                                    height: screenHeight * 0.2,
                                    fit: BoxFit.cover,
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  buildDetailItem(
                      "Model Year", carData['modelYear'], screenWidth),
                  buildDetailItem("Make", carData['make'], screenWidth),
                  buildDetailItem("Model", carData['model'], screenWidth),
                  buildDetailItem("Car Type", carData['type'], screenWidth),
                  buildEditableDetailItem(
                      "Color", carData['color'] ?? 'N/A', "color", screenWidth),
                  buildDetailItem("Status", carData['status'], screenWidth),
                  buildEditableDetailItem("Fuel Level",
                      carData['fuelLevel'] ?? 'N/A', "fuelLevel", screenWidth),
                  buildDetailItem("Plate No", carData['plateNo'], screenWidth),
                  buildDetailItem("Gear Type", carData['gear'], screenWidth),
                  buildDetailItem(
                    "Number of Seats",
                    carData['seats']?.toString() ?? 'N/A',
                    screenWidth,
                  ),
                  buildEditableDetailItem(
                      "Last Maintenance",
                      lastMaintenance != null
                          ? "${lastMaintenance.year}-${lastMaintenance.month.toString().padLeft(2, '0')}-${lastMaintenance.day.toString().padLeft(2, '0')}"
                          : "N/A",
                      "lastMaintenance",
                      screenWidth),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget buildDetailItem(String label, dynamic value, double screenWidth) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: screenWidth * 0.01),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              "$label :",
              style: TextStyle(
                fontSize: screenWidth * 0.035,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: Container(
              padding: EdgeInsets.symmetric(
                  vertical: screenWidth * 0.02,
                  horizontal: screenWidth * 0.025),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Text(
                value?.toString() ?? 'N/A',
                style: TextStyle(
                  fontSize: screenWidth * 0.035,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildEditableDetailItem(
      String label, String value, String field, double screenWidth) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: screenWidth * 0.01),
      child: GestureDetector(
        onTap: () => field == "lastMaintenance"
            ? _showDateInputDialog("Update $label", field)
            : _showInputDialog("Update $label", field),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Text(
                "$label:",
                style: TextStyle(
                  fontSize: screenWidth * 0.035,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(
              flex: 5,
              child: Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: Color.fromARGB(255, 213, 227, 255),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: screenWidth * 0.035,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
