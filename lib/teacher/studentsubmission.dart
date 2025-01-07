import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class StudentSubmission extends StatefulWidget {
  const StudentSubmission({super.key});

  @override
  _StudentSubmissionState createState() => _StudentSubmissionState();
}

class _StudentSubmissionState extends State<StudentSubmission> {
  late final String examId;
  late final String studentId;
  late final String lastAttemptId;
  Map<String, dynamic>? examData;
  List<Map<String, dynamic>> questionsData = [];
  List<String> questionIds = [];
  int currentQuestionIndex = 0;
  Map<int, TextEditingController> textControllers = {};
  Map<int, TextEditingController> gradeControllers = {};
  Map<int, TextEditingController> feedbackControllers = {};
  Map<int, String?> answers = {};
  Map<int, int?> studentGrades = {};
  Map<int, String?> feedbackDocIds = {}; 

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    examId = args['examId'];
    studentId = args['studentId'];
    lastAttemptId = args['lastAttemptId'];

    _fetchExamData().then((_) => _populateAnswers(lastAttemptId));
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
        gradeControllers[i] = TextEditingController();
        feedbackControllers[i] = TextEditingController();
      }

      setState(() {
        questionsData = fetchedQuestions;
        questionIds = questionsSnapshot.docs.map((doc) => doc.id).toList();
      });
    } catch (e) {
      print('Error fetching exam $e');
    }
  }

  Future<void> _populateAnswers(String attemptId) async {
    try {
      for (int i = 0; i < questionsData.length; i++) {
        final questionId = questionIds[i];
        final answerSnapshot = await FirebaseFirestore.instance
            .collection('Answers')
            .where('StudentID', isEqualTo: studentId)
            .where('AttemptID', isEqualTo: attemptId)
            .where('QuestionID', isEqualTo: questionId)
            .where('ExamID', isEqualTo: examId)
            .get();

        if (answerSnapshot.docs.isNotEmpty) {
          final studentAnswer = answerSnapshot.docs.first['StudentAnswer'] ?? 'No Answer';
          answers[i] = studentAnswer != 'No Answer' ? studentAnswer : null;

          int? existingGrade = answerSnapshot.docs.first['StudentGrade'];
          studentGrades[i] = existingGrade;

          if (questionsData[i]['QuestionType'] == 'Short Answer' || questionsData[i]['QuestionType'] == 'Essay') {
            textControllers[i]?.text = studentAnswer;
            gradeControllers[i]?.text = existingGrade?.toString() ?? '';
          }
        }

        final feedbackSnapshot = await FirebaseFirestore.instance
            .collection('FeedBacks')
            .where('StudentID', isEqualTo: studentId)
            .where('AttemptID', isEqualTo: attemptId)
            .where('QuestionID', isEqualTo: questionId)
            .where('ExamID', isEqualTo: examId)
            .get();

        if (feedbackSnapshot.docs.isNotEmpty) {
          final feedbackText = feedbackSnapshot.docs.first['FeedBackText'] ?? '';
          feedbackControllers[i]?.text = feedbackText;
          feedbackDocIds[i] = feedbackSnapshot.docs.first.id; 
        }
      }
      setState(() {}); 
    } catch (e) {
      print('Error loading answers or feedback: $e');
    }
  }

  Future<void> _updateStudentGrades() async {
    try {
      bool gradesUpdated = false;
      final currentUser = FirebaseAuth.instance.currentUser;

      for (int i = 0; i < questionsData.length; i++) {
        if (questionsData[i]['QuestionType'] == 'Short Answer' || questionsData[i]['QuestionType'] == 'Essay') {
          final answerSnapshot = await FirebaseFirestore.instance
              .collection('Answers')
              .where('StudentID', isEqualTo: studentId)
              .where('AttemptID', isEqualTo: lastAttemptId)
              .where('QuestionID', isEqualTo: questionIds[i])
              .where('ExamID', isEqualTo: examId)
              .get();

          if (answerSnapshot.docs.isNotEmpty) {
            int? grade = int.tryParse(gradeControllers[i]?.text ?? '');
            double maxGrade = questionsData[i]['QuestionGrade']?.toDouble() ?? 0.0;

            if (grade != null && grade >= 0 && grade <= maxGrade) {
              await FirebaseFirestore.instance.collection('Answers').doc(answerSnapshot.docs.first.id).update({
                'StudentGrade': grade,
              });

              if (feedbackDocIds[i] != null) {
                await FirebaseFirestore.instance.collection('FeedBacks').doc(feedbackDocIds[i]).update({
                  'FeedBackText': feedbackControllers[i]?.text ?? '',
                });
              } else {
                final newFeedback = await FirebaseFirestore.instance.collection('FeedBacks').add({
                  'ExamID': examId,
                  'FeedBackText': feedbackControllers[i]?.text ?? '',
                  'QuestionID': questionIds[i],
                  'StudentID': studentId,
                  'TeacherID': currentUser?.uid ?? '',
                  'AttemptID': lastAttemptId,
                });
                setState(() {
                  feedbackDocIds[i] = newFeedback.id; 
                });
              }

              gradesUpdated = true;
            } else {
              print('Invalid grade for question $i: $grade');
            }
          }
        }
      }

      if (gradesUpdated) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Grades and feedback updated successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2), 
          ),
        );

        Navigator.of(context).pushReplacementNamed('SubmittedExams');
      }
    } catch (e) {
      print('Error updating student grades or feedback: $e');
    }
  }

  void _showUpdateConfirmationDialog() {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.question,
      borderSide: const BorderSide(color: Colors.green, width: 2),
      width: 350,
      buttonsBorderRadius: const BorderRadius.all(Radius.circular(2)),
      headerAnimationLoop: false,
      animType: AnimType.bottomSlide,
      title: 'Confirm Update',
      desc: 'Are you sure you want to update the student grades and feedback?',
      btnCancelOnPress: () {},
      btnOkOnPress: _updateStudentGrades,
    ).show();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Submission'),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.of(context).pushNamedAndRemoveUntil("login", (route) => false);
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
                  const SizedBox(height: 20),
                  if (questionsData.isNotEmpty)
                    _buildQuestionCard(questionsData[currentQuestionIndex]),
                  const Spacer(),
                  if (currentQuestionIndex == questionsData.length - 1)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20.0),
                      child: ElevatedButton(
                        onPressed: _showUpdateConfirmationDialog,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.yellow,
                        ),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 24.0),
                          child: Text(
                            'Update',
                            style: TextStyle(
                              fontSize: 22,
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Sorts Mill Goudy',
                            ),
                          ),
                        ),
                      ),
                    ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (currentQuestionIndex > 0)
                        _buildNavigationButton('Back', _previousQuestion),
                      if (currentQuestionIndex < questionsData.length - 1)
                        _buildNavigationButton('Next', _nextQuestion),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildQuestionCard(Map<String, dynamic> question) {
    String questionText = question['QuestionText'] ?? 'No Question Text';
    double questionGrade = question['QuestionGrade']?.toDouble() ?? 0.0;
    int? studentGrade = studentGrades[currentQuestionIndex];

    bool isRandomizationFalse = examData?['QuestionsRandomization'] == false;
    if (isRandomizationFalse && questionText.isNotEmpty) {
      questionText = questionText.substring(1);
    }

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
                    "${studentGrade ?? 0}/$questionGrade",
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
            _buildAnswerField(question, questionGrade),
          ],
        ),
      ),
    );
  }

  Widget _buildAnswerField(Map<String, dynamic> question, double maxGrade) {
    String questionType = question['QuestionType'];
    String correctAnswer = question['CorrectAnswer'] ?? '';
    String? studentAnswer = answers[currentQuestionIndex];

    switch (questionType) {
      case 'MCQ':
        return Column(
          children: (question['Options'] as String).split('/').map((option) {
            String trimmedOption = option.trim();
            bool isCorrect = trimmedOption == correctAnswer;
            bool isStudentAnswer = trimmedOption == studentAnswer;

            return ListTile(
              title: Text(
                trimmedOption,
                style: TextStyle(
                  fontWeight: isStudentAnswer ? FontWeight.bold : FontWeight.normal,
                  fontSize: 20,
                  fontFamily: 'Sorts Mill Goudy',
                  color: isStudentAnswer && !isCorrect ? Colors.red : (isCorrect ? Colors.green : Color.fromARGB(255, 42, 42, 60)),
                ),
              ),
              leading: Radio<String>(
                value: trimmedOption,
                groupValue: correctAnswer,
                onChanged: null,
              ),
            );
          }).toList(),
        );
      case 'True/False':
        return Column(
          children: ['True', 'False'].map((option) {
            bool isCorrect = option == correctAnswer;
            bool isStudentAnswer = option == studentAnswer;

            return ListTile(
              title: Text(
                option,
                style: TextStyle(
                  fontWeight: isStudentAnswer ? FontWeight.bold : FontWeight.normal,
                  fontSize: 20,
                  fontFamily: 'Sorts Mill Goudy',
                  color: isStudentAnswer && !isCorrect ? Colors.red : (isCorrect ? Colors.green : Color.fromARGB(255, 42, 42, 60)),
                ),
              ),
              leading: Radio<String>(
                value: option,
                groupValue: correctAnswer,
                onChanged: null,
              ),
            );
          }).toList(),
        );
      case 'Short Answer':
      case 'Essay':
        return Column(
          children: [
            TextFormField(
              controller: textControllers[questionsData.indexOf(question)],
              maxLines: questionType == 'Essay' ? null : 1,
              decoration: const InputDecoration(
                hintText: 'Your answer',
              ),
              enabled: false,
            ),
            TextFormField(
              controller: gradeControllers[questionsData.indexOf(question)],
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly, 
                CustomRangeInputFormatter(max: maxGrade),
              ],
              decoration: InputDecoration(
                labelText: 'Student Grade (0 to $maxGrade)',
                errorText: _validateGrade(gradeControllers[questionsData.indexOf(question)]!.text, maxGrade)
                    ? null
                    : 'Enter a valid grade',
              ),
            ),
            TextFormField(
              controller: feedbackControllers[questionsData.indexOf(question)],
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Feedback',
              ),
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  bool _validateGrade(String gradeText, double maxGrade) {
    final grade = int.tryParse(gradeText);
    return grade != null && grade >= 0 && grade <= maxGrade;
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

  @override
  void dispose() {
    textControllers.forEach((key, controller) => controller.dispose());
    gradeControllers.forEach((key, controller) => controller.dispose());
    feedbackControllers.forEach((key, controller) => controller.dispose());
    super.dispose();
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

class CustomRangeInputFormatter extends TextInputFormatter {
  final double max;

  CustomRangeInputFormatter({required this.max});

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    final int? newInt = int.tryParse(newValue.text);
    if (newInt == null || newInt < 0 || newInt > max) {
      return oldValue;
    }

    return newValue;
  }
}