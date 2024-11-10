import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:zen_assist/screens/homepage.dart';
import 'package:zen_assist/screens/todo.dart';
import 'package:zen_assist/screens/adminhomepage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Initialize Firebase here
  runApp(ZenAssistApp()); // Start with ZenAssistApp as the root widget
}

class ZenAssistApp extends StatelessWidget {
  const ZenAssistApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ZenAssist',
      theme: ThemeData(
        primaryColor: const Color(0xFF6B9080),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6B9080),
          secondary: const Color(0xFFA4C3B2),
        ),
        fontFamily: 'Roboto',
      ),
      home:
          Homepage(), // Starting screen can be the homepage or any desired screen
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
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

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
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
