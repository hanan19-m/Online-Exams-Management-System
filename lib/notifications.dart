import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Notifications extends StatefulWidget {
  const Notifications({super.key});

  @override
  _NotificationsState createState() => _NotificationsState();
}

class _NotificationsState extends State<Notifications> {
  late Future<void> _roleFuture;
  String home = '';
  String firstNavItem = '';
  String secondNavItem = '';
  String firstNavRoute = '';
  String secondNavRoute = '';

  @override
  void initState() {
    super.initState();
    _roleFuture = _initializeUserRole();
  }

  Future<void> _initializeUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await checkUserRole(user.uid);
    }
  }

  Future<void> checkUserRole(String uid) async {
    final teacherCollection = FirebaseFirestore.instance.collection('Teachers');
    final studentCollection = FirebaseFirestore.instance.collection('Students');

    final teacherDoc = await teacherCollection.doc(uid).get();
    if (teacherDoc.exists) {
      setState(() {
        home = "teacherhomepage";
        firstNavItem = "Create Exam";
        secondNavItem = "Submissions";
        firstNavRoute = "createexam";
        secondNavRoute = "submissions";
      });
      return;
    }

    final studentDoc = await studentCollection.doc(uid).get();
    if (studentDoc.exists) {
      setState(() {
        home = "studenthomepage";
        firstNavItem = "Available Exams";
        secondNavItem = "Completed Exams";
        firstNavRoute = "availableexams";
        secondNavRoute = "completedexams";
      });
      return;
    }
  }

  Future<List<Map<String, dynamic>>> _fetchNotifications() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    final notificationsCollection = FirebaseFirestore.instance.collection('Notifications');
    final snapshot = await notificationsCollection.where('UserID', isEqualTo: user.uid).get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final notificationColor = const Color.fromARGB(255, 8, 41, 114);

    return FutureBuilder<void>(
      future: _roleFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text('Error: ${snapshot.error}'),
            ),
          );
        } else {
          return Scaffold(
            appBar: AppBar(
              title: const Text(
                'Notifications',
                style: TextStyle(fontSize: 24, fontFamily: 'Sorts Mill Goudy'),
              ),
              centerTitle: true,
              leading: IconButton(
                icon: Image.asset('assets/Logo.png'),
                onPressed: () {
                  if (home.isNotEmpty) {
                    Navigator.of(context)
                        .pushNamedAndRemoveUntil(home, (route) => false);
                  }
                },
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.exit_to_app),
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                    Navigator.of(context).pushNamedAndRemoveUntil(
                        "login", (route) => false);
                  },
                ),
              ],
              backgroundColor: notificationColor,
            ),
            body: FutureBuilder<List<Map<String, dynamic>>>(
              future: _fetchNotifications(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Text(
                      'No notifications for now',
                      style: TextStyle(
                        fontSize: screenWidth * 0.06,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Sorts Mill Goudy',
                        color: notificationColor,
                      ),
                    ),
                  );
                }

                final notifications = snapshot.data!;

                return ListView.builder(
                  padding: EdgeInsets.all(screenWidth * 0.04),
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final notification = notifications[index];
                    final examTitle = notification['ExamTitle'] ?? 'No Title';
                    final actionText = notification['Action'] ?? 'No Action';
                    final content = notification['Content'] ?? 'No Content';
                    final examId = notification['ExamID'] ?? '';

                    return Padding(
                      padding: EdgeInsets.only(bottom: screenHeight * 0.02),
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(color: notificationColor),
                        ),
                        elevation: 5,
                        child: Padding(
                          padding: EdgeInsets.all(screenWidth * 0.04),
                          child: Column(
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.notifications,
                                    size: screenWidth * 0.15,
                                    color: notificationColor,
                                  ),
                                  SizedBox(width: screenWidth * 0.04),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          examTitle,
                                          style: TextStyle(
                                            fontSize: screenWidth * 0.055,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'Sorts Mill Goudy',
                                            color: notificationColor,
                                          ),
                                        ),
                                        SizedBox(height: screenHeight * 0.01),
                                        Text(
                                          content,
                                          style: TextStyle(
                                            fontSize: screenWidth * 0.04,
                                            fontFamily: 'Sorts Mill Goudy',
                                            color: notificationColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: screenHeight * 0.02),
                              Align(
                                alignment: Alignment.bottomRight,
                                child: ElevatedButton(
                                  onPressed: () {
                                    if (actionText == "Start Grading") {
                                      Navigator.of(context).pushNamed(
                                        "submittedexams",
                                        arguments: examId,
                                      );
                                    } else if (actionText == "Completed Exams") {
                                      Navigator.of(context).pushNamed(
                                        "completedexams",
                                        arguments: examId,
                                      );
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: notificationColor,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: screenWidth * 0.05,
                                      vertical: screenHeight * 0.015,
                                    ),
                                  ),
                                  child: Text(
                                    actionText,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: screenWidth * 0.04,
                                      fontFamily: 'Sorts Mill Goudy',
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            bottomNavigationBar: BottomNavigationBar(
              backgroundColor: notificationColor,
              items: <BottomNavigationBarItem>[
                BottomNavigationBarItem(
                  icon: const Icon(Icons.assignment,
                      color: Colors.white, size: 30),
                  label: firstNavItem,
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.report, color: Colors.white, size: 30),
                  label: secondNavItem,
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.notifications,
                      color: Colors.white, size: 30),
                  label: 'Notifications',
                ),
              ],
              currentIndex: 2,
              selectedItemColor: Colors.amber,
              unselectedItemColor: Colors.white,
              onTap: (index) {
                switch (index) {
                  case 0:
                    if (firstNavRoute.isNotEmpty) {
                      Navigator.of(context).pushNamedAndRemoveUntil(
                          firstNavRoute, (route) => false);
                    }
                    break;
                  case 1:
                    if (secondNavRoute.isNotEmpty) {
                      Navigator.of(context).pushNamedAndRemoveUntil(
                          secondNavRoute, (route) => false);
                    }
                    break;
                  case 2:
                    // Already on Notifications
                    break;
                }
              },
            ),
          );
        }
      },
    );
  }
}