import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:lojistik/firebase_options.dart';
import 'package:lojistik/staff_Menu.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized(); // Flutter widget'larının başlatıldığından emin olun
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // Platforma özel Firebase ayarları
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Lojistik Deneme',
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: StaffMenu(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
          ],
        ),
      ),
    );
  }
}
