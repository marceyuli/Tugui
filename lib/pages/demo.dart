import 'package:dialog_flowtter/dialog_flowtter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' as foundation;
import 'dart:async';
import 'package:proximity_sensor/proximity_sensor.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';

class DemoApp extends StatefulWidget {
  const DemoApp({super.key});

  @override
  State<DemoApp> createState() => _DemoAppState();
}

class _DemoAppState extends State<DemoApp> {
  late DialogFlowtter dialogFlowtter;
  final TextEditingController textEditingController = TextEditingController();
  //List<Map<String, dynamic>> messages = [];

  bool _isNear = false;
  late StreamSubscription<dynamic> _streamSubscription;
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  String _lastWords = '';
  final FlutterTts flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    DialogFlowtter.fromFile().then((instance) => dialogFlowtter = instance);
    listenSensor();
    _initSpeech();
  }

  /// This has to happen only once per app
  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize();
    setState(() {});
  }

  /// Each time to start a speech recognition session
  void _startListening() async {
    await _speechToText.listen(onResult: _onSpeechResult);
    setState(() {});
  }

  /// Manually stop the active speech recognition session
  /// Note that there are also timeouts that each platform enforces
  /// and the SpeechToText plugin supports setting timeouts on the
  /// listen method.
  void _stopListening() async {
    await _speechToText.stop();
    setState(() {});
  }

  /// This is the callback that the SpeechToText plugin calls when
  /// the platform returns recognized words.
  void _onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      _lastWords = result.recognizedWords;
    });
  }

  @override
  void dispose() {
    super.dispose();
    // _streamSubscription.cancel();
  }

  speak(String text) async {
    await flutterTts.setLanguage("es-US");
    await flutterTts.setPitch(1);
    await flutterTts.speak(text);
  }

  Future<void> listenSensor() async {
    FlutterError.onError = (FlutterErrorDetails details) {
      if (foundation.kDebugMode) {
        FlutterError.dumpErrorToConsole(details);
      }
    };
    _streamSubscription = ProximitySensor.events.listen((int event) {
      setState(() {
        _speechToText.isNotListening ? _startListening() : _stopListening();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Tugui the Guide Dog'),
          centerTitle: true,
          backgroundColor: const Color.fromRGBO(118, 84, 154, 100),
        ),
        body: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Image.asset('lib/assets/TUGUI logo.png'),
              Text('Proximity sensor, is near ? $_isNear\n'),
              Text(
                _speechToText.isListening
                    ? _lastWords
                    : _speechEnabled
                        ? 'Use de proximity sensor to start listening...'
                        : 'Speech not available',
              ),
              Text(_lastWords),
              Icon(_speechToText.isNotListening ? Icons.mic_off : Icons.mic),
              ElevatedButton(
                  child: Text("Start text to speech"),
                  onPressed: () {
                    speak(_lastWords);
                    sendMessage(_lastWords);
                  }),
              //Text(messages[messages.length - 1]['message'].text.text[0])
            ],
          ),
        ));
  }

  void sendMessage(String text) async {
    if (text.isEmpty) return;
   /* setState(() {
      addMessage(
        Message(text: DialogText(text: [text])),
        true,
      );
    });*/

    DetectIntentResponse response = await dialogFlowtter.detectIntent(
      queryInput: QueryInput(text: TextInput(text: text)),
    );

    if (response.message == null) return;
    /*setState(() {
      addMessage(response.message!);
    });*/

    String? textResponse = response.text;

    print(textResponse); 
  }

  //de dialogflow
 /* addMessage(Message message, [bool isUserMessage = false]) {
    messages.add({'message': message, 'isUserMessage': isUserMessage});
  } */
}
