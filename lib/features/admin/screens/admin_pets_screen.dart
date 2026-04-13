import 'package:flutter/material.dart';

class AdminPetsScreen extends StatelessWidget {
  const AdminPetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Pets')),
      body: const Center(child: Text('Manage Pets — Student 3 builds this')),
    );
  }
}