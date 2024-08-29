//Package imports
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:flutter/gestures.dart';

class Login extends StatelessWidget {
  Login({super.key});
  static const String route = '/login';

  String email = "";
  String password = "";
  FirebaseAuth auth = FirebaseAuth.instance;

  showAlertDialog(BuildContext context, String statement, User? user) {
    // set up the button
    Widget okButton = TextButton(
      child: Text("OK"),
      onPressed: () {
        Navigator.pop(context);
      },
    );

    Widget verifyButton = TextButton(
      child: Text("Send Verify Email"),
      onPressed: () {
        //Send a verification to users email
        sendEmailVerif(user);

        //Pop context on screen
        Navigator.pop(context);

        //Show that an email sent to user
        showAlertDialog(context,
            "Sent verification to corresponding email. Check spam.", user);
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text("Alert"),
      content: Text(statement),
      actions: [
        okButton,
      ],
    );

    if (statement == "You have not verified your email") {
      // set up the AlertDialog
      alert = AlertDialog(
        title: Text("Alert"),
        content: Text(statement),
        actions: [
          okButton,
          verifyButton,
        ],
      );
    }

    //show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  void signoutUser() async {
    await FirebaseAuth.instance.signOut();
  }

  Future<void> sendResetPasswordEmail(
      String email, BuildContext context) async {
    if (email != "") {
      try {
        await auth.sendPasswordResetEmail(email: email);

        showAlertDialog(
            context,
            "If that email address is in our database, we will send you an email to reset your password.",
            null);
      } on FirebaseAuthException catch (error) {
        String errorMessage = "";
        switch (error.code) {
          case "auth/invalid-email":
            errorMessage =
                "If that email address is in our database, we will send you an email to reset your password.";
            break;
          case "auth/user-not-found":
            errorMessage =
                "If that email address is in our database, we will send you an email to reset your password.";
            break;
          default:
            errorMessage =
                "If that email address is in our database, we will send you an email to reset your password.";
            break;
        }
        //Display pop-up with corresponding error
        showAlertDialog(context, errorMessage, null);
      }
    } else {
      //Email box left empty
      showAlertDialog(
          context,
          "If that email address is in our database, we will send you an email to reset your password.",
          null);
    }
  }

  void login(String email, String password, BuildContext context) async {
    if (email != "" && password != "") {
      try {
        final credential = await FirebaseAuth.instance
            .signInWithEmailAndPassword(email: email, password: password);

        User? user = credential.user;

        if (user != null) {
          if (user.emailVerified) {
            IdTokenResult? userToken = await user?.getIdTokenResult();

            Map<String, dynamic>? claims = userToken?.claims;

            if (claims != null) {
              if (!claims['admin'] && !claims['manager']) {
                showAlertDialog(
                    context,
                    "You don't have the authority to login on this platform",
                    user);

                //Technically the user is signed in but we dont want this
                signoutUser();
              } else {
                Navigator.pushNamedAndRemoveUntil(
                    context, '/home', (route) => false);
              }
            } 
            else {
              showAlertDialog(
                  context,
                  "You don't have the authority to login on this platform",
                  user);

              signoutUser();
            }
          } 
          else {
            showAlertDialog(context, "You have not verified your email", user);
          }
        }
      } on FirebaseAuthException catch (error) {
        String errorMessage = "";
        switch (error.code) {
          case 'user-not-found':
            errorMessage =
               "Invalid Username or Password! Please check them and try again.";
            break;
          case 'wrong-password':
            errorMessage =
               "Invalid Username or Password! Please check them and try again.";
            break;
          case 'invalid-email':
            errorMessage =
               "Invalid Username or Password! Please check them and try again.";
            break;
          case 'user-disabled':
            errorMessage =
               "Invalid Username or Password! Please check them and try again.";
            break;
          default:
            errorMessage = "Something went wrong. Please try again.";
            break;
        }

        //Display pop-up with corresponding error message
        showAlertDialog(context, errorMessage, null);
      }
    } else {
      showAlertDialog(context, "One of the mandatory fields is empty.", null);
    }
  }

  Future<void> sendEmailVerif(User? user) async {
    if (user != null) {
      if (!user.emailVerified) {
        await user.sendEmailVerification();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          splashRadius: 20.0,
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),

      ),
      body: LayoutBuilder(builder: (context, windowSize) {
        return Align(
          alignment: Alignment.topCenter,
          child: Container(
            constraints: BoxConstraints(maxWidth: 600),
            padding: EdgeInsets.all(16.0),
            child: Form(
              child: ListView(children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    obscureText: false,
                    decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Email'),
                    onChanged: (text) {
                      email = text;
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    obscureText: true,
                    decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Password'),
                    onChanged: (text) {
                      password = text;
                    },
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(8.0),
                  alignment: Alignment.center,
                  child: ElevatedButton(
                    child: const Text("Login"),
                    style: ButtonStyle(
                      padding: MaterialStateProperty.all(
                        EdgeInsets.symmetric(vertical: 15.0, horizontal: 48.0),
                      ),
                        shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                            RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18.0),
                                ))),
                    onPressed: () {
                      login(email, password, context);
                    },
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Center(
                    child: Focus(
                      child: InkWell(
                        onTap: () {
                          sendResetPasswordEmail(email, context);
                        },
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(color: Theme.of(context).primaryColor),
                            text: "Forgot Password",
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        );
      }),
    );
  }
}
