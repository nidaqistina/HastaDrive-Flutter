import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:video_player/video_player.dart';
import 'admin_reply_page.dart';

class AllReviewsPage extends StatefulWidget {
  const AllReviewsPage({super.key});

  @override
  _AllReviewPageState createState() => _AllReviewPageState();
}

class _AllReviewPageState extends State<AllReviewsPage> {
  String selectedFilter = 'All';
  final List<String> filterOptions = [
    'All',
    'Unreplied',
    'Replied',
    'Below 3 Stars',
    'Above 3 stars'
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.grey.shade300,
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 19, 25, 37),
        foregroundColor: Colors.white,
        title: const Text('All Reviews'),
      ),
      body: Column(
        children: [
          SizedBox(height: 3),
          // Horizontal Filter Section
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            height: screenHeight * 0.06,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: filterOptions.length,
              itemBuilder: (context, index) {
                final filter = filterOptions[index];
                final isSelected = selectedFilter == filter;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5.0),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedFilter = filter; // Update the selected filter
                      });
                    },
                    child: Chip(
                      label: Text(
                        filter,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black,
                        ),
                      ),
                      backgroundColor:
                          isSelected ? Color.fromARGB(255, 19, 25, 37) : Colors.grey[100],
                      side: BorderSide.none,
                    ),
                  ),
                );
              },
            ),
          ),

          // Reviews List (Filtered using StreamBuilder)
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('reviews')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  // Retrieve reviews from Firestore
                  var reviews = snapshot.data!.docs;

                  // Apply filter logic
                  if (selectedFilter == 'Unreplied') {
                    reviews = reviews
                        .where((review) =>
                            !(review.data() as Map).containsKey('replies'))
                        .toList();
                  } else if (selectedFilter == 'Replied') {
                    reviews = reviews
                        .where((review) =>
                            (review.data() as Map).containsKey('replies'))
                        .toList();
                  } else if (selectedFilter == 'Below 3 Stars') {
                    reviews = reviews
                        .where((review) => (review['rating'] ?? 0.0) <= 3.0)
                        .toList();
                  } else if (selectedFilter == 'Above 3 stars') {
                    reviews = reviews
                        .where((review) => (review['rating'] ?? 0.0) > 3.0)
                        .toList();
                  }

                  // If no reviews match the filter, show an empty state
                  if (reviews.isEmpty) {
                    return const Center(
                      child: Text('No reviews match the selected filter.'),
                    );
                  }

                  // Display filtered reviews in a list
                  return ListView.builder(
                    itemCount: reviews.length,
                    itemBuilder: (context, index) {
                      var review = reviews[index];

                      return FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('cars')
                            .doc(review['carName']) // Fetch based on carName
                            .get(),
                        builder: (context, carSnapshot) {
                          if (!carSnapshot.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          var carData = carSnapshot.data!;
                          var mainImage = carData['mainImage'] ?? '';

                          return Card(
                            color: Colors.grey[100],
                            margin: EdgeInsets.symmetric(
                              vertical: screenHeight * 0.009,
                              horizontal: screenHeight * 0.012,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      if (mainImage.isNotEmpty)
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          child: (mainImage
                                                      .startsWith('http') ||
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
                                        ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          '${review['carName']}',
                                          style: TextStyle(
                                            fontSize: screenWidth * 0.05,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: screenHeight * 0.005),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      RatingBarIndicator(
                                        rating: review['rating'] ?? 0.0,
                                        itemBuilder: (context, index) =>
                                            const Icon(
                                          Icons.star,
                                          color: Colors.amber,
                                        ),
                                        itemCount: 5,
                                        itemSize: 20,
                                        direction: Axis.horizontal,
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: screenHeight * 0.005),
                                  Text(
                                    'By ${review['username']}',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  SizedBox(width: screenWidth * 0.009),
                                  Text(
                                    '${review['review']}',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  SizedBox(height: screenHeight * 0.005),
                                  if ((review['videoUrl'] != null &&
                                          review['videoUrl'] != '') ||
                                      (review['imageUrl'] != null &&
                                          review['imageUrl'] != ''))
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        // Video Preview
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
                                                    mediaUrl:
                                                        review['videoUrl'],
                                                  ),
                                                ),
                                              );
                                            },
                                            child: Container(
                                              width: 80,
                                              height: 80,
                                              decoration: BoxDecoration(
                                                color: Colors.grey[200],
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: const Center(
                                                child: Icon(
                                                  Icons.play_circle_fill,
                                                  color: Colors.grey,
                                                  size: 40,
                                                ),
                                              ),
                                            ),
                                          ),
                                        SizedBox(width: screenWidth * 0.012),
                                        // Image Preview
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
                                                    mediaUrl:
                                                        review['imageUrl'],
                                                  ),
                                                ),
                                              );
                                            },
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child: Image.network(
                                                review['imageUrl'],
                                                width: 80,
                                                height: 80,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  const SizedBox(height: 12),
                                  Align(
                                    alignment: Alignment.bottomRight,
                                    child: (review.data() as Map<String,
                                                    dynamic>?)?['replies'] !=
                                                null &&
                                            (review['replies'] as String)
                                                .isNotEmpty
                                        ? Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.end,
                                                children: const [
                                                  Text(
                                                    'You have replied to this review.',
                                                    style: TextStyle(
                                                        color: Colors.green,
                                                        fontStyle:
                                                            FontStyle.italic),
                                                  ),
                                                ],
                                              ),
                                              const Divider(color: Colors.grey),
                                              const SizedBox(
                                                  height:
                                                      8), // Adds space between the text and the reply
                                              const Text(
                                                'Your Reply:',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                              const SizedBox(
                                                  height:
                                                      4), // Adds space between label and reply text
                                              Text(
                                                review[
                                                    'replies'], // Display the reply content here
                                                style: const TextStyle(
                                                    color: Colors.black),
                                              ),
                                            ],
                                          )
                                        : TextButton(
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      AdminReplyPage(
                                                    reviewId: review.id,
                                                    carName: review['carName'],
                                                  ),
                                                ),
                                              );
                                            },
                                            child: Text(
                                              'Reply',
                                              style: TextStyle(
                                                color: Color.fromARGB(255, 19, 25, 37),
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
                    },
                  );
                }),
          )
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
