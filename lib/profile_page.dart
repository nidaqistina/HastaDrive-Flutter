import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart'; // For calling and WhatsApp chat
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'edit_profile_page.dart'; // Import EditProfilePage

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  Future<Map<String, dynamic>> fetchUserData() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception("User is not logged in.");

      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      return userDoc.data() as Map<String, dynamic>;
    } catch (e) {
      print('Error fetching user data: $e');
      return {};
    }
  }

  Future<void> _showLogoutDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[200],
          title: const Text('Confirm Logout'),
          content: const Text('Are you sure you want to log out?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.red),
              ),
            ),
            TextButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.pushNamedAndRemoveUntil(
                    context, '/logout', (route) => false);
              },
              child: const Text(
                'Logout',
                style: TextStyle(color: Color.fromARGB(255, 130, 23, 23)),
              ),
            ),
          ],
        );
      },
    );
  }

  /*Future<void> _callSupport(String phoneNumber) async {
    final Uri phoneUri = Uri.parse("tel:$phoneNumber");
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      print("Could not launch phone app.");
    }
  }*/

  @override
  Widget build(BuildContext context) {
    // hasta whatsapp number
    //final String supportPhoneNumber = "601110900700";
    final Uri phoneUri = Uri.parse("tel:601110900700");
    final Uri whatsapp = Uri.parse("https://wa.me/601110900700");

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF800000),
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: fetchUserData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError ||
              !snapshot.hasData ||
              snapshot.data!.isEmpty) {
            return const Center(child: Text('Error loading profile data'));
          } else {
            final userData = snapshot.data!;
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundImage: userData['imageUrl'] != null
                          ? NetworkImage(userData['imageUrl'])
                          : const NetworkImage(
                              'https://via.placeholder.com/150'),
                      backgroundColor: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      userData['name'] ?? 'N/A',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      userData['email'] ?? 'N/A',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.shade300,
                            blurRadius: 5,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Account Details',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const Divider(color: Colors.grey),
                          ProfileDetail(
                              label: 'Phone Number',
                              value: userData['phone'] ?? 'N/A'),
                          const SizedBox(height: 8),
                          ProfileDetail(
                              label: 'Gender',
                              value: userData['gender'] ?? 'N/A'),
                          const SizedBox(height: 8),
                          ProfileDetail(
                              label: 'Username',
                              value: userData['username'] ?? 'N/A'),
                          const SizedBox(height: 8),
                          ProfileDetail(
                              label: 'Matric No',
                              value: userData['matricNo'] ?? 'N/A'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                EditProfilePage(userData: userData),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF800000),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 50, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: const Text(
                        'Edit Profile',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        _showLogoutDialog(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade300,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 50, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: const Text(
                        'Logout',
                        style:
                            TextStyle(fontSize: 16, color: Color(0xFF800000)),
                      ),
                    ),
                    const SizedBox(height: 30),
                    const Divider(color: Colors.grey),
                    const SizedBox(height: 5),
                    Column(
                      children: [
                        const Text(
                          'Customer Support',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () => launchUrl(phoneUri),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    const Color(0xFF800000), // Maroon color
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                              ),
                              icon: const Icon(Icons.phone,
                                  color: Colors.white), // Phone icon
                              label: const Text(
                                'Contact Us',
                                style: TextStyle(
                                    fontSize: 16, color: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton.icon(
                              onPressed: () => launchUrl(whatsapp),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(
                                    0xFF25D366), // WhatsApp green color
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                              ),
                              icon: const FaIcon(FontAwesomeIcons.whatsapp,
                                  color: Colors.white), // WhatsApp icon
                              label: const Text(
                                'WhatsApp Us',
                                style: TextStyle(
                                    fontSize: 16, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }
        },
      ),
    );
  }
}

class ProfileDetail extends StatelessWidget {
  final String label;
  final String value;

  const ProfileDetail({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 16, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}
