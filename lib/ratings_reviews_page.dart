import 'package:chewie/chewie.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

import 'package:video_player/video_player.dart';

class RatingsReviewsPage extends StatefulWidget {
  final String mainImage;
  final String orderId;

  const RatingsReviewsPage({
    super.key,
    required this.orderId,
    required this.mainImage,
  });

  @override
  _RatingsReviewsPageState createState() => _RatingsReviewsPageState();
}

class _RatingsReviewsPageState extends State<RatingsReviewsPage> {
  double starRating = 0;
  TextEditingController reviewController = TextEditingController();

  String? carName;
  double? totalPrice;
  String? pickupDate;
  String? returnDate;
  String? name;
  String? phone;
  String? username;
  String? plateNo;
  String? uploadedImageUrl;
  String? uploadedVideoUrl;
  String? mainImage;
  late String profileImage;

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

  Future<void> _pickReviewImage() async {
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
          uploadedImageUrl = imageUrl; // Store the image URL
        });
      }
    }
  }

  // Display the uploaded image if available
  Widget buildImagePreview() {
    if (uploadedImageUrl != null) {
      return Column(
        children: [
          const Text(
            'Uploaded Image:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Image.network(
            uploadedImageUrl!,
            height: 120,
            width: 120,
            fit: BoxFit.contain,
          ),
        ],
      );
    }
    return const SizedBox(); // Return an empty box if no image is uploaded
  }

  Future<String?> _uploadVideoToCloudinary(File videoFile) async {
    const String cloudName =
        'deh4rivp8'; // Replace with your Cloudinary cloud name
    const String uploadPreset =
        'ml_default'; // Replace with your Cloudinary upload preset

    final url =
        Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/video/upload');

    final request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(
        await http.MultipartFile.fromPath('file', videoFile.path),
      );

    try {
      final response = await request.send();
      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final jsonResponse = json.decode(responseData);
        return jsonResponse['secure_url'];
      } else {
        throw Exception('Failed to upload video');
      }
    } catch (e) {
      debugPrint('Error uploading video: $e');
      return null;
    }
  }

  Future<void> _pickReviewVideo() async {
    final ImagePicker picker = ImagePicker();
    final XFile? videoFile =
        await picker.pickVideo(source: ImageSource.gallery);

    if (videoFile != null) {
      final int videoSize = await videoFile.length();
      if (videoSize > 10 * 1024 * 1024) {
        // Limit video size to 10MB
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Video size must not exceed 10MB.')),
        );
        return;
      }

      final videoUrl = await _uploadVideoToCloudinary(File(videoFile.path));
      if (videoUrl != null) {
        setState(() {
          uploadedVideoUrl = videoUrl;
        });
      }
    }
  }

  Widget buildVideoPreview() {
    if (uploadedVideoUrl != null) {
      VideoPlayerController? videoController;
      ChewieController? chewieController;

      videoController =
          VideoPlayerController.networkUrl(Uri.parse(uploadedVideoUrl!));
      chewieController = ChewieController(
        videoPlayerController: videoController,
        aspectRatio: 16 / 9,
        autoInitialize: true,
        looping: false,
        errorBuilder: (context, errorMessage) {
          return Center(child: Text('Error: $errorMessage'));
        },
      );

      return Column(
        children: [
          const Text(
            'Uploaded Video:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () {
              // Handle tap if you want to add any specific action.
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Chewie(controller: chewieController),
              ),
            ),
          ),
        ],
      );
    }
    return const SizedBox();
  }

  // Function to store the review in Firestore
  Future<void> storeReview() async {
    try {
      // Get the current time when the review is submitted
      String timeSubmitted =
          DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
      User? user = FirebaseAuth.instance.currentUser;

      // Create a new document in Firestore
      await FirebaseFirestore.instance.collection('reviews').add({
        'username': username ?? 'Anonymous',
        'userId': user?.uid,
        'carName': carName ?? 'Unknown Car',
        //'plateNo': plateNo ?? 'Null',
        'totalPrice': totalPrice ?? 0.0,
        'pickupDate': pickupDate ?? 'N/A',
        'returnDate': returnDate ?? 'N/A',
        'plateNumber': plateNo ?? 'Unknown Plate',
        'timeSubmitted': timeSubmitted,
        'orderId': widget.orderId,
        'rating': starRating,
        'review': reviewController.text,
        'imageUrl': uploadedImageUrl,
        'videoUrl': uploadedVideoUrl,
      });

      // Show confirmation dialog after successful submission
      _showConfirmationDialog();
    } catch (e) {
      print('Error storing review: $e');
    }
  }

  Future<void> fetchBookingDetails() async {
    try {
      DocumentSnapshot document = await FirebaseFirestore.instance
          .collection('bookings')
          .doc(widget.orderId)
          .get();

      if (document.exists) {
        setState(() {
          carName = document['carName'] ?? 'No Car Name';
          plateNo = document['plateNo'] ?? 'No Plate Number';
          totalPrice = document['totalPrice']?.toDouble() ?? 0.0;

          // Convert Firestore Timestamp to DateTime and format it
          Timestamp? pickupTimestamp = document['pickupDate'];
          Timestamp? returnTimestamp = document['returnDate'];
          if (pickupTimestamp != null) {
            pickupDate =
                DateFormat('dd MMM yyyy').format(pickupTimestamp.toDate());
          }
          if (returnTimestamp != null) {
            returnDate =
                DateFormat('dd MMM yyyy').format(returnTimestamp.toDate());
          }

          // Fetch customer details after getting the userId
          String userId =
              document['userId']; // Assuming bookings have a userId field
          if (userId.isNotEmpty) {
            fetchCustomerDetails(userId); // Fetch user details using userId
          } else {
            print('No userId found in the booking document.');
          }
        });
      } else {
        print('Booking document does not exist.');
      }
    } catch (e) {
      print('Error fetching booking details: $e');
    }
  }

  Future<void> fetchCustomerDetails(String userId) async {
    try {
      DocumentSnapshot document = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (document.exists) {
        setState(() {
          profileImage =
              document['imageUrl'] ?? 'https://via.placeholder.com/150';
          name = document['name'] ?? 'No Name';
          phone = document['phone'] ?? 'No Phone';
          username = document['username'] ?? 'No Username';
        });
      } else {
        print('User document does not exist.');
      }
    } catch (e) {
      print('Error fetching customer details: $e');
    }
  }

  Future<void> fetchCarImage(String carId) async {
    try {
      DocumentSnapshot document =
          await FirebaseFirestore.instance.collection('cars').doc(carId).get();

      if (document.exists) {
        setState(() {
          mainImage = document['mainImage'] ?? '';
        });
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    profileImage = widget.mainImage.isNotEmpty
        ? widget.mainImage
        : 'https://via.placeholder.com/150';
    fetchBookingDetails();
  }

  Widget buildRatingStars(double rating, Function(double) onRatingChanged) {
    return Row(
      children: List.generate(5, (index) {
        return IconButton(
          icon: Icon(
            index < rating ? Icons.star : Icons.star_border,
            color: Colors.yellow[700],
          ),
          onPressed: () {
            onRatingChanged(index + 1.0);
          },
        );
      }),
    );
  }

  void _showConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Review Submitted'),
        content: const Text('Your review has been submitted successfully!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 130, 23, 23),
        foregroundColor: Colors.white,
        title: const Text('Rate Car'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Car Details
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 130, 21, 21),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your Booking:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Row(
                      children: [
                        // Image
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
                        // Booking details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Car Name: ${carName ?? 'Loading...'}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'Plate Number: ${plateNo ?? 'Loading...'}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'Booking Date: $pickupDate - $returnDate',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'Total Price: RM${totalPrice?.toStringAsFixed(2) ?? 'Loading...'}',
                                style: const TextStyle(
                                  fontSize: 12,
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

              // Owner Details Section
              const Text(
                'Customer Detail',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundImage: NetworkImage(profileImage),
                    backgroundColor: Colors.grey.shade300,
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(username ?? 'Loading...',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(name ?? 'Loading...'),
                      Text(phone ?? 'Loading...'),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Write Review Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Rating',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  buildRatingStars(starRating, (value) {
                    setState(() {
                      starRating = value;
                    });
                  }),
                ],
              ),
              const SizedBox(height: 8),

              // Photo and Video Buttons
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton.icon(
                      style: ButtonStyle(
                        backgroundColor: WidgetStatePropertyAll(Colors.grey[300]),
                      ),
                      onPressed:
                          _pickReviewImage, // Update this button to pick an image
                      icon: const Icon(Icons.photo_camera, color: Color.fromARGB(255, 130, 23, 23),),
                      label: const Text('Add photo', style: TextStyle(color: Color.fromARGB(255, 130, 23, 23)),),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      style: ButtonStyle(
                        backgroundColor: WidgetStatePropertyAll(Colors.grey[300]),
                      ),
                      onPressed: _pickReviewVideo,
                      icon: const Icon(Icons.videocam, color: Color.fromARGB(255, 130, 23, 23)),
                      label: const Text('Add video', style: TextStyle(color: Color.fromARGB(255, 130, 23, 23)),),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Display uploaded image and video preview
              buildImagePreview(),
              buildVideoPreview(),

              // Review Input Field
              TextField(
                controller: reviewController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Type here...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),

              // Submit Button
              Center(
                child: ElevatedButton(
                  onPressed: storeReview,
                  // _showConfirmationDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF800000),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text('Submit'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
