//p
import 'package:bubbles_app/models/app_user.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';

//services
import '../services/database_service.dart';
import '../services/navigation_server.dart';

class AuthenticationProvider extends ChangeNotifier {
  late final FirebaseAuth _auth;
  late final NavigationService _navigationService;
  late final DatabaseService _databaseService;

  late AppUser user;

  AuthenticationProvider() {
    _auth = FirebaseAuth.instance;
    _navigationService = GetIt.instance.get<NavigationService>();
    _databaseService = GetIt.instance.get<DatabaseService>();

    _auth.authStateChanges().listen((_user) {
      if (_user != null) {
        _databaseService.updateUserLastSeenTime(_user.uid);
        _databaseService.getUser(_user.uid).then(
          (_snapshot) {
            Map<String, dynamic> _userData =
                _snapshot.data()! as Map<String, dynamic>;

            user = AppUser.fromJSON(
              {
                "uid": _user.uid,
                "username": _userData["username"],
                "email": _userData["email"],
                "last_active": _userData["last_active"],
                "image": _userData["image"],
              },
            );
            print(user.toMap());
          },
        );
      } else {
        print("not Logged");
      }
    });
  }

  Future<void> loginUsingEmailAndPassword(
      String _email, String _password) async {
    try {
      await _auth.signInWithEmailAndPassword(
          email: _email, password: _password);
    } on FirebaseAuthException {
      print("Error logging user into Firebase");
    } catch (e) {
      print(e);
    }
  }
}
