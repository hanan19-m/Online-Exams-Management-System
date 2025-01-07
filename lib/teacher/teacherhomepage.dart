import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class TeacherHomePage extends StatefulWidget {
  const TeacherHomePage({super.key});

  @override
  _TeacherHomePageState createState() => _TeacherHomePageState();
}

class _TeacherHomePageState extends State<TeacherHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teacher Home Page'),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.of(context)
                  .pushNamedAndRemoveUntil("login", (route) => false);
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.white,
              ),
              child: Center(
                child: Text(
                  'Your Gateway\nto Online Exams!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Poor Story',
                    fontSize: 40,
                    color: const Color.fromARGB(255, 8, 41, 114),
                  ),
                ),
              ),
            ),
            _createDrawerItem(
              icon: Icons.home,
              text: 'Home',
              onTap: () {
                Navigator.of(context).pushNamedAndRemoveUntil('teacherhomepage', (route) => false);
              },
            ),
            _drawerDivider(),
            _createDrawerItem(
              icon: Icons.assignment,
              text: 'Create Exam',
              onTap: () {
                Navigator.of(context)
                    .pushNamedAndRemoveUntil("createexam", (route) => false);
              },
            ),
            _drawerDivider(),
            _createDrawerItem(
              icon: Icons.report,
              text: 'View Submissions',
              onTap: () {
                Navigator.of(context)
                    .pushNamedAndRemoveUntil("submissions", (route) => false);
              },
            ),
            _drawerDivider(),
            _createDrawerItem(
              icon: Icons.notifications,
              text: 'Notifications',
              onTap: () {
                Navigator.of(context)
                    .pushNamedAndRemoveUntil("notifications", (route) => false);
              },
            ),
            const Spacer(),
            _drawerDivider(),
            _createDrawerItem(
              icon: Icons.logout,
              text: 'Logout',
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.of(context)
                    .pushNamedAndRemoveUntil("login", (route) => false);
              },
            ),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, const Color.fromARGB(255, 228, 230, 252)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Hello, ',
                              style: TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Sorts Mill Goudy',
                                  color: Color.fromARGB(255, 8, 41, 114)),
                            ),
                            SizedBox(height: 10,),
                            const Text(
                              "\t\tWelcome to",
                              style: TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Sorts Mill Goudy',
                                  color: Color.fromARGB(255, 8, 41, 114)),
                            ),
                            SizedBox(height: 10,),
                            const Text(
                              '\t\t\t\tEDUHUB!',
                              style: TextStyle(
                                  fontSize: 50,
                                  fontFamily: 'Patua One',
                                  color: Color.fromARGB(255, 8, 41, 114)),
                            ),
                          ],
                        ),
                      ),
                      Image.asset(
                        'assets/Logo.png',
                        height: 130,
                        width: 130,
                      ),
                    ],
                  ),
                  const SizedBox(height: 60),
                  Center(
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width * 0.75,
                      child: _buildImageCard(
                        'Create Exam', 
                        'assets/Exam.png', 
                        () {
                          Navigator.of(context)
                    .pushNamedAndRemoveUntil("createexam", (route) => false);
                        }
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Center(
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width * 0.75,
                      child: _buildImageCard(
                        'View Submissions', 
                        'assets/Submission.png', 
                        () {
                          Navigator.of(context)
                    .pushNamedAndRemoveUntil("submissions", (route) => false);
                        }
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageCard(String title, String imagePath, VoidCallback onTap) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.blueAccent.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 180,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, const Color.fromARGB(255, 228, 230, 252)],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Expanded(
                flex: 2,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    gradient: LinearGradient(
                      colors: [Colors.white, const Color.fromARGB(255, 228, 230, 252)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Image.asset(
                    imagePath,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius:
                      const BorderRadius.vertical(bottom: Radius.circular(20)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 8, 41, 114),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.arrow_forward_ios,
                        size: 20,
                        color: Color.fromARGB(255, 8, 41, 114),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _createDrawerItem({
    required IconData icon,
    required String text,
    GestureTapCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        leading: Icon(icon, color: Color.fromARGB(255, 8, 41, 114), size: 28),
        title: Text(
          text,
          style: const TextStyle(
            color: Color.fromARGB(255, 8, 41, 114),
            fontWeight: FontWeight.bold,
            fontSize: 20,
            fontFamily: 'Sorts Mill Goudy',
          ),
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _drawerDivider() {
    return Divider(
      color: Color.fromARGB(255, 184, 184, 184),
      thickness: 1,
      height: 40,
    );
  }
}