import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ExamAnswers extends StatefulWidget {
  const ExamAnswers({super.key});

  @override
  _ExamAnswersState createState() => _ExamAnswersState();
}

class _ExamAnswersState extends State<ExamAnswers> {
  late final String examId;
  Map<String, dynamic>? examData;
  List<Map<String, dynamic>> questionsData = [];
  List<String> questionIds = [];
  int currentQuestionIndex = 0;
  Map<int, TextEditingController> textControllers = {};
  Map<int, String?> answers = {};
  Map<int, int?> studentGrades = {};
  Map<int, String?> feedbackTexts = {}; 
  String? currentAttemptId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)!.settings.arguments;
    if (args is String) {
      examId = args;
      _fetchExamData().then((_) => _fetchLastAttempt()); 
    } else {
      examId = 'Unknown';
    }
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
      }

      setState(() {
        questionsData = fetchedQuestions;
        questionIds = questionsSnapshot.docs.map((doc) => doc.id).toList();
      });
    } catch (e) {
      print('Error fetching exam $e');
    }
  }

  Future<void> _fetchLastAttempt() async {
    try {
      final currentUserId = FirebaseAuth.instance.currentUser!.uid;
      final attemptsSnapshot = await FirebaseFirestore.instance
          .collection('Attempts')
          .where('ExamID', isEqualTo: examId)
          .get(); 

      DocumentSnapshot? latestAttempt;
      int maxAttemptNumber = 0;

      for (var doc in attemptsSnapshot.docs) {
        if (doc['StudentID'] == currentUserId) {
          int attemptNumber = doc['AttemptNumber'] ?? 0;
          if (attemptNumber > maxAttemptNumber) {
            maxAttemptNumber = attemptNumber;
            latestAttempt = doc;
          }
        }
      }

      if (latestAttempt != null) {
        currentAttemptId = latestAttempt.id;
        await _populateAnswers(currentAttemptId!); 
      } else {
        print('No attempts found for this exam.');
      }
    } catch (e) {
      print('Error fetching last attempt: $e');
    }
  }

  Future<void> _populateAnswers(String attemptId) async {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    for (int i = 0; i < questionsData.length; i++) {
      final questionId = questionIds[i];
      final answerSnapshot = await FirebaseFirestore.instance
          .collection('Answers')
          .where('StudentID', isEqualTo: currentUserId)
          .where('AttemptID', isEqualTo: attemptId)
          .where('QuestionID', isEqualTo: questionId)
          .where('ExamID', isEqualTo: examId)
          .get();

      if (answerSnapshot.docs.isNotEmpty) {
        final studentAnswer = answerSnapshot.docs.first['StudentAnswer'] ?? 'No Answer';
        final studentGrade = answerSnapshot.docs.first['StudentGrade'];

        setState(() {
          answers[i] = studentAnswer != 'No Answer' ? studentAnswer : null;
          studentGrades[i] = studentGrade;
        });

        if (questionsData[i]['QuestionType'] == 'Short Answer' || questionsData[i]['QuestionType'] == 'Essay') {
          textControllers[i]?.text = studentAnswer;
        }

        final feedbackSnapshot = await FirebaseFirestore.instance
            .collection('FeedBacks')
            .where('StudentID', isEqualTo: currentUserId)
            .where('AttemptID', isEqualTo: attemptId)
            .where('QuestionID', isEqualTo: questionId)
            .where('ExamID', isEqualTo: examId)
            .get();

        if (feedbackSnapshot.docs.isNotEmpty) {
          final feedbackText = feedbackSnapshot.docs.first['FeedBackText'] ?? '';
          setState(() {
            feedbackTexts[i] = feedbackText;
          });
        }

        print('Loaded answer for question $questionId: $studentAnswer with grade: ${studentGrades[i]}');
      } else {
        print('No answer found for question ID: $questionId');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exam'),
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
            _buildAnswerField(question),
            if (feedbackTexts[currentQuestionIndex]?.isNotEmpty ?? false)
              Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: Text(
                  feedbackTexts[currentQuestionIndex]!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnswerField(Map<String, dynamic> question) {
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
          ],
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

  @override
  void dispose() {
    textControllers.forEach((key, controller) => controller.dispose());
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