// ignore_for_file: unused_field

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // FirebaseAuth for user authentication

class EditProfilePage extends StatefulWidget {
  final Map<String, dynamic> userData;

  const EditProfilePage({super.key, required this.userData});

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _usernameController;

  File? _selectedImage;
  String? _uploadedImageUrl;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.userData['name']);
    _phoneController = TextEditingController(text: widget.userData['phone']);
    _usernameController =
        TextEditingController(text: widget.userData['username']);
    _uploadedImageUrl = widget.userData['imageUrl']; // Existing image URL
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
      await _uploadImageToImgBB(XFile(pickedFile.path));
    }
  }

  Future<String?> _uploadImageToImgBB(XFile imageFile) async {
    const String apiKey = '322729043822e4f733559305a853de30';
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
        final jsonData = jsonDecode(responseData);

        setState(() {
          _uploadedImageUrl = jsonData['data']['url'];
          _selectedImage = null;
        });

        print('Image Uploaded: $_uploadedImageUrl');
        return _uploadedImageUrl;
      } else {
        print('Error uploading image: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error: $e');
      return null;
    }
  }

  Future<void> _saveChanges() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in.')),
      );
      return;
    }

    final updatedData = {
      'name': _nameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'username': _usernameController.text.trim(),
      'imageUrl': _uploadedImageUrl ?? widget.userData['imageUrl'],
      'matricNo': widget.userData['matricNo'],
      'userType': widget.userData['userType'],
      'verified': widget.userData['verified'],
    };

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update(updatedData);
      print('Profile updated: $updatedData');
      Navigator.pop(context); // Return to previous screen
    } catch (e) {
      print('Error updating profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Error updating profile. Please try again.')),
      );
    }
  }

  Future<void> _changePassword() async {
  final currentUser = FirebaseAuth.instance.currentUser;

  // Variables to hold input values
  String currentPassword = '';
  String newPassword = '';
  String confirmNewPassword = '';

  // Show dialog to get current and new password inputs
  bool? shouldChange = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Current Password'),
              onChanged: (value) {
                currentPassword = value;
              },
            ),
            TextField(
              obscureText: true,
              decoration: const InputDecoration(labelText: 'New Password'),
              onChanged: (value) {
                newPassword = value;
              },
            ),
            TextField(
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Confirm New Password'),
              onChanged: (value) {
                confirmNewPassword = value;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (newPassword != confirmNewPassword) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Passwords do not match!')),
                );
                return;
              }
              Navigator.pop(context, true);
            },
            child: const Text('Change'),
          ),
        ],
      );
    },
  );

  if (shouldChange != true || currentPassword.isEmpty || newPassword.isEmpty) {
    return; // User canceled or fields were empty
  }

  try {
    // Reauthenticate user
    AuthCredential credential = EmailAuthProvider.credential(
      email: currentUser?.email ?? '',
      password: currentPassword,
    );

    await currentUser?.reauthenticateWithCredential(credential);

    // Update password
    await currentUser?.updatePassword(newPassword);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Password changed successfully!')),
    );
  } on FirebaseAuthException catch (e) {
    if (e.code == 'wrong-password') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wrong current password.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.message}')),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e')),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: const Color(0xFF800000),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey[300],
                      backgroundImage: _uploadedImageUrl != null
                          ? NetworkImage(_uploadedImageUrl!)
                          : null,
                      child: _uploadedImageUrl == null
                          ? const Icon(Icons.person,
                              size: 60, color: Colors.white)
                          : null,
                    ),
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.white,
                      child: const Icon(Icons.edit,
                          size: 20, color: Colors.black54),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: TextEditingController(
                    text: widget.userData['email']), // Display email
                decoration: const InputDecoration(
                  labelText: 'Email',
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF800000)),
                  ),
                ),
                readOnly: true, // Make the field read-only
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone Number'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'Username'),
              ),
              const SizedBox(height: 16),
// "Change Password" with a text label
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Password',
                        style: TextStyle(
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: _changePassword,
                        child: const Text(
                          'Change Password',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF800000), // Indicate it's clickable
                            //decoration: TextDecoration.underline, // Underline to mimic link behavior
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Divider(color: Colors.grey),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: _saveChanges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF800000),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: const Text('Save Changes',
                        style: TextStyle(fontSize: 16, color: Colors.white)),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 45, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: const Text('Cancel',
                        style:
                            TextStyle(fontSize: 16, color: Color(0xFF800000))),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
