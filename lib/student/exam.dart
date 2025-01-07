import 'dart:async';
import 'dart:math';

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Exam extends StatefulWidget {
  const Exam({super.key});

  @override
  _ExamState createState() => _ExamState();
}

class _ExamState extends State<Exam> {
  late final String examId;
  Map<String, dynamic>? examData;
  List<Map<String, dynamic>> questionsData = [];
  List<String> questionIds = [];
  int currentQuestionIndex = 0;
  Map<int, TextEditingController> textControllers = {};
  Map<int, String?> answers = {};
  Duration remainingTime = Duration.zero;
  Timer? timer;
  DateTime attemptStartTime = DateTime.now();
  String? currentAttemptId;
  List<String> randomizedQuestionIds = [];
  double totalDurationInSeconds = 1.0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)!.settings.arguments;
    if (args is String) {
      examId = args;
      _checkAndHandleAttempts();
    } else {
      examId = 'Unknown';
    }
  }

  Future<void> _checkAndHandleAttempts() async {
    try {
      final currentUserId = FirebaseAuth.instance.currentUser!.uid;
      final attemptsSnapshot = await FirebaseFirestore.instance
          .collection('Attempts')
          .where('ExamID', isEqualTo: examId)
          .where('StudentID', isEqualTo: currentUserId)
          .get();

      int maxAttemptNumber = 0;
      DocumentSnapshot? latestAttempt;
      for (var doc in attemptsSnapshot.docs) {
        int attemptNumber = doc['AttemptNumber'] ?? 0;
        if (attemptNumber > maxAttemptNumber) {
          maxAttemptNumber = attemptNumber;
          latestAttempt = doc;
        }
      }

      if (latestAttempt == null) {
        await _createNewAttempt(1, DateTime.now());
      } else {
        final status = latestAttempt['Status'] as String;
        if (status == 'Completed') {
          await _createNewAttempt(maxAttemptNumber + 1, DateTime.now());
        } else if (status == 'Started') {
          currentAttemptId = latestAttempt.id;
          attemptStartTime =
              (latestAttempt['StartDateTime'] as Timestamp).toDate();
          await _fetchExamData();
          await _populateAnswers(latestAttempt.id);
        }
      }
    } catch (e) {
      print('Error handling attempts: $e');
    }
  }

  Future<void> _createNewAttempt(int attemptNumber, DateTime now) async {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    final newAttemptRef =
        await FirebaseFirestore.instance.collection('Attempts').add({
      'AttemptNumber': attemptNumber,
      'EndDateTime': now,
      'ExamID': examId,
      'StartDateTime': now,
      'Status': 'Started',
      'StudentID': currentUserId,
    });

    currentAttemptId = newAttemptRef.id;
    print('New attempt created with ID: $currentAttemptId');
    attemptStartTime = now;
    await _fetchExamData();
  }

  Future<void> _fetchExamData() async {
    try {
      final examDoc = await FirebaseFirestore.instance
          .collection('Exams')
          .doc(examId)
          .get();
      if (examDoc.exists) {
        setState(() {
          examData = examDoc.data();
          totalDurationInSeconds = (examData?['Duration'] ?? 0) * 60.0;
          _calculateRemainingTime();
        });
      }

      final questionsSnapshot = await FirebaseFirestore.instance
          .collection('Questions')
          .where('ExamID', isEqualTo: examId)
          .get();

      List<Map<String, dynamic>> fetchedQuestions = questionsSnapshot.docs
          .map((doc) => doc.data())
          .toList();

      for (int i = 0; i < fetchedQuestions.length; i++) {
        textControllers[i] = TextEditingController();
      }

      if (examData?['QuestionsRandomization'] == true) {
        final random = Random();
        randomizedQuestionIds =
            questionsSnapshot.docs.map((doc) => doc.id).toList();
        for (int i = fetchedQuestions.length - 1; i > 0; i--) {
          final j = random.nextInt(i + 1);
          final tempQuestion = fetchedQuestions[i];
          fetchedQuestions[i] = fetchedQuestions[j];
          fetchedQuestions[j] = tempQuestion;

          final tempId = randomizedQuestionIds[i];
          randomizedQuestionIds[i] = randomizedQuestionIds[j];
          randomizedQuestionIds[j] = tempId;
        }
      } else {
        randomizedQuestionIds =
            questionsSnapshot.docs.map((doc) => doc.id).toList();
      }

      setState(() {
        questionsData = fetchedQuestions;
        questionIds = randomizedQuestionIds;
      });
    } catch (e) {
      print('Error fetching exam: $e');
    }
  }

  Future<void> _populateAnswers(String attemptId) async {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    for (int i = 0; i < questionsData.length; i++) {
      if (i >= questionIds.length) break;

      final questionId = questionIds[i];
      final answerSnapshot = await FirebaseFirestore.instance
          .collection('Answers')
          .where('StudentID', isEqualTo: currentUserId)
          .where('AttemptID', isEqualTo: attemptId)
          .where('QuestionID', isEqualTo: questionId)
          .get();

      if (answerSnapshot.docs.isNotEmpty) {
        final studentAnswer =
            answerSnapshot.docs.first['StudentAnswer'] ?? 'No Answer';
        answers[i] = studentAnswer != 'No Answer' ? studentAnswer : null;

        textControllers[i]?.text =
            studentAnswer != 'No Answer' ? studentAnswer : '';
        print('Loaded answer for question $questionId: $studentAnswer');
      } else {
        print('No answer found for question ID: $questionId');
      }
    }
  }

  Future<void> _submitAnswers({bool isTimeUp = false}) async {
    final now = DateTime.now();
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    if (currentAttemptId == null) {
      print('No valid attempt ID found. Cannot submit.');
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('Attempts')
          .doc(currentAttemptId!)
          .update({
        'EndDateTime': now,
        'Status': 'Completed',
      });

      for (int i = 0; i < questionsData.length; i++) {
        final questionId = questionIds[i];
        final studentAnswer = answers[i] ?? 'No Answer';

        final answerSnapshot = await FirebaseFirestore.instance
            .collection('Answers')
            .where('StudentID', isEqualTo: currentUserId)
            .where('AttemptID', isEqualTo: currentAttemptId)
            .where('QuestionID', isEqualTo: questionId)
            .get();

        if (answerSnapshot.docs.isEmpty) {
          await FirebaseFirestore.instance.collection('Answers').add({
            'AttemptID': currentAttemptId,
            'ExamID': examId,
            'QuestionID': questionId,
            'StudentAnswer': studentAnswer,
            'StudentGrade': 0,
            'StudentID': currentUserId,
          });
        } else {
          final docId = answerSnapshot.docs.first.id;
          await FirebaseFirestore.instance
              .collection('Answers')
              .doc(docId)
              .update({
            'StudentAnswer': studentAnswer,
          });
        }
      }

      if (isTimeUp) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Time Limit Reached'),
              content: Text(
                  'The time limit is up. Your answers have been submitted successfully.'),
            );
          },
        );

        Future.delayed(Duration(seconds: 3), () {
          Navigator.of(context).pop();
          Navigator.of(context).pop();
        });
      } else {
        Navigator.pop(context);
        print('Submission completed');
      }
    } catch (e) {
      print('Error during submission: $e');
    }
  }

  Future<void> _saveAnswersAndExit() async {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    if (currentAttemptId == null) {
      print('No valid attempt ID found. Cannot save.');
      return;
    }

    try {
      for (int i = 0; i < questionsData.length; i++) {
        final questionId = questionIds[i];
        final studentAnswer = answers[i] ?? 'No Answer';

        final answerSnapshot = await FirebaseFirestore.instance
            .collection('Answers')
            .where('StudentID', isEqualTo: currentUserId)
            .where('AttemptID', isEqualTo: currentAttemptId)
            .where('QuestionID', isEqualTo: questionId)
            .get();

        if (answerSnapshot.docs.isEmpty) {
          await FirebaseFirestore.instance.collection('Answers').add({
            'AttemptID': currentAttemptId,
            'ExamID': examId,
            'QuestionID': questionId,
            'StudentAnswer': studentAnswer,
            'StudentGrade': 0,
            'StudentID': currentUserId,
          });
        } else {
          final docId = answerSnapshot.docs.first.id;
          await FirebaseFirestore.instance
              .collection('Answers')
              .doc(docId)
              .update({
            'StudentAnswer': studentAnswer,
          });
        }
      }

      Navigator.pop(context);
      print('Progress saved, exiting exam.');
    } catch (e) {
      print('Error saving progress: $e');
    }
  }

  void _showExitConfirmationDialog() {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.warning,
      animType: AnimType.scale,
      title: 'Exit Confirmation',
      desc:
          'Are you sure you want to exit now? You can continue your attempt later.',
      btnCancelOnPress: () {},
      btnOkOnPress: _saveAnswersAndExit,
    ).show();
  }

  void _calculateRemainingTime() {
    if (examData?['EndTime'] != null) {
      DateTime endTime = (examData!['EndTime'] as Timestamp).toDate();
      setState(() {
        remainingTime = endTime.difference(DateTime.now());
      });

      timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          remainingTime = endTime.difference(DateTime.now());
          if (remainingTime.isNegative) {
            timer.cancel();
            remainingTime = Duration.zero;
            _submitAnswers(isTimeUp: true);
          }
        });
      });
    }
  }

  void _showSubmitDialog() {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.question,
      animType: AnimType.scale,
      title: 'Confirm Submission',
      desc: 'Are you sure you want to submit your answers?',
      btnCancelOnPress: () {},
      btnOkOnPress: () => _submitAnswers(),
    ).show();
  }

  @override
  void dispose() {
    timer?.cancel();
    textControllers.forEach((key, controller) => controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _showExitConfirmationDialog();
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Center(child: Text('Exam')),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _showExitConfirmationDialog,
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
        ),
        body: examData == null
            ? const Center(child: CircularProgressIndicator())
            : Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFE0E0F8), Color(0xFFF8F8FF)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      "${examData?['ExamTitle'] ?? 'Exam Title'}",
                      style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Patua One',
                          color: Color.fromARGB(255, 42, 42, 60)),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Started at ${DateFormat('d/M - h:mm a').format(attemptStartTime)}",
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Sorts Mill Goudy',
                          color: Color.fromARGB(255, 42, 42, 60)),
                    ),
                    Text(
                      "Remaining Time: ${_formatDuration(remainingTime)}",
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                          fontFamily: 'Sorts Mill Goudy'),
                    ),
                    const SizedBox(height: 20),
                    if (questionsData.isNotEmpty)
                      Column(
                        children: [
                          _buildProgressBar(),
                          _buildQuestionCard(questionsData[currentQuestionIndex]),
                        ],
                      ),
                    const Spacer(),
                    const Text(
                      'Your answers will be submitted automatically\nwhen the time limit is up.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                          fontFamily: 'Sorts Mill Goudy'),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (currentQuestionIndex > 0)
                          _buildNavigationButton('Back', _previousQuestion),
                        if (currentQuestionIndex < questionsData.length - 1)
                          _buildNavigationButton('Next', _nextQuestion),
                      ],
                    ),
                    if (currentQuestionIndex == questionsData.length - 1)
                      const SizedBox(height: 20),
                    if (currentQuestionIndex == questionsData.length - 1)
                      _buildSubmitButton(),
                  ],
                ),
              ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return "${duration.inHours}:$minutes:$seconds";
  }

  Widget _buildProgressBar() {
    double progressWidth = MediaQuery.of(context).size.width * 0.9;
    double progress = max(0, remainingTime.inSeconds / totalDurationInSeconds);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: AnimatedContainer(
        duration: const Duration(seconds: 1),
        height: 10,
        width: progress * progressWidth,
        decoration: BoxDecoration(
          color: Colors.green,
          borderRadius: BorderRadius.circular(5),
        ),
      ),
    );
  }

  Widget _buildQuestionCard(Map<String, dynamic> question) {
    String questionText = question['QuestionText'] ?? 'No Question Text';
    double questionGrade = question['QuestionGrade']?.toDouble() ?? 0.0; 

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: const BorderSide(color: Color.fromARGB(255, 8, 41, 114)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Question ${currentQuestionIndex + 1}",
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Sorts Mill Goudy',
                      color: Color.fromARGB(255, 8, 41, 114),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    "-/$questionGrade",
                    style: const TextStyle(
                      fontSize: 18, 
                      fontWeight: FontWeight.bold,
                      color: Colors.grey, 
                      fontFamily: 'Sorts Mill Goudy',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              questionText,
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Sorts Mill Goudy',
                  color: Colors.black),
            ),
            const SizedBox(height: 10),
            _buildAnswerField(question),
          ],
        ),
      ),
    );
  }

  Widget _buildAnswerField(Map<String, dynamic> question) {
    final questionIndex = questionsData.indexOf(question);
    String questionType = question['QuestionType'];
    String? selectedAnswer = answers[questionIndex];

    switch (questionType) {
      case 'MCQ':
        return Column(
          children: (question['Options'] as String).split('/').map((option) {
            String trimmedOption = option.trim();
            return ListTile(
              title: Text(trimmedOption,
                  style: const TextStyle(
                      fontSize: 20,
                      fontFamily: 'Sorts Mill Goudy',
                      color: Color.fromARGB(255, 42, 42, 60))),
              leading: Radio<String>(
                value: trimmedOption,
                groupValue: selectedAnswer,
                onChanged: (value) {
                  setState(() {
                    answers[questionIndex] = value;
                  });
                },
              ),
            );
          }).toList(),
        );
      case 'True/False':
        return Column(
          children: ['True', 'False'].map((option) {
            return ListTile(
              title: Text(option,
                  style: const TextStyle(
                      fontSize: 20,
                      fontFamily: 'Sorts Mill Goudy',
                      color: Color.fromARGB(255, 42, 42, 60))),
              leading: Radio<String>(
                value: option,
                groupValue: selectedAnswer,
                onChanged: (value) {
                  setState(() {
                    answers[questionIndex] = value;
                  });
                },
              ),
            );
          }).toList(),
        );
      case 'Short Answer':
        return TextFormField(
          controller: textControllers[questionIndex],
          decoration: const InputDecoration(
            hintText: 'Enter your answer',
          ),
          onChanged: (value) {
            answers[questionIndex] = value;
          },
        );
      case 'Essay':
        return TextFormField(
          controller: textControllers[questionIndex],
          maxLines: null,
          decoration: const InputDecoration(
            hintText: 'Enter your answer',
          ),
          onChanged: (value) {
            answers[questionIndex] = value;
          },
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildNavigationButton(String label, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color.fromARGB(255, 8, 41, 114),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 24.0),
        child: Text(
          label,
          style: const TextStyle(
              fontSize: 22,
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontFamily: 'Sorts Mill Goudy'),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Center(
      child: ElevatedButton(
        onPressed: _showSubmitDialog,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 24.0),
          child: Text(
            'Submit',
            style: TextStyle(
                fontSize: 22,
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontFamily: 'Sorts Mill Goudy'),
          ),
        ),
      ),
    );
  }

  void _nextQuestion() {
    if (currentQuestionIndex < questionsData.length - 1) {
      setState(() {
        currentQuestionIndex++;
      });
    }
  }

  void _previousQuestion() {
    if (currentQuestionIndex > 0) {
      setState(() {
        currentQuestionIndex--;
      });
    }
  }
}