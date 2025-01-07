import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Submissions extends StatefulWidget {
  const Submissions({super.key});

  @override
  _SubmissionsState createState() => _SubmissionsState();
}

class _SubmissionsState extends State<Submissions> {
  final _firestore = FirebaseFirestore.instance;
  List<DocumentSnapshot> _exams = [];
  List<DocumentSnapshot> _filteredExams = [];
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _fetchExams();
  }

  Future<void> _fetchExams() async {
    try {
      final currentUserId = FirebaseAuth.instance.currentUser!.uid;
      final snapshot = await _firestore
          .collection('Exams')
          .where('Status', whereIn: ['Completed', 'Graded']) 
          .where('TeacherID', isEqualTo: currentUserId)
          .get();

      setState(() {
        _exams = snapshot.docs;
        _filteredExams = List.from(_exams);
        _sortExams();
      });
    } catch (e) {
      print('Error fetching exams: $e');
    }
  }

  void _filterExams(String query) async {
    setState(() {
      _searchQuery = query.toLowerCase().trim();
    });

    List<DocumentSnapshot> filteredList = [];
    for (var exam in _exams) {
      final examTitle = exam['ExamTitle'] ?? '';
      final types = await _getExamQuestionTypes(exam.id);

      if (_isFuzzyMatch(examTitle, _searchQuery) ||
          types.any((type) => _isFuzzyMatch(type, _searchQuery))) {
        filteredList.add(exam);
      }
    }

    setState(() {
      _filteredExams = filteredList;
      _sortExams();
    });
  }

  void _sortExams() {
    _filteredExams.sort((a, b) {
      final statusOrder = {'Complete': 0, 'Start': 1, 'Done': 2};
      final statusA = getStatus(a);
      final statusB = getStatus(b);
      return statusOrder[statusA]!.compareTo(statusOrder[statusB]!);
    });
  }

  String getStatus(DocumentSnapshot exam) {
    final studentAttempt =
        _getStudentAttemptInfoSync(exam.id)['attemptNumber'] ?? 0;
    final lastStatus =
        _getStudentAttemptInfoSync(exam.id)['status'] ?? 'NotExist';
    final numberOfAttempts = exam['NumberOfAttempts'] ?? 0;

    if (lastStatus == 'Started') {
      return 'Complete';
    } else if (studentAttempt < numberOfAttempts) {
      return 'Start';
    } else {
      return 'Done';
    }
  }

  Map<String, dynamic> _getStudentAttemptInfoSync(String examId) {
    return {'attemptNumber': 0, 'status': 'NotExist'};
  }

  Future<List<String>> _getExamQuestionTypes(String examId) async {
    try {
      final questionsQuerySnapshot = await _firestore
          .collection('Questions')
          .where('ExamID', isEqualTo: examId)
          .get();

      Set<String> questionTypes = {};
      for (var doc in questionsQuerySnapshot.docs) {
        questionTypes.add(doc['QuestionType']);
      }
      return questionTypes.toList();
    } catch (e) {
      print('Error fetching question types: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> _getStudentAttemptInfo(String examId) async {
    try {
      final attemptsQuerySnapshot = await _firestore
          .collection('Attempts')
          .where('ExamID', isEqualTo: examId)
          .get();

      Set<String> uniqueStudents = {};
      for (var doc in attemptsQuerySnapshot.docs) {
        uniqueStudents.add(doc['StudentID']);
      }

      return {'totalSubmissions': uniqueStudents.length};
    } catch (e) {
      print('Error fetching student attempt: $e');
      return {'totalSubmissions': 0};
    }
  }

  void _navigateToSubmittedExams(String examId) async {
    try {
      await Navigator.of(context).pushNamed('submittedexams', arguments: examId);
      setState(() {
        _fetchExams();
      });
    } catch (e) {
      print('Error navigating to submittedexams: $e');
    }
  }

  void _navigateToExamAnswers(String examId) async {
    try {
      await Navigator.of(context).pushNamed('examanswers', arguments: examId);
      setState(() {
        _fetchExams();
      });
    } catch (e) {
      print('Error navigating to examanswers: $e');
    }
  }

  bool _isFuzzyMatch(String source, String query) {
    source = source.toLowerCase().replaceAll(RegExp(r'\s+'), '');
    query = query.toLowerCase().replaceAll(RegExp(r'\s+'), '');

    if (source.contains(query)) return true;

    int maxDistance = (source.length * 0.2).floor();
    return _levenshteinDistance(source, query) <= maxDistance;
  }

  int _levenshteinDistance(String s, String t) {
    if (s.isEmpty) return t.length;
    if (t.isEmpty) return s.length;

    var v0 = List<int>.generate(t.length + 1, (i) => i);
    var v1 = List<int>.filled(t.length + 1, 0);

    for (var i = 0; i < s.length; i++) {
      v1[0] = i + 1;

      for (var j = 0; j < t.length; j++) {
        var cost = s[i] == t[j] ? 0 : 1;
        v1[j + 1] = [
          v1[j] + 1,
          v0[j + 1] + 1,
          v0[j] + cost
        ].reduce((a, b) => a < b ? a : b);
      }

      var temp = v0;
      v0 = v1;
      v1 = temp;
    }

    return v0[t.length];
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Completed Exams',
          style: TextStyle(fontSize: 24, fontFamily: 'Sorts Mill Goudy'),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Image.asset('assets/Logo.png'),
          onPressed: () {
            Navigator.of(context)
                .pushNamedAndRemoveUntil('teacherhomepage', (route) => false);
          },
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
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(screenWidth * 0.04),
            child: TextField(
              onChanged: _filterExams,
              decoration: InputDecoration(
                hintText: 'Search by title or question types...',
                hintStyle: TextStyle(
                  fontFamily: 'Sorts Mill Goudy',
                  color: Color.fromARGB(255, 8, 41, 114),
                  fontSize: screenWidth * 0.04,
                ),
                prefixIcon:
                    Icon(Icons.search, color: Color.fromARGB(255, 8, 41, 114)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide:
                      BorderSide(color: Color.fromARGB(255, 8, 41, 114)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide:
                      BorderSide(color: Color.fromARGB(255, 8, 41, 114)),
                ),
              ),
            ),
          ),
          Expanded(
            child: _exams.isEmpty
                ? Center(
                    child: Text(
                      'No Completed or Graded exams right now\nyou will be notified when\nyour exam completed',
                      style: TextStyle(
                        fontSize: screenWidth * 0.06,
                        fontFamily: 'Sorts Mill Goudy',
                        fontWeight: FontWeight.bold,
                        color: const Color.fromARGB(255, 8, 41, 114),
                      ),
                    ),
                  )
                : _filteredExams.isEmpty
                    ? Center(
                        child: Text(
                          'No results found',
                          style: TextStyle(
                            fontSize: screenWidth * 0.06,
                            fontFamily: 'Sorts Mill Goudy',
                            fontWeight: FontWeight.bold,
                            color: const Color.fromARGB(255, 8, 41, 114),
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredExams.length,
                        itemBuilder: (context, index) {
                          final exam = _filteredExams[index];
                          final examId = exam.id;
                          final examTitle = exam['ExamTitle'] ?? 'No Title';

                          return FutureBuilder<Map<String, dynamic>>(
                            future: _getStudentAttemptInfo(examId),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                    child: CircularProgressIndicator());
                              }

                              if (snapshot.hasError) {
                                return Center(
                                    child: Text('Error: ${snapshot.error}'));
                              }

                              final totalSubmissions =
                                  snapshot.data?['totalSubmissions'] ?? 0;
                              final startTime =
                                  (exam['StartTime'] as Timestamp).toDate();
                              final endTime =
                                  (exam['EndTime'] as Timestamp).toDate();
                              final duration = exam['Duration'] ?? 0;

                              return Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: screenWidth * 0.04,
                                    vertical: screenHeight * 0.02),
                                child: Card(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    side: BorderSide(
                                        color:
                                            Color.fromARGB(255, 8, 41, 114)),
                                  ),
                                  elevation: 5,
                                  child: Padding(
                                    padding:
                                        EdgeInsets.all(screenWidth * 0.04),
                                    child: Stack(
                                      children: [
                                        Positioned(
                                          top: 0,
                                          right: 0,
                                          child: Text(
                                            '$totalSubmissions Students\nSubmissions',
                                            style: TextStyle(
                                              fontSize: screenWidth * 0.035,
                                              color: Colors.grey,
                                              fontFamily: 'Sorts Mill Goudy',
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Icon(Icons.article,
                                                size: screenWidth * 0.15,
                                                color: Color.fromARGB(
                                                    255, 8, 41, 114)),
                                            SizedBox(
                                                width: screenWidth * 0.04),
                                            Expanded(
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    examTitle,
                                                    style: TextStyle(
                                                      fontSize:
                                                          screenWidth * 0.055,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontFamily:
                                                          'Sorts Mill Goudy',
                                                      color: Color.fromARGB(
                                                          255, 8, 41, 114),
                                                    ),
                                                  ),
                                                  SizedBox(
                                                      height: screenHeight *
                                                          0.01),
                                                  Text(
                                                    'From ${DateFormat('d/M - h:mm a').format(startTime)}\nTo ${DateFormat('d/M - h:mm a').format(endTime)}\nDuration $duration minutes',
                                                    textAlign: TextAlign.left,
                                                    style: TextStyle(
                                                      fontSize: screenWidth *
                                                          0.04,
                                                      fontFamily:
                                                          'Sorts Mill Goudy',
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Color.fromARGB(
                                                          255, 8, 41, 114),
                                                    ),
                                                  ),
                                                  SizedBox(
                                                      height: screenHeight *
                                                          0.01),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        Positioned(
                                          bottom: 0,
                                          right: 0,
                                          child: ElevatedButton(
                                            onPressed: () {
                                              if (totalSubmissions > 0) {
                                                _navigateToSubmittedExams(examId);
                                              } else {
                                                _navigateToExamAnswers(examId);
                                              }
                                            },
                                            style: ElevatedButton.styleFrom(
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              backgroundColor: totalSubmissions > 0
                                                  ? Colors.green
                                                  : Color.fromARGB(255, 8, 41, 114),
                                              padding: EdgeInsets.symmetric(
                                                  horizontal:
                                                      screenWidth * 0.04,
                                                  vertical:
                                                      screenHeight * 0.015),
                                            ),
                                            child: Center(
                                              child: Text(
                                                totalSubmissions > 0 ? 'Grade' : 'View',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  fontSize: screenWidth * 0.04,
                                                  fontFamily:
                                                      'Sorts Mill Goudy',
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
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
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color.fromARGB(255, 8, 41, 114),
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.create, color: Colors.white, size: 30),
            label: 'Create Exam',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment, color: Colors.white, size: 30),
            label: 'Submissions',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications, color: Colors.white, size: 30),
            label: 'Notifications',
          ),
        ],
        currentIndex: 1,
        selectedItemColor: Colors.amber,
        unselectedItemColor: Colors.white,
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.of(context).pushNamedAndRemoveUntil("createexam", (route) => false);
              break;
            case 1:
              // Already on Submissions
              break;
            case 2:
              Navigator.of(context).pushNamedAndRemoveUntil("notifications", (route) => false);
              break;
          }
        },
      ),
    );
  }
}