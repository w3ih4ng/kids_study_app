import 'package:flutter/material.dart';

class AdminQuizzesScreen extends StatelessWidget {
  const AdminQuizzesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Quizzes')),
      body: const Center(child: Text('Manage Quizzes — Student 2 builds this')),
    );
  }
}