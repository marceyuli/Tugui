import 'package:dialog_flowtter/dialog_flowtter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' as foundation;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:mailer/smtp_server/gmail.dart';
import 'dart:async';
import 'package:proximity_sensor/proximity_sensor.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:mailer/mailer.dart' as mailLibrary;

import '../api/google_auth_api.dart';

class DemoApp extends StatefulWidget {
  const DemoApp({super.key});

  @override
  State<DemoApp> createState() => _DemoAppState();
}

class _DemoAppState extends State<DemoApp> {
  late DialogFlowtter dialogFlowtter;
  final TextEditingController textEditingController = TextEditingController();
  //Ubicacion actual
  String? _currentAddress;
  Position? _currentPosition;

  bool _isNear = false;
  late StreamSubscription<dynamic> _streamSubscription;
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  String _lastWords = '';
  final FlutterTts flutterTts = FlutterTts();
  String apiKey = "AIzaSyDF2wZV31k2clz5HlF8kJf7OHoiZJHWj_w";
  String radius = "30";

  @override
  void initState() {
    super.initState();
    DialogFlowtter.fromFile().then((instance) => dialogFlowtter = instance);
    listenSensor();
    _initSpeech();
  }

  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize();
    setState(() {});
  }

  void _startListening() async {
    await _speechToText.listen(onResult: _onSpeechResult);
    setState(() {});
  }

  void _stopListening() async {
    await _speechToText.stop();
    setState(() {});
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      _lastWords = result.recognizedWords;
      sendMessage(_lastWords);
    });
  }

  @override
  void dispose() {
    super.dispose();
    _streamSubscription.cancel();
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

  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Location services are disabled. Please enable the services')));
      return false;
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are denied')));
        return false;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Location permissions are permanently denied, we cannot request permissions.')));
      return false;
    }
    return true;
  }

  Future<void> _getCurrentPosition() async {
    final hasPermission = await _handleLocationPermission();

    if (!hasPermission) return;
    await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high)
        .then((Position position) {
      setState(() => _currentPosition = position);
    }).catchError((e) {
      debugPrint(e);
    });
  }

  Future<List<String>> getNearbyPlaces() async {
    _getCurrentPosition();
    double? latitude = _currentPosition?.latitude;
    double? longitude = _currentPosition?.longitude;
    var url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=$latitude,$longitude&radius=$radius&key=$apiKey');
    var response = await http.get(url);
    if (response.statusCode == 200) {
      List<String> places = [];
      var data = json.decode(response.body);
      var results = data['results'];
      for (var result in results) {
        places.add(result['name']);
      }
      return places;
    } else {
      throw Exception("Error");
    }
  }

  Future<void> _getAddressFromLatLng(Position position) async {
    await placemarkFromCoordinates(
            _currentPosition!.latitude, _currentPosition!.longitude)
        .then((List<Placemark> placemarks) {
      Placemark place = placemarks[0];
      setState(() {
        _currentAddress =
            '${place.street}, ${place.subLocality}, ${place.subAdministrativeArea}, ${place.postalCode}';
        speak(_currentAddress!);
      });
    }).catchError((e) {
      debugPrint(e);
    });
  }

  Future sendEmail() async {
    final user = await GoogleAuthApi.signIn();
    print(user);
    if (user == null) {
      speak('Por favor loggeate');
      GoogleAuthApi.signOut();
      GoogleAuthApi.signIn();
    } else {
      final email = user.email;
      final auth = await user.authentication;
      final token = auth.accessToken!;

      print('authenticated: $email');
      speak("La ayuda va en camino");

      final smtpServer = gmailSaslXoauth2(email, token);
      final message = mailLibrary.Message()
        ..from = mailLibrary.Address(email, 'Tugui')
        ..recipients = ['mauriciosauzatorrez666@gmail.com']
        ..subject = 'Tugui user needs your help'
        ..text = 'This is a test email!';

      try {
        await mailLibrary.send(message, smtpServer);
      } on mailLibrary.MailerException catch (e) {
        print(e);
      }
    }
  }

  void sendMessage(String text) async {
    if (text.isEmpty) return;

    DetectIntentResponse response = await dialogFlowtter.detectIntent(
      queryInput: QueryInput(text: TextInput(text: text)),
    );

    if (response.message == null) return;
    final action = response.queryResult?.action;

    switch (action) {
      case 'donde.estoy':
        _getCurrentPosition();
        _getAddressFromLatLng(_currentPosition!);

        print('Accion match');
        break;
      case 'quehay.alrededor':
        getNearbyPlaces();
        speakNearbyPlaces();
        break;
      case 'necesito.ayuda':
        sendEmail();

        print('Action matched');
        break;
      default:
        //handle unknown actions
        break;
    }
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
            ],
          ),
        ));
  }

  Future<void> speakNearbyPlaces() async {
    List<String> places = await getNearbyPlaces();
    String placesString = "";
    if (places != null) {
      for (int i = 0; i < places.length; i++) {
        placesString = placesString + '${places[i].toString()}' + ' , ';
      }
    }
    print(placesString);
    speak(placesString);
  }
}
