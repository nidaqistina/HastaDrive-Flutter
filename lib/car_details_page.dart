import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:video_player/video_player.dart';

class CarDetailsPage extends StatefulWidget {
  final String carId;

  const CarDetailsPage({
    super.key,
    required this.carId,
  });

  @override
  _CarDetailsPageState createState() => _CarDetailsPageState();
}

class _CarDetailsPageState extends State<CarDetailsPage> {
  final ScrollController _scrollController = ScrollController();

  Future<DocumentSnapshot> _fetchCarDetails() {
    return FirebaseFirestore.instance
        .collection('cars')
        .doc(widget.carId)
        .get();
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
  
  Widget _buildReviewSection(String carName) {
  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection('reviews')
        .where('carName', isEqualTo: carName)
        .snapshots(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }

      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
        return const Center(child: Text('No reviews available.'));
      }

      final reviews = snapshot.data!.docs;

      return SizedBox(
        height: 230,
        child: PageView.builder(
          itemCount: reviews.length,
          controller: PageController(viewportFraction: 0.8),
          itemBuilder: (context, index) {
            final reviewData = reviews[index].data() as Map<String, dynamic>;

            return Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                margin: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(20),
                ),
                height: 200,
                width: double.infinity,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Username and Rating Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              // User Profile Image
                          FutureBuilder<DocumentSnapshot>(
                            future: FirebaseFirestore.instance
                                .collection('users')
                                .doc(reviewData['userId']) // Assuming you have userId in reviewData
                                .get(),
                            builder: (context, userSnapshot) {
                              if (userSnapshot.connectionState == ConnectionState.waiting) {
                                return const CircularProgressIndicator(); // Loading indicator
                              }

                              if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                                return const CircleAvatar(); // Default avatar if user not found
                              }

                              final userData = userSnapshot.data!.data() as Map<String, dynamic>;

                              return CircleAvatar(
                                backgroundImage: NetworkImage(userData['imageUrl'] ?? 'default_image_url'), // Replace with a default image URL if needed
                                radius: 20, // Adjust the radius as needed
                              );
                            },
                          ),
                          SizedBox(width: 5),
                          // Username
                          Text(
                            reviewData['username'] ?? 'Anonymous',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                            ],
                          ),
                          // Rating
                          Row(
                            children: List.generate(
                              (reviewData['rating'] ?? 0).toInt(),
                              (starIndex) => const Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Review Text
                          Expanded(
                            child: Text(
                              reviewData['review'] ?? '',
                              style: const TextStyle(
                                fontSize: 12,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),
                      // Images and Videos Row
                      Row(
                        children: [
                          // Image (if available)
                          if (reviewData['imageUrl'] != null &&
                              reviewData['imageUrl'].toString().isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => FullScreenViewer(
                                      mediaType: 'image',
                                      mediaUrl: reviewData['imageUrl'],
                                    ),
                                  ),
                                );
                              },
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  reviewData['imageUrl'],
                                  height: 100,
                                  width: 100,
                                  fit: BoxFit.cover ),
                              ),
                            ),

                          const SizedBox(width: 8),

                          // Video (if available)
                          if (reviewData['videoUrl'] != null &&
                              reviewData['videoUrl'].toString().isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => FullScreenViewer(
                                      mediaType: 'video',
                                      mediaUrl: reviewData['videoUrl'],
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                height: 100,
                                width: 100,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.black,
                                ),
                                child: const Icon(
                                  Icons.play_arrow,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      );
    },
  );
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

        return Scaffold(
          backgroundColor: Color.fromARGB(255, 245, 245, 245),
          appBar: AppBar(
            backgroundColor: Color.fromARGB(255, 130, 23, 23),
            title: const Text(
              "Car Details",
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
            padding: EdgeInsets.all(screenWidth * 0.03), // Responsive padding
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: screenHeight * 0.1),

                  // Card for Main Image and Additional Images

                  Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.topCenter,
                    children: [
                      // Card for Additional Images and Details
                      Card(
                        margin: EdgeInsets.only(
                            top: screenHeight *
                                0.035), // Space for the floating image

                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.0),
                        ),

                        color: Color.fromARGB(255, 130, 23, 23),

                        elevation: 4,

                        child: Padding(
                          padding: EdgeInsets.all(
                              screenWidth * 0.025), // Padding inside the card

                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                  height: screenHeight *
                                      0.05), // Space to align with the floating image

                              Center(
                                child: Text(
                                  carData['name'] ?? '',
                                  style: TextStyle(
                                    fontSize: screenWidth *
                                        0.06, // Scalable font size for car name

                                    fontWeight: FontWeight.bold,

                                    color: Color.fromARGB(255, 231, 231, 231),
                                  ),
                                ),
                              ),

                              SizedBox(height: screenHeight * 0.005),

                              // Carousel for Additional Images with Scroll Controls

                              if (carData['additionalImages'] != null &&
                                  (carData['additionalImages'] as List)
                                      .isNotEmpty)
                                Stack(
                                  children: [
                                    SizedBox(
                                      height: screenHeight *
                                          0.1, // Adjust height for the carousel

                                      child: ListView.builder(
                                        controller: _scrollController,
                                        scrollDirection: Axis.horizontal,
                                        itemCount: (carData['additionalImages']
                                                as List)
                                            .length,
                                        itemBuilder: (context, index) {
                                          return GestureDetector(
                                            onTap: () {
                                              // Navigate to the full-screen viewer

                                              Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      FullScreenViewer(
                                                    mediaType: 'image',
                                                    mediaUrl: carData[
                                                            'additionalImages']
                                                        [index],
                                                  ),
                                                ),
                                              );
                                            },
                                            child: Padding(
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: screenWidth *
                                                      0.01), // Responsive spacing

                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(8.0),
                                                child: Image.network(
                                                  carData['additionalImages']
                                                      [index],

                                                  width: screenWidth *
                                                      0.3, // Adjust image width for carousel

                                                  height: screenHeight *
                                                      0.12, // Adjust image height for carousel

                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),

                                    // Left Scroll Arrow
                                    Positioned(
                                      left: 0,
                                      top: screenHeight * 0.04,
                                      bottom: screenHeight * 0.05,
                                      child: GestureDetector(
                                        onTap: _scrollLeft,
                                        child: Icon(
                                          Icons.arrow_back_ios,

                                          color: Colors.black.withOpacity(0.5),

                                          size: screenWidth *
                                              0.05, // Scalable icon size
                                        ),
                                      ),
                                    ),

                                    // Right Scroll Arrow
                                    Positioned(
                                      right: 0,
                                      top: screenHeight * 0.04,
                                      bottom: screenHeight * 0.05,
                                      child: GestureDetector(
                                        onTap: _scrollRight,
                                        child: Icon(
                                          Icons.arrow_forward_ios,

                                          color: Colors.black.withOpacity(0.5),

                                          size: screenWidth *
                                              0.05, // Scalable icon size
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                              SizedBox(height: screenHeight * 0.005),
                            ],
                          ),
                        ),
                      ),

                      // Main Car Image Floating Above the Card

                      Positioned(
                        top: -screenHeight *
                            0.1, // Position the image above the card

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
                  const Divider(color: Colors.grey),
                  //REVIEW SECTION
                  _buildReviewSection(carData['name']),

                  // Car Details List (Responsive form-like input fields)
                  buildDetailItem(
                      "Model Year", carData['modelYear'], screenWidth),

                  buildDetailItem("Make", carData['make'], screenWidth),

                  buildDetailItem("Model", carData['model'], screenWidth),

                  buildDetailItem("Car Type", carData['type'], screenWidth),

                  buildDetailItem("Color", carData['color'], screenWidth),

                  buildDetailItem("Status", carData['status'], screenWidth),

                  buildDetailItem(
                      "Fuel Level", carData['fuelLevel'], screenWidth),

                  buildDetailItem("Plate No", carData['plateNo'], screenWidth),

                  buildDetailItem("Gear Type", carData['gear'], screenWidth),

                  buildDetailItem(
                    "Number of Seats",
                    carData['seats']?.toString() ?? 'N/A',
                    screenWidth,
                  ), // Explicitly convert to String

                  buildDetailItem(
                    "Last Maintenance",
                    lastMaintenance != null
                        ? "${lastMaintenance.day}/${lastMaintenance.month}/${lastMaintenance.year}"
                        : "N/A",
                    screenWidth,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Helper function to build each detail row (Responsive font size and padding)
  Widget buildDetailItem(String label, dynamic value, double screenWidth) {
    return Padding(
      padding: EdgeInsets.symmetric(
          vertical: screenWidth * 0.01), // Dynamic vertical padding

      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              "$label :",
              style: TextStyle(
                fontSize: screenWidth * 0.035, // Scalable font size for labels

                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: Container(
              padding: EdgeInsets.symmetric(
                  vertical: screenWidth * 0.02,
                  horizontal: screenWidth * 0.025), // Dynamic padding

              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8.0),
              ),

              child: Text(
                value?.toString() ?? 'N/A', // Convert to String for display

                style: TextStyle(
                  fontSize:
                      screenWidth * 0.035, // Scalable font size for values
                ),
              ),
            ),
          ),
        ],
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
