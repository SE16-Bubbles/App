//p

import 'package:bubbles_app/models/app_user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:get_it/get_it.dart';

//services
import '../models/activity.dart';
import '../services/database_service.dart';
import '../services/navigation_service.dart';

class AuthenticationProvider extends ChangeNotifier {
  late final FirebaseAuth _auth;
  late final NavigationService _navigationService;
  late final DatabaseService _databaseService;

  late AppUser appUser;

  AuthenticationProvider() {
    _auth = FirebaseAuth.instance;
    _navigationService = GetIt.instance.get<NavigationService>();
    _databaseService = GetIt.instance.get<DatabaseService>();

    _auth.authStateChanges().listen((user) {
      if (user != null) {
        _databaseService.updateUserLastSeenTime(user.uid);
        _databaseService.getUser(user.uid).then((snapshot) {
          Map<String, dynamic> userData =
              snapshot.data()! as Map<String, dynamic>;

          List<Activity> activityList = [];

          if (snapshot.exists) {
            // Get the reference to the activities collection
            CollectionReference activitiesRef =
                snapshot.reference.collection('activities');

            activitiesRef.get().then((querySnapshot) {
              querySnapshot.docs.forEach((activityDoc) {
                // Get the data from each activity document
                Map<String, dynamic> activityData =
                    activityDoc.data() as Map<String, dynamic>;

                // Create an Activity object using the retrieved data
                Activity activity = Activity(
                  activityData['description'],
                  activityData['date'].toDate(),
                );

                activityList.add(activity);
              });

              // Set the updated activityList in the AppUser object
              appUser = AppUser.fromJSON({
                "uid": user.uid,
                "username": userData["username"],
                "email": userData["email"],
                "last_active": userData["last_active"],
                "image": userData["image"],
                "activities": activityList,
                "up_votes": userData["up_votes"],
                "down_votes": userData["down_votes"],
                "number_of_votes": userData["number_of_votes"],
                "preferred_language": userData["preferred_language"],
              });

              _navigationService.removeAndNavigateToRoute('/home');
            });
          }
        });
      } else {
        _navigationService.removeAndNavigateToRoute('/login');
      }
    });
  }

  Future<String?> loginUsingEmailAndPassword(
      String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user!.uid;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
      } else if (e.code == 'wrong-password') {
      } else {}
    }
    return null;
  }

  Future<String?> registerUserUsingEmailAndPassword(
      String email, String password) async {
    try {
      UserCredential credentials = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credentials.user!.uid;
    } on FirebaseAuthException {
      if (kDebugMode) {
        print("Error: create user");
      }
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
    return null;
  }

  Future<void> logout() async {
    try {
      await _auth.signOut();
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
  }

  Future<UserCredential?> changeEmail(newEmail, currentPassword) async {
    try {
      UserCredential? authResult =
          await _auth.currentUser?.reauthenticateWithCredential(
        EmailAuthProvider.credential(
          email: _auth.currentUser!.email!,
          password: currentPassword,
        ),
      );

      return authResult;
      // ignore: empty_catches
    } catch (e) {}
    return null;
  }

  Future<UserCredential?> changePassword(newPassword, currrentPassword) async {
    try {
      UserCredential? authResult =
          await _auth.currentUser?.reauthenticateWithCredential(
        EmailAuthProvider.credential(
          email: _auth.currentUser!.email!,
          password: currrentPassword,
        ),
      );
      return authResult;
    } catch (e) {
      return null;
    }
  }
}
