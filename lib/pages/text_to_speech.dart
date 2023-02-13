import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TextToSpeech extends StatelessWidget {
  final FlutterTts flutterTts = FlutterTts();
  final TextEditingController textEditingController = TextEditingController();

  speak(String text) async {
    await flutterTts.setLanguage("es-US");
    await flutterTts.setPitch(1);
    await flutterTts.speak(text);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
          TextFormField(
            controller: textEditingController,
          ),
          ElevatedButton(
              child: Text("Start text to speech"),
              onPressed: () => speak(textEditingController.text))
        ]),
      ),
    );
  }
}
