import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'exam_service.dart'; 

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  String home = 'login';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user == null) {
        print('User is currently signed out!');
        if (!mounted) return;
        setState(() {
          home = 'login';
          isLoading = false;
        });
      } else {
        String uid = user.uid;
        checkUserRole(uid);
      }
    });

    final examService = Provider.of<ExamService>(context, listen: false);
    examService.startCheckingExams(); 
  }

  Future<void> checkUserRole(String uid) async {
    try {
      DocumentSnapshot teacherDoc = await FirebaseFirestore.instance
          .collection('Teachers')
          .doc(uid)
          .get();

      if (teacherDoc.exists) {
        if (!mounted) return;
        setState(() {
          home = 'teacherhomepage';
        });
      } else {
        DocumentSnapshot studentDoc = await FirebaseFirestore.instance
            .collection('Students')
            .doc(uid)
            .get();

        if (studentDoc.exists) {
          if (!mounted) return;
          setState(() {
            home = 'studenthomepage';
          });
        } else {
          if (!mounted) return;
          setState(() {
            home = 'login';
          });
        }
      }
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
      print('Redirecting to: $home');
    } catch (e) {
      print('Error checking user role: $e');
      if (!mounted) return;
      setState(() {
        home = 'login';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : GestureDetector(
              onTap: () {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  home,
                  (route) => false,
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white,
                      const Color.fromARGB(255, 228, 230, 252)
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset('assets/Logo.png', width: 228, height: 264),
                      SizedBox(height: 60),
                      Text(
                        'EDUHUB',
                        style: TextStyle(
                          fontFamily: 'Poller One',
                          fontSize: 60,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 8, 41, 114),
                        ),
                      ),
                      SizedBox(height: 20),
                      Text(
                        'Your Gateway\nto Online Exams!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Poor Story',
                          fontSize: 50,
                          color: Color.fromARGB(255, 8, 41, 114),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}