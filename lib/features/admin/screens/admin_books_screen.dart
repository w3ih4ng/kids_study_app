import 'package:flutter/material.dart';

class AdminBooksScreen extends StatelessWidget {
  const AdminBooksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Books')),
      body: const Center(child: Text('Manage Books — Student 3 builds this')),
    );
  }
}