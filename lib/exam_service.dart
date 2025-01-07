import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ExamService with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Timer? _timer;
  Set<String> processedExamIds = {};

  void startCheckingExams() {
    stopCheckingExams();
    _timer = Timer.periodic(Duration(seconds: 2), (timer) async {
      await checkAndUpdateExams();
    });
  }

  Future<void> checkAndUpdateExams() async {
    final now = Timestamp.now();
    final examsSnapshot = await _firestore.collection('Exams').get();

    bool statusChanged = false;

    for (var examDoc in examsSnapshot.docs) {
      final endTime = examDoc['EndTime'] as Timestamp;
      final examId = examDoc.id;

      if (now.millisecondsSinceEpoch < endTime.millisecondsSinceEpoch) continue;

      final currentStatus = examDoc['Status'] as String;

      if (processedExamIds.contains(examId) || currentStatus == 'Completed') continue;

      final teacherId = examDoc['TeacherID'] as String;
      final examTitle = examDoc['ExamTitle'] as String;

      await examDoc.reference.update({'Status': 'Completed'});
      processedExamIds.add(examId); 
      statusChanged = true;

      final attemptsSnapshot = await _firestore
          .collection('Attempts')
          .where('ExamID', isEqualTo: examId)
          .where('Status', isEqualTo: 'Started')
          .get();

      for (var attemptDoc in attemptsSnapshot.docs) {
        await attemptDoc.reference.update({'Status': 'Completed'});
      }

      await _firestore.collection('Notifications').add({
        'Action': 'Start Grading',
        'Content': 'This is to notify you that your exam with the title $examTitle has been completed.',
        'ExamID': examId,
        'ExamTitle': examTitle,
        'UserID': teacherId,
      });

      if (currentStatus == 'Graded') {
        final attemptsForGradedExam = await _firestore
            .collection('Attempts')
            .where('ExamID', isEqualTo: examId)
            .get();

        Set<String> uniqueStudentIds = {};
        for (var doc in attemptsForGradedExam.docs) {
          uniqueStudentIds.add(doc['StudentID'] as String); 
        }

        for (var studentId in uniqueStudentIds) {
          await _firestore.collection('Notifications').add({
            'Action': 'Completed Exams',
            'Content': 'This is to notify you that your exam with the title $examTitle has been Graded.',
            'ExamID': examId,
            'ExamTitle': examTitle,
            'UserID': studentId,
          });
        }
      }
    }

    if (statusChanged) {
      processedExamIds.clear();
    }

    notifyListeners(); 
  }

  void stopCheckingExams() {
    _timer?.cancel();
    _timer = null; 
  }
}