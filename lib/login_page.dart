//login_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'customer_home_page.dart';
import 'hasta_home_page.dart';
import 'sign_up_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize the AnimationController
    _fadeController = AnimationController(
      vsync: this, // 'this' refers to the current state
      duration: const Duration(seconds: 2), // Animation duration
    );

    // Initialize the CurvedAnimation using the AnimationController
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    // Initialize slide animation
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 1.0), // Start off-screen (from below)
      end: Offset.zero, // End at its original position
    ).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    // Start the animation
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        backgroundColor: Colors.grey[200],
      ),
      body: SingleChildScrollView(
        // Added to allow scrolling
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: size.height * 0.09,
            ),
            SlideTransition(
              position: _slideAnimation,
              child: Image.asset(
                'assets/HASTA_LOGO.png',
                height: size.height * 0.15,
                fit: BoxFit.cover,
              ),
            ),
            SizedBox(height: size.height * 0.008),
            FadeTransition(
              opacity: _fadeAnimation, // Use the animation
              child: Column(children: [
                Text(
                  'Hit the road with ease',
                  style: TextStyle(
                      fontSize: size.width * 0.04, 
                      fontStyle: FontStyle.italic,
                      color: Color.fromARGB(255, 130, 23, 23)
                      ),
                ),
                //SizedBox(height: size.height * 0.008),
                Text(
                  'Welcome!',
                  style: TextStyle(
                    fontSize: MediaQuery.of(context).size.height * 0.035,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ]),
            ),
            SizedBox(height: size.height * 0.02),
            TextField(
              controller: usernameController,
              style: TextStyle(color: Colors.black),
              decoration: const InputDecoration(
                labelText: 'Username',
                labelStyle: TextStyle(
                    color: Color.fromARGB(163, 0, 0, 0)),
                filled: true,
                fillColor: Colors.white54,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(4)),
                    borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(4)),
                  borderSide: BorderSide(
                      color: Color.fromARGB(255, 130, 23, 23), width: 0.5),
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
              obscureText: !_isPasswordVisible, // Toggle password visibility
              style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
              decoration: InputDecoration(
                labelText: 'Password',
                labelStyle: TextStyle(
                    color: Color.fromARGB(163, 0, 0, 0)),
                filled: true,
                fillColor: Colors.white54,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(4)),
                    borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(4)),
                  borderSide: BorderSide(
                      color: Color.fromARGB(255, 130, 23, 23), width: 0.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(4)),
                  borderSide: BorderSide(
                      color: Color.fromARGB(255, 130, 23, 23), width: 1.5),
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: Color.fromARGB(255, 130, 23, 23),
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                ),
              ),
              cursorColor: const Color.fromARGB(255, 130, 23, 23),
            ),
            SizedBox(height: size.height * 0.03),
            ElevatedButton(
              style: ButtonStyle(
                backgroundColor: WidgetStatePropertyAll(Color.fromARGB(255, 130, 23, 23)),
              ),
              onPressed: () async {
                try {
                  final username = usernameController.text.trim();
                  final password = passwordController.text.trim();

                  // Step 1: Retrieve email based on username
                  final userQuery = await FirebaseFirestore.instance
                      .collection('users')
                      .where('username', isEqualTo: username)
                      .get();

                  if (userQuery.docs.isNotEmpty) {
                    final userData = userQuery.docs.first;
                    final email = userData['email'];

                    // Step 2: Sign in with the retrieved email
                    UserCredential userCredential =
                        await FirebaseAuth.instance.signInWithEmailAndPassword(
                      email: email,
                      password: password,
                    );

                    User user = userCredential.user!;

                    // Step 3: Check if the email is verified
                    if (user.emailVerified) {
                      // Update Firestore 'verified' field
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(user.uid)
                          .update({'verified': true});

                      // Redirect based on user type
                      String userType = userData.data().containsKey('userType')
                          ? userData['userType']
                          : 'unknown';

                      if (userType == 'customer') {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const CustomerHomePage()),
                        );
                      } else if (userType == 'hasta') {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const HastaHomePage()),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Unknown user type')),
                        );
                      }
                    } else {
                      // If email is not verified, prompt the user
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content:
                                Text('Please verify your email to proceed.')),
                      );
                      // Optionally resend verification email
                      await user.sendEmailVerification();
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Invalid username')),
                    );
                  }
                } on FirebaseAuthException catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.message ?? 'Unknown error')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('An error occurred: $e')),
                  );
                }
              },
              child: const Text(
                'Login',
                style: TextStyle(color: Colors.white),
              ),
            ),
            SizedBox(height: size.height * 0.015),
            TextButton(
              onPressed: () async {
                // Show a dialog box to ask for the username
                final username = await showDialog<String>(
                  context: context,
                  builder: (BuildContext context) {
                    String enteredUsername = '';
                    String errorMessage = '';
                    return StatefulBuilder(
                      builder: (BuildContext context, StateSetter setState) {
                        return AlertDialog(
                          backgroundColor: const Color.fromARGB(255, 255, 255, 255),
                          title: const Text('Reset Password',
                          style: TextStyle(
                            color: Color.fromARGB(255, 130, 23, 23)
                          )),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextField(
                                cursorColor: Color.fromARGB(255, 130, 23, 23),
                                onChanged: (value) {
                                  enteredUsername = value;
                                },
                                decoration: const InputDecoration(
                                  labelText: 'Enter your username',
                                  labelStyle: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color.fromARGB(150, 130, 23, 23)),
                                  filled: true,
                                  fillColor: Colors.white54,
                                  border: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.all(Radius.circular(4)),
                                      borderSide: BorderSide.none),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(4)),
                                        borderSide: BorderSide(
                                        color: Color.fromARGB(255, 130, 23, 23),
                                        width: 0.5)
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(4)),
                                    borderSide: BorderSide(
                                        color: Color.fromARGB(255, 130, 23, 23),
                                        width: 1.5),
                                  ),
                                ),
                              ),
                              if (errorMessage.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    errorMessage,
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                ),
                            ],
                          ),
                          actions: <Widget>[
                            TextButton(
                              onPressed: () {
                                Navigator.of(context)
                                    .pop(); // Dismiss the dialog
                              },
                              child: const Text('Cancel',
                                  style: TextStyle(color: Colors.red)),
                            ),
                            TextButton(
                              onPressed: () async {
                                // Validate username
                                if (enteredUsername.trim().isEmpty) {
                                  setState(() {
                                    errorMessage = 'Username cannot be empty.';
                                  });
                                  return;
                                }

                                try {
                                  final userQuery = await FirebaseFirestore
                                      .instance
                                      .collection('users')
                                      .where('username',
                                          isEqualTo: enteredUsername.trim())
                                      .get();

                                  if (userQuery.docs.isNotEmpty) {
                                    // Username is valid
                                    Navigator.of(context)
                                        .pop(enteredUsername.trim());
                                  } else {
                                    setState(() {
                                      errorMessage = 'Username not found.';
                                    });
                                  }
                                } catch (e) {
                                  setState(() {
                                    errorMessage = 'An error occurred: $e';
                                  });
                                }
                              },
                              child: const Text(
                                'Submit',
                                style: TextStyle(
                                    color: Color.fromARGB(255, 130, 23, 23)),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                );

                // If the dialog is dismissed without entering a username, return
                if (username == null || username.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content:
                            Text('Username is required to reset password.')),
                  );
                  return;
                }

                try {
                  // Retrieve email based on username
                  final userQuery = await FirebaseFirestore.instance
                      .collection('users')
                      .where('username', isEqualTo: username.trim())
                      .get();

                  if (userQuery.docs.isNotEmpty) {
                    final email = userQuery.docs.first['email'];

                    // Send password reset email
                    await FirebaseAuth.instance
                        .sendPasswordResetEmail(email: email);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('Password reset email sent to $email')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Username not found')),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              },
              child: const Text(
                'Forgot Password?',
                style: TextStyle(color: Color.fromARGB(255, 130, 23, 23)),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          const SignUpPage()), // Navigate to sign-up page
                );
              },
              child: const Text(
                'Don\'t have an account? Sign up here',
                style: TextStyle(color: Color.fromARGB(255, 130, 23, 23)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
