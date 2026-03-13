import 'package:flutter/material.dart';

enum UserRole { admin, player }

class AppStore extends StatefulWidget {
  final Widget child;
  const AppStore({super.key, required this.child});

  @override
  State<AppStore> createState() => AppStoreState();

  static AppStoreState of(BuildContext context) =>
      context.findAncestorStateOfType<AppStoreState>()!;
}

class AppStoreState extends State<AppStore> {
  UserRole? selectedRole;
  bool isLoggedIn = false;
  String userName = '';

  void setRole(UserRole role) => setState(() => selectedRole = role);

  void login(String name) => setState(() {
    isLoggedIn = true;
    userName = name;
  });

  void logout() => setState(() {
    isLoggedIn = false;
    userName = '';
    selectedRole = null;
  });

  @override
  Widget build(BuildContext context) => widget.child;
}
