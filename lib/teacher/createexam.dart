import 'dart:async';

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class CreateExam extends StatefulWidget {
  const CreateExam({super.key});

  @override
  _CreateExamState createState() => _CreateExamState();
}

class _CreateExamState extends State<CreateExam> {
  bool questionRandomization = false;
  DateTime? startTime;
  DateTime? endTime;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _attemptsController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  final TextEditingController _startTimeController = TextEditingController();
  final TextEditingController _endTimeController = TextEditingController();
  final TextEditingController _examTitleController = TextEditingController();
  final List<Question> questions = [Question()];
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _durationController.text = "Select start and end times";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Create Exam',
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Exam Details',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Patua One',
                  color: Color.fromARGB(255, 8, 41, 114),
                ),
              ),
              const SizedBox(height: 20),
              _buildTextField('Exam Title', 'Enter Exam Title',
                  TextInputType.text, Icons.title, _examTitleController),
              _buildReadOnlyNumericField(
                  'Duration', _durationController, Icons.timer),
              _buildDateTimeField('Start Time', true, Icons.calendar_today),
              _buildDateTimeField('End Time', false, Icons.calendar_today),
              _buildNumericField(
                  'Attempts', 'Attempts', _attemptsController, Icons.repeat),
              Row(
                children: [
                  Checkbox(
                    value: questionRandomization,
                    onChanged: (value) {
                      setState(() {
                        questionRandomization = value!;
                      });
                    },
                    activeColor: const Color.fromARGB(255, 8, 41, 114),
                  ),
                  const Text(
                    'Randomization',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Sorts Mill Goudy',
                      color: Color.fromARGB(255, 8, 41, 114),
                    ),
                  ),
                ],
              ),
              const Divider(color: Color.fromARGB(255, 8, 41, 114)),
              _buildQuestionsSection(),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: _showCreateDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    textStyle: const TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Sorts Mill Goudy',
                    ),
                  ),
                  child: const Text('Create',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
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
        currentIndex: 0,
        selectedItemColor: Colors.amber,
        unselectedItemColor: Colors.white,
        onTap: (index) {
          switch (index) {
            case 0:
              // Already on Create Exam
              break;
            case 1:
              Navigator.of(context)
                  .pushNamedAndRemoveUntil("submissions", (route) => false);
              break;
            case 2:
              Navigator.of(context)
                  .pushNamedAndRemoveUntil("notifications", (route) => false);
              break;
          }
        },
      ),
    );
  }

  Widget _buildTextField(String label, String hint, TextInputType type,
      IconData icon, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        keyboardType: type,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'This field is required';
          }
          return null;
        },
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: const Color.fromARGB(255, 8, 41, 114)),
          labelText: label,
          hintText: hint,
          labelStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Sorts Mill Goudy',
            color: Color.fromARGB(255, 8, 41, 114),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: Color.fromARGB(255, 8, 41, 114)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: Color.fromARGB(255, 8, 41, 114)),
          ),
        ),
      ),
    );
  }

  Widget _buildReadOnlyNumericField(
      String label, TextEditingController controller, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        readOnly: true,
        validator: (value) {
          if (value == null || value.isEmpty || value == '0 minutes') {
            return 'Duration must be calculated and greater than 0';
          }
          return null;
        },
        style: const TextStyle(color: Colors.red, fontSize: 14),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: const Color.fromARGB(255, 8, 41, 114)),
          labelText: label,
          labelStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Sorts Mill Goudy',
            color: Color.fromARGB(255, 8, 41, 114),
          ),
          hintText: 'Select start and end times',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: Color.fromARGB(255, 8, 41, 114)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: Color.fromARGB(255, 8, 41, 114)),
          ),
        ),
      ),
    );
  }

  Widget _buildNumericField(String label, String hint,
      TextEditingController controller, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        validator: (value) {
          if (value == null || value.isEmpty || int.tryParse(value) == null) {
            return 'Enter a valid number';
          }
          return null;
        },
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: const Color.fromARGB(255, 8, 41, 114)),
          labelText: label,
          hintText: hint,
          labelStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Sorts Mill Goudy',
            color: Color.fromARGB(255, 8, 41, 114),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: Color.fromARGB(255, 8, 41, 114)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: Color.fromARGB(255, 8, 41, 114)),
          ),
        ),
      ),
    );
  }

  Widget _buildDateTimeField(String label, bool isStart, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: isStart ? _startTimeController : _endTimeController,
        readOnly: true,
        validator: (value) {
          if (isStart && startTime == null) {
            return 'Start time is required';
          }
          if (!isStart && endTime == null) {
            return 'End time is required';
          }
          return null;
        },
        onTap: () async {
          DateTime? pickedDate = await showDatePicker(
            context: context,
            initialDate: isStart ? DateTime.now() : startTime ?? DateTime.now(),
            firstDate: isStart ? DateTime.now() : startTime ?? DateTime.now(),
            lastDate: DateTime(2101),
          );
          if (pickedDate != null) {
            TimeOfDay? pickedTime = await showTimePicker(
              context: context,
              initialTime: TimeOfDay.now(),
            );
            if (pickedTime != null) {
              setState(() {
                DateTime fullDateTime = DateTime(
                  pickedDate.year,
                  pickedDate.month,
                  pickedDate.day,
                  pickedTime.hour,
                  pickedTime.minute,
                );
                if (isStart) {
                  startTime = fullDateTime;
                  _startTimeController.text =
                      DateFormat('yyyy-MM-dd – kk:mm').format(startTime!);
                } else {
                  if (fullDateTime.isAfter(startTime!)) {
                    endTime = fullDateTime;
                    _endTimeController.text =
                        DateFormat('yyyy-MM-dd – kk:mm').format(endTime!);
                    _updateDuration();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('End time must be after start time'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              });
            }
          }
        },
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: const Color.fromARGB(255, 8, 41, 114)),
          labelText: label,
          hintText: isStart
              ? (startTime == null
                  ? 'Choose start date and time'
                  : DateFormat('yyyy-MM-dd – kk:mm').format(startTime!))
              : (endTime == null
                  ? 'Choose end date and time'
                  : DateFormat('yyyy-MM-dd – kk:mm').format(endTime!)),
          labelStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Sorts Mill Goudy',
            color: Color.fromARGB(255, 8, 41, 114),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: Color.fromARGB(255, 8, 41, 114)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: Color.fromARGB(255, 8, 41, 114)),
          ),
        ),
      ),
    );
  }

  void _updateDuration() {
    if (startTime != null && endTime != null) {
      int durationMinutes = endTime!.difference(startTime!).inMinutes;
      if (durationMinutes <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('End time must be after start time'),
            backgroundColor: Colors.red,
          ),
        );
        _durationController.text = 'Select start and end times';
      } else {
        _durationController.text = '$durationMinutes minutes';
      }
    }
  }

  Widget _buildQuestionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Questions',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            fontFamily: 'Patua One',
            color: Color.fromARGB(255, 8, 41, 114),
          ),
        ),
        const SizedBox(height: 10),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 600),
          child: Column(
            key: ValueKey<int>(questions.length),
            children: questions.asMap().entries.map((entry) {
              int index = entry.key;
              Question question = entry.value;
              return _buildQuestionCard(question, index + 1);
            }).toList(),
          ),
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: () {
            setState(() {
              questions.add(Question());
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 8, 41, 114),
            textStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontFamily: 'Sorts Mill Goudy',
            ),
          ),
          child: const Text('Add Question',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildQuestionCard(Question question, int number) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color.fromARGB(255, 8, 41, 114)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Question $number',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Sorts Mill Goudy',
                  color: Color.fromARGB(255, 8, 41, 114),
                ),
              ),
              SizedBox(
                width: 200,
                child: _buildNumericField('Grade', 'Enter Grade',
                    question.gradeController, Icons.grade),
              ),
            ],
          ),
          _buildTextField('Question Text', 'Enter Question Text',
              TextInputType.text, Icons.text_fields, question.textController),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: DropdownButtonFormField<String>(
              value: question.type,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.list,
                    color: Color.fromARGB(255, 8, 41, 114)),
                labelText: 'Question Type',
                labelStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Sorts Mill Goudy',
                  color: Color.fromARGB(255, 8, 41, 114),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: Color.fromARGB(255, 8, 41, 114)),
                ),
              ),
              items: <String>['MCQ', 'Short Answer', 'Essay', 'True/False']
                  .map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  question.type = value!;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select a question type';
                }
                return null;
              },
            ),
          ),
          if (question.type == 'MCQ' || question.type == 'True/False')
            _buildOptions(question),
          
          _buildFileImageButtons(question),
          if (question.uploadedFileName != null)
            Text('File: ${question.uploadedFileName}',
                style: const TextStyle(color: Colors.green)),
          if (question.uploadedImageName != null)
            Text('Image: ${question.uploadedImageName}',
                style: const TextStyle(color: Colors.green)),
        ],
      ),
    );
  }

  Widget _buildFileImageButtons(Question question) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ElevatedButton(
            onPressed: () => _pickFileForQuestion(question),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              side: const BorderSide(color: Color.fromARGB(255, 8, 41, 114)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'File Attachment',
              style: TextStyle(
                color: Color.fromARGB(255, 8, 41, 114),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => _pickImageForQuestion(question),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              side: const BorderSide(color: Color.fromARGB(255, 8, 41, 114)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Image',
              style: TextStyle(
                color: Color.fromARGB(255, 8, 41, 114),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickFileForQuestion(Question question) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();
      if (result != null) {
        PlatformFile file = result.files.first;
        setState(() {
          question.uploadedFileName = file.name; 
        });
        print('File picked for question: ${file.name}');
      }
    } catch (e) {
      print('Error picking file: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick file: $e')),
      );
    }
  }

  Future<void> _pickImageForQuestion(Question question) async {
    try {
      final XFile? image =
          await _imagePicker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          question.uploadedImageName = image.name; 
        });
        print('Image picked for question: ${image.name}');
      }
    } catch (e) {
      print('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e')),
      );
    }
  }

  Widget _buildOptions(Question question) {
    if (question.type == 'True/False') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Please Select the Correct Answer',
            style: TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
          ...['True', 'False'].map((option) {
            return Row(
              children: [
                Checkbox(
                  value: question.trueFalseAnswer == option,
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        question.trueFalseAnswer = option;
                      }
                    });
                  },
                ),
                Text(option),
              ],
            );
          }),
          if (question.trueFalseAnswer == null)
            const Text(
              'You must select a correct answer',
              style: TextStyle(color: Colors.red),
            ),
        ],
      );
    } else if (question.type == 'MCQ') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Please Select The Correct Answer',
            style: TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
          ...question.options.asMap().entries.map((entry) {
            int index = entry.key;
            Option option = entry.value;
            return Row(
              children: [
                Checkbox(
                  value: option.isCorrect,
                  onChanged: (value) {
                    setState(() {
                      for (var opt in question.options) {
                        opt.isCorrect = false;
                      }
                      option.isCorrect = value!;
                    });
                  },
                ),
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(hintText: 'Option Text'),
                    controller: option.controller,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Option text is required';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            );
          }),
          if (!question.options.any((opt) => opt.isCorrect))
            const Text(
              'You must select a correct answer',
              style: TextStyle(color: Colors.red),
            ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                question.options.add(Option());
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 8, 41, 114),
            ),
            child: const Text(
              '+',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      );
    } else {
      return Container();
    }
  }

  void _showCreateDialog() {
    if (_formKey.currentState!.validate() && _validateQuestions()) {
      AwesomeDialog(
        context: context,
        dialogType: DialogType.info,
        animType: AnimType.bottomSlide,
        title: 'Confirm Creation',
        desc: 'Are you sure you want to create the exam?',
        btnCancelOnPress: () {},
        btnOkOnPress: () async {
          await _addExamToFirestore();
          _resetForm();
          AwesomeDialog(
            context: context,
            dialogType: DialogType.success,
            animType: AnimType.bottomSlide,
            title: 'Success!',
            desc: 'The exam has been created successfully.',
            btnOkOnPress: () {},
          ).show();
        },
      ).show();
    } else {
      AwesomeDialog(
        context: context,
        dialogType: DialogType.error,
        animType: AnimType.bottomSlide,
        title: 'Incomplete Form',
        desc: 'Please fill in all required fields before creating the exam.',
        btnOkOnPress: () {},
      ).show();
    }
  }

  Future<void> _addExamToFirestore() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return; 

    DocumentReference examDocRef =
        await FirebaseFirestore.instance.collection('Exams').add({
      'Duration': int.tryParse(_durationController.text.split(' ')[0]) ?? 0,
      'EndTime': endTime,
      'ExamTitle': _examTitleController.text,
      'NumberOfAttempts': int.tryParse(_attemptsController.text) ?? 0,
      'QuestionsRandomization': questionRandomization,
      'StartTime': startTime,
      'Status': 'Available',
      'TeacherID': currentUser.uid,
    });

    for (var question in questions) {
      String options = '';
      if (question.type == 'MCQ') {
        options =
            question.options.map((opt) => opt.controller.text).join('/');
      } else if (question.type == 'True/False') {
        options = 'True/False';
      }

      await FirebaseFirestore.instance.collection('Questions').add({
        'AttachedFile': question.uploadedFileName ?? '',
        'CorrectAnswer': question.trueFalseAnswer ??
            (question.options
                    .firstWhere((opt) => opt.isCorrect, orElse: () => Option())
                    .controller
                    .text ??
                ''),
        'ExamID': examDocRef.id,
        'Options': options,
        'QuestionGrade': int.tryParse(question.gradeController.text) ?? 0,
        'QuestionText': question.textController.text,
        'QuestionType': question.type ?? '',
        'UploadedImage': question.uploadedImageName ?? '',
      });
    }
  }

  bool _validateQuestions() {
    for (var question in questions) {
      if (question.type == 'MCQ') {
        for (var option in question.options) {
          if (option.controller.text.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content:
                      Text('All option texts for MCQ questions must be filled.')),
            );
            return false;
          }
        }
        if (!question.options.any((opt) => opt.isCorrect)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'All MCQ questions must have a correct answer selected.')),
          );
          return false;
        }
      }

      if (question.type == 'True/False' && question.trueFalseAnswer == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'All True/False questions must have a correct answer selected.')),
        );
        return false;
      }
    }
    return true;
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    setState(() {
      _durationController.text = "Select start and end times";
      _startTimeController.clear();
      _endTimeController.clear();
      _attemptsController.clear();
      _examTitleController.clear();
      questions.clear();
      questions.add(Question());
    });
  }
}

class Question {
  String? type;
  final TextEditingController textController = TextEditingController();
  final TextEditingController gradeController = TextEditingController();
  final List<Option> options = [Option(), Option()];
  String? trueFalseAnswer;
  String? uploadedFileName;
  String? uploadedImageName;
}

class Option {
  bool isCorrect = false;
  final TextEditingController controller = TextEditingController();
}