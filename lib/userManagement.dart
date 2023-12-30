import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Manage extends StatefulWidget {
  const Manage( { super.key } );

  @override
  State<Manage> createState() => _ManageState();
}

class _ManageState extends State<Manage>{
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Users'),
      ),
      body: FutureBuilder(
        future: fetchFirebaseUsers(),
        builder: (context, snapshot) 
        {
          if(snapshot.connectionState == ConnectionState.waiting)
          {
            return CircularProgressIndicator();
          } 
          else if (snapshot.hasError) 
          {
            return Text('Error: ${snapshot.error}');
          }
          else 
          {
            List<User>? users = snapshot.data;
            if(users != null)
            {
              return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) 
                  {
                      return ListTile(
                          title: Text(users[index].email ?? "No Email"),
                          subtitle: SizedBox(
                            child: ElevatedButton(
                              onPressed: () 
                              {
                                Map<String, dynamic>? anonymousClaims = 
                                users[index]?.getIdTokenResult().data?.claims;
                                if(anonymousClaims != null)
                                { 
                                  String status = anonymousClaims['disabled'] 
                                                         ? "Enable" : "Disable";
                                  changeUserStatus(users[index],
                                                  !anonymousClaims['disabled']);
                                }
                              },
                              // status is out of scope currently 
                              // child: Text(status)
                              child: Text("Enable/Disable"),
                            ),
                          ),
                      );
                  },
              );
            }
            else
            {
              // Return that there is no users
                return SizedBox.shrink();
            }
          }
        },
      ),
    );
    }

    // Problem: Have to have elevated permissions to execute
    Future<List<User>> fetchFirebaseUsers() async 
    {
        List<User> users = [];
        try 
        {
            UserCredential userCredential = 
                               await FirebaseAuth.instance.signInAnonymously();
            User? currentUser = FirebaseAuth.instance.currentUser;
            User? signedInUser = userCredential.user;
            Map<String, dynamic>? anonymousClaims;

            if(signedInUser != null)
            {
                anonymousClaims = signedInUser.getIdTokenResult().data?.claims;
                if(anonymousClaims != null)
                {
                  if(anonymousClaims['manager'] || anonymousClaims['admin'])
                  {
                    users.add(signedInUser);
                  }
                }
            }
        } 
        catch(error)
        {
            print('Error fetching users: $error');
        }

        return users;
    }


    // DNW, Might have to implement a cloud function to set claims
    Future<void> changeUserStatus(User user, bool activeStatus) async
    {
      //await FirebaseAuth.instance.setCustomUserClaims(user.uid, 
      //                                            {'disabled': activeStatus});
      await user.updateCustomData({'disabled': activeStatus});
    }
}