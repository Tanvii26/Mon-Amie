import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:mon_amie/ai_service.dart';
import 'package:mon_amie/feature_box.dart';
import 'package:mon_amie/pallete.dart';
import 'package:mon_amie/secrets.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:permission_handler/permission_handler.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final speechToText = SpeechToText();
  final flutterTts = FlutterTts();
  String? generatedContent;
  String lastWords = '';
  late final AiService aiService;

  @override
  void initState() {
    super.initState();
    initSpeechToText();
    initTextToSpeech();

    // Initialize the AiService with the GenerativeModel
    aiService = AiService(
      model: GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: APIKey, // Make sure secrets.dart contains your API key
      ),
    );
  }

  Future<void> initTextToSpeech() async {
    await flutterTts.setSharedInstance(true);
    setState(() {});
  }

  Future<void> initSpeechToText() async {
    if (await Permission.microphone.isDenied) {
      bool permissionGranted = await Permission.microphone.request().isGranted;

      if (!permissionGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
                'Microphone permission is required to use speech recognition.'),
            action: SnackBarAction(
              label: 'Settings',
              onPressed: () {
                openAppSettings(); // Open device settings if permission denied
              },
            ),
          ),
        );
        return;
      }
    }

    bool available = await speechToText.initialize(
      onStatus: (status) => print('Speech Status: $status'),
      onError: (error) => print('Speech Error: $error'),
    );

    if (!available) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Speech recognition is not available on this device.')),
      );
    }

    setState(() {}); // Refresh UI after initializing
  }

  String sanitizeResponse(String response) {
    // Replace some special characters with an empty string 
    String sanitizedResponse = response.replaceAll(RegExp(r'[*#!]'), '');

    return sanitizedResponse;
  }

  Future<void> startListening() async {
    if (speechToText.isNotListening) {
      await speechToText.listen(onResult: onSpeechResult);
      setState(() {});
    }
  }

  Future<void> stopListening() async {
    if (speechToText.isListening) {
      await speechToText.stop();
      setState(() {});
    }
  }

  void onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      lastWords = result.recognizedWords;
    });
  }

  Future<void> systemSpeak(String content) async {
    await flutterTts.speak(content);
  }

  @override
  void dispose() {
    speechToText.stop();
    flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon Amie'),
        leading: const Icon(Icons.menu),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Profile Section
              Stack(
                children: [
                  Center(
                    child: Container(
                      height: 120,
                      width: 120,
                      margin: const EdgeInsets.only(top: 8),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        image: DecorationImage(
                          image: AssetImage('assets/images/bg.jpg'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    height: 123,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      image: DecorationImage(
                        image: AssetImage('assets/images/bot.png'),
                      ),
                    ),
                  ),
                ],
              ),

              // Intro Chat
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                margin:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                decoration: BoxDecoration(
                  border: Border.all(color: Pallete.borderColor),
                  borderRadius:
                      BorderRadius.circular(20).copyWith(topLeft: Radius.zero),
                ),
                child: Text(
                  generatedContent == null
                      ? 'Salut, What can I help you with?'
                      : generatedContent!,
                  style: TextStyle(
                    fontFamily: 'Cera Pro',
                    color: Pallete.mainFontColor,
                    fontSize: generatedContent == null ? 25 : 18,
                  ),
                ),
              ),

              // Suggestion Text
              Visibility(
                visible: generatedContent == null,
                child: Container(
                  margin: const EdgeInsets.only(top: 20),
                  alignment: Alignment.center,
                  child: const Text(
                    'Here are a few suggestions.',
                    style: TextStyle(
                      fontFamily: 'Cera Pro',
                      color: Pallete.mainFontColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              // Suggestions List
              Visibility(
                visible: generatedContent == null,
                child: const Column(
                  children: [
                    FeatureBox(
                      color: Pallete.firstSuggestionBoxColor,
                      headerText: 'Code Captain',
                      descText:
                          'Stay updated on Coding Championships around you. Hackathons, Competitions, Bug Bounties, and more...',
                    ),
                    FeatureBox(
                      color: Pallete.secondSuggestionBoxColor,
                      headerText: 'Job Hunter',
                      descText:
                          'Find internships and job opportunities aligning with your expertise level. Get started now.',
                    ),
                    FeatureBox(
                      color: Pallete.thirdSuggestionBoxColor,
                      headerText: 'Smart Voice Assist',
                      descText:
                          'Personalized voice assistance at your service, powered by AI integration, making it inclusive and interactive.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          if (!await speechToText.hasPermission) {
            await initSpeechToText();
          } else if (speechToText.isNotListening) {
            await startListening();
          } else {
            final response = await aiService.isPrompt(lastWords);
            generatedContent = response;
            String sanitizedResponse = sanitizeResponse(response);
            setState(() {});
            await systemSpeak(sanitizedResponse);
            await stopListening();
          }
        },
        child: Icon(speechToText.isListening ? Icons.stop : Icons.mic),
      ),
    );
  }
}
