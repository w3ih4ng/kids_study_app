import 'package:flutter/material.dart';

class AdminLessonsScreen extends StatelessWidget {
  const AdminLessonsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Lessons')),
      body: const Center(child: Text('Manage Lessons — Student 2 builds this')),
    );
  }
}