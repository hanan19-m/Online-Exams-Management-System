import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SubmittedExams extends StatefulWidget {
  const SubmittedExams({super.key});

  @override
  _SubmittedExamsState createState() => _SubmittedExamsState();
}

class _SubmittedExamsState extends State<SubmittedExams> {
  String? _examId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _studentSubmissions = [];
  bool _isGraded = false; 

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is String) {
      setState(() {
        _examId = args;
        _fetchStudentSubmissions();
      });
    }
  }

  Future<void> _fetchStudentSubmissions() async {
    if (_examId == null) return;

    try {
      final examDoc = await _firestore.collection('Exams').doc(_examId).get();
      if (examDoc.exists) {
        setState(() {
          _isGraded = examDoc['Status'] == 'Graded';
        });
      }

      final attemptsSnapshot = await _firestore
          .collection('Attempts')
          .where('ExamID', isEqualTo: _examId)
          .get();

      Map<String, DocumentSnapshot> latestAttempts = {};

      for (var doc in attemptsSnapshot.docs) {
        final studentId = doc['StudentID'];
        final attemptNumber = doc['AttemptNumber'];

        if (!latestAttempts.containsKey(studentId) ||
            latestAttempts[studentId]!['AttemptNumber'] < attemptNumber) {
          latestAttempts[studentId] = doc;
        }
      }

      List<Map<String, dynamic>> submissions = [];

      for (var studentId in latestAttempts.keys) {
        final studentDoc = await _firestore.collection('Students').doc(studentId).get();
        
        if (studentDoc.exists) {
          final studentName = studentDoc['name'] ?? 'Unknown';
          final attempt = latestAttempts[studentId]!;
          final endDateTime = (attempt['EndDateTime'] as Timestamp).toDate();

          submissions.add({
            'studentName': studentName,
            'studentId': studentId,
            'attemptId': attempt.id,
            'attemptNumber': attempt['AttemptNumber'],
            'endDateTime': endDateTime,
          });
        }
      }

      setState(() {
        _studentSubmissions = submissions;
      });

    } catch (e) {
      print('Error fetching student submissions: $e');
    }
  }

  void _showGradingConfirmationDialog() {
    if (_isGraded) return; 

    AwesomeDialog(
      context: context,
      dialogType: DialogType.info,
      animType: AnimType.bottomSlide,
      title: 'Confirm',
      desc: 'Notify students that they can view their results now?',
      btnCancelOnPress: () {},
      btnOkOnPress: () async {
        if (_examId != null) {
          await _firestore.collection('Exams').doc(_examId).update({'Status': 'Graded'});

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('All students notified successfully'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );

          setState(() {
            _isGraded = true;
          });
        }
      },
    ).show();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Students Submissions',
          style: TextStyle(fontSize: 24, fontFamily: 'Sorts Mill Goudy'),
        ),
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
        backgroundColor: const Color.fromARGB(255, 8, 41, 114),
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(screenWidth * 0.04),
        itemCount: _studentSubmissions.length,
        itemBuilder: (context, index) {
          final submission = _studentSubmissions[index];
          final studentName = submission['studentName'] ?? 'Unknown';
          final studentId = submission['studentId'];
          final attemptId = submission['attemptId'];
          final attemptNumber = submission['attemptNumber'] ?? 0;
          final endDateTime = submission['endDateTime'];

          return Padding(
            padding: EdgeInsets.only(bottom: screenHeight * 0.02),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: Color.fromARGB(255, 8, 41, 114)),
              ),
              elevation: 5,
              child: Padding(
                padding: EdgeInsets.all(screenWidth * 0.04),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.article,
                          size: screenWidth * 0.15,
                          color: Color.fromARGB(255, 8, 41, 114),
                        ),
                        SizedBox(width: screenWidth * 0.04),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                studentName,
                                style: TextStyle(
                                  fontSize: screenWidth * 0.055,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Sorts Mill Goudy',
                                  color: Color.fromARGB(255, 8, 41, 114),
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.01),
                              Text(
                                'Last Attempt Number: $attemptNumber',
                                style: TextStyle(
                                  fontSize: screenWidth * 0.04,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Sorts Mill Goudy',
                                  color: Color.fromARGB(255, 8, 41, 114),
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.01),
                              Text(
                                'Submitted: ${DateFormat('d/M/yyyy, h:mm a').format(endDateTime)}',
                                style: TextStyle(
                                  fontSize: screenWidth * 0.04,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Sorts Mill Goudy',
                                  color: Color.fromARGB(255, 8, 41, 114),
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
                          Navigator.of(context).pushNamed(
                            'studentsubmission',
                            arguments: {
                              'examId': _examId,
                              'studentId': studentId,
                              'lastAttemptId': attemptId,
                            },
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.05,
                            vertical: screenHeight * 0.015,
                          ),
                        ),
                        child: Text(
                          'Start Grading',
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isGraded ? null : _showGradingConfirmationDialog,
        backgroundColor: _isGraded ? Colors.amber : Colors.green,
        child: const Icon(
          Icons.check,
          color: Colors.white,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}