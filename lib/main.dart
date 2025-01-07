import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'auth/login.dart';
import 'exam_service.dart';
import 'notifications.dart';
import 'student/availableexams.dart';
import 'student/completedexams.dart';
import 'student/exam.dart';
import 'student/examanswers.dart';
import 'student/studenthomepage.dart';
import 'teacher/createexam.dart';
import 'teacher/studentsubmission.dart';
import 'teacher/submissions.dart';
import 'teacher/submittedexams.dart';
import 'teacher/teacherhomepage.dart';
import 'welcomePage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: FirebaseOptions(
    apiKey: "AIzaSyCQYUeU4GPthFif0U4g-j-6H_8BxNbcuCs",
    authDomain: "itcs444project-cb0e2.firebaseapp.com",
    projectId: "itcs444project-cb0e2",
    storageBucket: "itcs444project-cb0e2.firebasestorage.app",
    messagingSenderId: "164024235304",
    appId: "1:164024235304:web:d70abe49fa2f7a598f0c1d",
    measurementId: "G-JRJX05MJG0"
  ));

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ExamService()..startCheckingExams(),
      child: MaterialApp(
        title: 'EDUHUB',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          appBarTheme: const AppBarTheme(
            backgroundColor: Color.fromARGB(255, 8, 41, 114),
            titleTextStyle: TextStyle(
              color: Colors.white, 
              fontSize: 18, 
              fontWeight: FontWeight.bold, 
              fontFamily: 'Patua One',
            ),
            iconTheme: IconThemeData(
              color: Colors.white,
            ),
          ),
        ),
        home: const WelcomePage(),
        routes: {
          "studenthomepage": (context) => const StudentHomePage(),
          "teacherhomepage": (context) => const TeacherHomePage(),
          "login": (context) => const Login(),
          "welcomePage": (context) => const WelcomePage(),
          "createexam": (context) => const CreateExam(),
          "submittedexams": (context) => const SubmittedExams(),
          "submissions": (context) => const Submissions(),
          "studentsubmission": (context) => const StudentSubmission(),
          "completedexams": (context) => const CompletedExams(),
          "availableexams": (context) => const AvailableExams(),
          "exam": (context) => const Exam(),
          "examanswers": (context) => const ExamAnswers(),
          "notifications": (context) => const Notifications(),
        },
      ),
    );
  }
}