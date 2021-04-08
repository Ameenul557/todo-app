import 'package:flutter/material.dart';
import 'package:todo/Screens/home_screen.dart';
import 'package:todo/providers/task_provider.dart';
import 'package:provider/provider.dart';

class LoadingScreen extends StatefulWidget {
  @override
  _LoadingScreenState createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
        future: Provider.of<TaskProvider>(context,listen: false).fetchAndSetTask(),
        builder: (context,snap) => (snap.connectionState==ConnectionState.waiting)?Center(child: CircularProgressIndicator(),):HomeScreen(),
      ),
    );
  }
}
