//SignUp Page
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_page.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController matricController = TextEditingController();
  String gender = 'Male'; // Default gender

  // Function to validate email domain
  bool isValidEmail(String email) {
    return email.endsWith('@graduate.utm.my');
  }

  // Function to check if email is already registered in Firestore
  Future<bool> isEmailRegistered(String email) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: email)
        .get();

    return snapshot.docs.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.grey.shade100,
        title: const Text('Sign Up'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: size.height * 0.03),
              Text(
                'Create an Account',
                style: TextStyle(
                  fontSize: size.height * 0.03,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 130, 23, 23),
                ),
              ),
              SizedBox(height: size.height * 0.03),
              TextField(
                controller: emailController,
                style: const TextStyle(color: Color.fromARGB(255, 130, 23, 23)),
                decoration: const InputDecoration(
                  labelText: 'Email',
                  labelStyle: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(150, 130, 23, 23)),
                  filled: true,
                  fillColor: Color.fromARGB(255, 231, 231, 231),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                      borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(4)),
                    borderSide: BorderSide(
                        color: Color.fromARGB(255, 231, 231, 231), width: 0.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(4)),
                    borderSide: BorderSide(
                        color: Color.fromARGB(255, 130, 23, 23), width: 1.5),
                  ),
                ),
                cursorColor: const Color.fromARGB(255, 130, 23, 23),
              ),
              SizedBox(height: size.height * 0.02),
              TextField(
                controller: passwordController,
                obscureText: true,
                style: const TextStyle(color: Color.fromARGB(255, 130, 23, 23)),
                decoration: const InputDecoration(
                  labelText: 'Password',
                  labelStyle: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(150, 130, 23, 23)),
                  filled: true,
                  fillColor: Color.fromARGB(255, 231, 231, 231),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                      borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(4)),
                    borderSide: BorderSide(
                        color: Color.fromARGB(255, 231, 231, 231), width: 0.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(4)),
                    borderSide: BorderSide(
                        color: Color.fromARGB(255, 130, 23, 23), width: 1.5),
                  ),
                ),
                cursorColor: const Color.fromARGB(255, 130, 23, 23),
              ),
              SizedBox(height: size.height * 0.02),
              TextField(
                controller: nameController,
                style: const TextStyle(color: Color.fromARGB(255, 130, 23, 23)),
                decoration: const InputDecoration(
                  labelText: 'Name',
                  labelStyle: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(150, 130, 23, 23)),
                  filled: true,
                  fillColor: Color.fromARGB(255, 231, 231, 231),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                      borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(4)),
                    borderSide: BorderSide(
                        color: Color.fromARGB(255, 231, 231, 231), width: 0.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(4)),
                    borderSide: BorderSide(
                        color: Color.fromARGB(255, 130, 23, 23), width: 1.5),
                  ),
                ),
                cursorColor: const Color.fromARGB(255, 130, 23, 23),
              ),
              SizedBox(height: size.height * 0.02),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: Color.fromARGB(255, 130, 23, 23)),
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  labelStyle: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(150, 130, 23, 23)),
                  filled: true,
                  fillColor: Color.fromARGB(255, 231, 231, 231),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                      borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(4)),
                    borderSide: BorderSide(
                        color: Color.fromARGB(255, 231, 231, 231), width: 0.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(4)),
                    borderSide: BorderSide(
                        color: Color.fromARGB(255, 130, 23, 23), width: 1.5),
                  ),
                ),
                cursorColor: const Color.fromARGB(255, 130, 23, 23),
              ),
              SizedBox(height: size.height * 0.02),
              TextField(
                controller: usernameController,
                style: const TextStyle(color: Color.fromARGB(255, 130, 23, 23)),
                decoration: const InputDecoration(
                  labelText: 'Username',
                  labelStyle: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(150, 130, 23, 23)),
                  filled: true,
                  fillColor: Color.fromARGB(255, 231, 231, 231),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                      borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(4)),
                    borderSide: BorderSide(
                        color: Color.fromARGB(255, 231, 231, 231), width: 0.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(4)),
                    borderSide: BorderSide(
                        color: Color.fromARGB(255, 130, 23, 23), width: 1.5),
                  ),
                ),
                cursorColor: const Color.fromARGB(255, 130, 23, 23),
              ),
              SizedBox(height: size.height * 0.02),
              TextField(
                controller: matricController,
                style: const TextStyle(color: Color.fromARGB(255, 130, 23, 23)),
                decoration: const InputDecoration(
                  labelText: 'Matric Number',
                  labelStyle: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(150, 130, 23, 23)),
                  filled: true,
                  fillColor: Color.fromARGB(255, 231, 231, 231),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                      borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(4)),
                    borderSide: BorderSide(
                        color: Color.fromARGB(255, 231, 231, 231), width: 0.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(4)),
                    borderSide: BorderSide(
                        color: Color.fromARGB(255, 130, 23, 23), width: 1.5),
                  ),
                ),
                cursorColor: const Color.fromARGB(255, 130, 23, 23),
              ),
              SizedBox(height: size.height * 0.02),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Gender',
                  labelStyle: const TextStyle(
                    color: Color.fromARGB(150, 130, 23, 23),
                    fontWeight: FontWeight.w600,
                  ),
                  filled: true,
                  fillColor: const Color.fromARGB(255, 231, 231, 231),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: const BorderSide(
                      color: Color.fromARGB(255, 231, 231, 231),
                      width: 0.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: const BorderSide(
                      color: Color.fromARGB(255, 130, 23, 23),
                      width: 2.0,
                    ),
                  ),
                ),
                value: gender,
                dropdownColor: const Color.fromARGB(255, 231, 231, 231),
                icon: const Icon(
                  Icons.arrow_drop_down,
                  color: Color.fromARGB(255, 130, 23, 23),
                ),
                onChanged: (String? newValue) {
                  setState(() {
                    gender = newValue!;
                  });
                },
                items: <String>['Male', 'Female', 'Other']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(
                      value,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 130, 23, 23),
                      ),
                    ),
                  );
                }).toList(),
              ),
              SizedBox(height: size.height * 0.03),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white70),
                onPressed: () async {
                  String email = emailController.text.trim();
                  if (!isValidEmail(email)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Please use a valid @graduate.utm.my email address'),
                      ),
                    );
                    return;
                  }

                  // Check if the email is already registered
                  bool isRegistered = await isEmailRegistered(email);
                  if (isRegistered) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('This email is already registered'),
                      ),
                    );
                    return;
                  }

                  try {
                    // Perform Firebase sign-up
                    UserCredential userCredential = await FirebaseAuth.instance
                        .createUserWithEmailAndPassword(
                      email: email,
                      password: passwordController.text.trim(),
                    );

                    // Send email verification
                    await userCredential.user!.sendEmailVerification();

                    // Store user details in Firestore
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(userCredential.user!.uid)
                        .set({
                      'email': email,
                      'name': nameController.text.trim(),
                      'phone': phoneController.text.trim(),
                      'username': usernameController.text.trim(),
                      'matricNo':
                          matricController.text.trim(), // Store matric no.
                      'gender': gender,
                      'userType': 'customer', // Fixed as customer
                      'verified': false, // Set this to false initially
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Verification email sent. Please check your inbox.'),
                      ),
                    );

                    // Navigate to the login page after successful sign-up
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const LoginPage()),
                    );
                  } on FirebaseAuthException catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(e.message ?? 'Unknown error occurred'),
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('An error occurred: $e'),
                      ),
                    );
                  }
                },
                child: const Text(
                  'Sign Up',
                  style: TextStyle(color: Color.fromARGB(255, 130, 23, 23)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
