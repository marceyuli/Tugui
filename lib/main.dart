import 'package:flutter/material.dart';
import 'package:tuguiapp/pages/pages.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IHC',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
<<<<<<< HEAD
      home: Scaffold(body: Center(child: TextToSpeech())),
      routes: {
        'speechToText': (BuildContext context) => const SpeechToText(),
        'textToSpeech': (BuildContext context) => TextToSpeech(),
        'hardwareButtons': (BuildContext context) => const HardwareButtons(),
        'proximitySensor': (BuildContext context) => const ProximitySensor()
=======
      home: const SpeechToTextTest(),
      routes: {
        'speechToText': (BuildContext context) => const SpeechToTextTest(),
        'textToSpeech': (BuildContext context) => const TextToSpeech(),
        'proximitySensor': (BuildContext context) => const ProximitySensorTest()
>>>>>>> cd213ab12d935740b46f66d612d4777669d9cf57
      },
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
        centerTitle: true,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Contador:',
            ),
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
