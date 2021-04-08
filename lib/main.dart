
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:todo/Screens/loading_screen.dart';
import 'package:todo/providers/task_provider.dart';
import 'package:provider/provider.dart';





void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  AwesomeNotifications().initialize(
    // set the icon to null if you want to use the default app icon
      'resource://drawable/ic_launcher',
      [
        NotificationChannel(
          channelKey: 'basic_channel',
          channelName: 'Basic notifications',
          channelDescription: 'Notification channel for basic tests',
          defaultColor: Colors.pinkAccent,
          ledColor: Colors.white,
          groupKey: "todo",
          importance: NotificationImportance.High,
          enableVibration: true,
          defaultPrivacy: NotificationPrivacy.Public,
          playSound: true,
        )
      ]
  );
  runApp(MyApp());
}


class MyApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: TaskProvider(),
      child: Material(
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          home: LoadingScreen(),
        ),
      ),
    );
  }


}



