import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  TextEditingController email = TextEditingController();
  TextEditingController password = TextEditingController();
  bool securetext = true;

  GlobalKey<FormState> formState = GlobalKey<FormState>();
  String home = "";

  Future<void> checkUserRole(String uid) async {
    final teacherCollection = FirebaseFirestore.instance.collection('Teachers');
    final studentCollection = FirebaseFirestore.instance.collection('Students');

    final teacherDoc = await teacherCollection.doc(uid).get();
    if (teacherDoc.exists) {
      setState(() {
        home = "teacherhomepage";
      });
      return;
    }

    final studentDoc = await studentCollection.doc(uid).get();
    if (studentDoc.exists) {
      setState(() {
        home = "studenthomepage";
      });
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, const Color.fromARGB(255, 228, 230, 252)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: ListView(children: [
          Form(
            key: formState,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 50),
                Center(
                  child: Container(
                    alignment: Alignment.center,
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(70)
                    ),
                    child: Image.asset(
                      "assets/Logo.png",
                      height: 110,
                      fit: BoxFit.fill,
                    ),
                  ),
                ),
                Container(height: 20),
                const Text(
                  "Login",
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 8, 41, 114)
                  ),
                ),
                Container(height: 10),
                const Text(
                  "Login To Continue Using The App",
                  style: TextStyle(color: Colors.grey)
                ),
                Container(height: 20),
                const Text(
                  "Email",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Color.fromARGB(255, 8, 41, 114)
                  ),
                ),
                Container(height: 10),
                TextFormField(
                  validator: (val) {
                    if (val == null ||
                      !RegExp(
                        r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+"
                      ).hasMatch(val)) {
                      return "Please Enter A Valid Email";
                    }
                    return null;
                  },
                  controller: email,
                  decoration: InputDecoration(
                    hintText: "Enter Your Email",
                    hintStyle: TextStyle(fontSize: 14, color: Colors.grey),
                    contentPadding: EdgeInsets.symmetric(vertical: 2, horizontal: 20),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(50),
                      borderSide: BorderSide(color: const Color.fromARGB(255, 184, 184, 184))
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(50),
                      borderSide: BorderSide(color: Color.fromARGB(255, 8, 41, 114), width: 1)
                    ),
                  ),
                ),
                Container(height: 10),
                const Text(
                  "Password",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Color.fromARGB(255, 8, 41, 114)
                  ),
                ),
                Container(height: 10),
                TextFormField(
                  validator: (val) {
                    if (val == '') {
                      return "Please Enter Password";
                    }
                    return null;
                  },
                  controller: password,
                  obscureText: securetext,
                  decoration: InputDecoration(
                    hintText: "Enter Your Password",
                    hintStyle: TextStyle(fontSize: 14, color: Colors.grey),
                    contentPadding: EdgeInsets.symmetric(vertical: 2, horizontal: 20),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(50),
                      borderSide: BorderSide(color: const Color.fromARGB(255, 184, 184, 184))
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(50),
                      borderSide: BorderSide(color: Color.fromARGB(255, 8, 41, 114), width: 1)
                    ),
                    suffixIcon: IconButton(
                      padding: EdgeInsets.fromLTRB(0, 0, 10, 0),
                      onPressed: () {
                        setState(() {
                          securetext = !securetext;
                        });
                      },
                      icon: Icon(securetext ? Icons.visibility_off : Icons.visibility),
                    ),
                  ),
                ),
                InkWell(
                  onTap: () async {
                    if (email.text == '') {
                      AwesomeDialog(
                        context: context,
                        dialogType: DialogType.error,
                        animType: AnimType.rightSlide,
                        title: 'Error',
                        desc: 'Please Enter Your Email, Then Click on "Forgot Password?"',
                      ).show();
                    } else {
                      try {
                        await FirebaseAuth.instance
                          .sendPasswordResetEmail(email: email.text);

                        AwesomeDialog(
                          context: context,
                          dialogType: DialogType.success,
                          animType: AnimType.rightSlide,
                          title: 'Message',
                          desc: 'Password Reset Email Has Been Sent To Your Email',
                        ).show();
                      } catch (e) {
                        AwesomeDialog(
                          context: context,
                          dialogType: DialogType.error,
                          animType: AnimType.rightSlide,
                          title: 'Error',
                          desc: 'Please Enter A Valid Email',
                        ).show();
                      }
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 20),
                    alignment: Alignment.topRight,
                    child: const Text(
                      "Forgot Password ?",
                      style: TextStyle(
                        fontSize: 14,
                        color: Color.fromARGB(255, 8, 41, 114),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          MaterialButton(
            height: 40,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            color: Color.fromARGB(255, 8, 41, 114),
            textColor: Colors.white,
            onPressed: () async {
              if (formState.currentState!.validate()) {
                try {
                  final credential = await FirebaseAuth.instance
                      .signInWithEmailAndPassword(
                    email: email.text,
                    password: password.text,
                  );

                  await checkUserRole(credential.user!.uid);

                  Navigator.of(context).pushReplacementNamed(home);
                } on FirebaseAuthException catch (e) {
                  String errorMessage = 'Wrong Email or Password. Please Try Again.';

                  AwesomeDialog(
                    context: context,
                    dialogType: DialogType.error,
                    animType: AnimType.rightSlide,
                    title: 'Error',
                    desc: errorMessage,
                  ).show();
                  print(e.code);
                }
              } else {
                print('Form is not valid');
              }
            },
            child: Text(
              "Login",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
          ),
          Container(height: 20),
          Container(height: 20),
        ]),
      ),
    );
  }
}