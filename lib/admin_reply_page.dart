import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:video_player/video_player.dart';

class AdminReplyPage extends StatefulWidget {
  final String reviewId;
  final String carName;

  const AdminReplyPage(
      {super.key, required this.reviewId, required this.carName});

  @override
  _AdminReplyPageState createState() => _AdminReplyPageState();
}

class _AdminReplyPageState extends State<AdminReplyPage> {
  final TextEditingController _replyController = TextEditingController();
  String? reviewContent;
  String? existingReply;
  String? username;
  double? rating;
  String? videoUrl;
  String? imageUrl;
  String? profileImageUrl; // Profile image URL
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchReview();
  }

  Future<void> _fetchReview() async {
    try {
      DocumentSnapshot reviewSnapshot = await FirebaseFirestore.instance
          .collection('reviews')
          .doc(widget.reviewId)
          .get();

      if (reviewSnapshot.exists) {
        String? fetchedUsername =
            reviewSnapshot['username']; // Fetching username
        setState(() {
          reviewContent = reviewSnapshot['review'];
          username = fetchedUsername;
          rating = reviewSnapshot['rating']?.toDouble();
          videoUrl = reviewSnapshot['videoUrl'];
          imageUrl = reviewSnapshot['imageUrl'];
        });

        await _fetchProfileImage(fetchedUsername!);
            } else {
        setState(() {
          reviewContent = "Review not found.";
        });
      }
    } catch (e) {
      setState(() {
        reviewContent = "Error fetching review: $e";
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _fetchProfileImage(String username) async {
    try {
      // Fetch profile image based on the username from the users collection
      QuerySnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: username)
          .get();

      if (userSnapshot.docs.isNotEmpty) {
        setState(() {
          profileImageUrl =
              userSnapshot.docs.first['imageUrl']; // Get profile image URL
        });
      }
    } catch (e) {
      print("Error fetching profile image: $e");
    }
  }

  Future<void> _submitReply() async {
    String replyText = _replyController.text.trim();
    if (replyText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reply cannot be empty.')),
      );
      return;
    }

    if (existingReply != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reply has already been submitted.')),
      );
      return;
    }

    try {
      DocumentReference reviewRef =
          FirebaseFirestore.instance.collection('reviews').doc(widget.reviewId);

      await reviewRef.update({
        'replies': replyText,
      });

      setState(() {
        existingReply = replyText;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reply submitted successfully.')),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit reply: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      appBar: AppBar(
        title: Text('Reply to $username'),
        backgroundColor: Color.fromARGB(255, 19, 25, 37),
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile picture and username
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            profileImageUrl != null
                            ? CircleAvatar(
                                radius: 24,
                                backgroundImage: NetworkImage(profileImageUrl!),
                              )
                            : CircleAvatar(
                                radius: 24,
                                backgroundColor: Colors.grey[300],
                                child: Icon(Icons.person, color: Colors.white),
                              ),
                        SizedBox(width: 12),
                        Text(
                          username ?? 'Unknown User',
                          style:
                              TextStyle(fontSize: 16),
                        ),
                          ],
                        ),
                        RatingBarIndicator(
                            rating: rating!,
                            itemBuilder: (context, _) => Icon(
                              Icons.star,
                              color: Colors.amber,
                            ),
                            itemCount: 5,
                            itemSize: 20.0,
                            direction: Axis.horizontal,
                          ),
                      ],
                    ),
                    SizedBox(height: 16),
                    // Review content
                    Text(
                      'Review:',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,),
                    ),
                    SizedBox(height: 8),
                    Text(
                      reviewContent ?? 'No content available.',
                      style: TextStyle(fontSize: 16, color: Colors.grey[800]),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        // Video URL
                        if (videoUrl != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => FullScreenViewer(
                                      mediaType: 'video',
                                      mediaUrl: videoUrl!,
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
                          ),
                          SizedBox(width: 8),
// Image from the review
                        if (imageUrl != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => FullScreenViewer(
                                      mediaType: 'image',
                                      mediaUrl: imageUrl!,
                                    ),
                                  ),
                                );
                              },
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(imageUrl!,
                                    height: 100, width: 100, fit: BoxFit.cover),
                              ),
                            ),
                          ),
                      ],
                    ),

                    SizedBox(height: 16),
                    // Reply section
                    Text(
                      'Your Reply:',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,),
                    ),
                    SizedBox(height: 2),
                    existingReply != null
                        ? Text(
                            existingReply!,
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          )
                        : TextField(
                            controller: _replyController,
                            maxLines: 4,
                            decoration: InputDecoration(
                              hintText: 'Type your reply here...',
                              border: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.grey),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: Color.fromARGB(255, 19, 25, 37)),
                              ),
                              contentPadding: EdgeInsets.all(10),
                            ),
                          ),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        existingReply == null
                        ? ElevatedButton(
                            onPressed: _submitReply,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color.fromARGB(255, 19, 25, 37),
                              padding: EdgeInsets.symmetric(
                                  vertical: 14, horizontal: 30),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                            child: Text(
                              'Submit Reply',
                              style:
                                  TextStyle(fontSize: 16, color: Colors.white),
                            ),
                          )
                        : SizedBox.shrink(),
                      ],
                    ),
                    
                  ],
                ),
              ),
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
