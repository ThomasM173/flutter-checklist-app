import 'package:flutter/material.dart';
import 'dart:math';

class CessnaEmergencyGame extends StatefulWidget {
  @override
  _CessnaEmergencyGameState createState() => _CessnaEmergencyGameState();
}

class _CessnaEmergencyGameState extends State<CessnaEmergencyGame> {
  final List<Map<String, dynamic>> allQuestions = [
    {
      "question": "First action for engine failure during takeoff roll:",
      "correct": "Throttle – IDLE",
      "options": ["Throttle – IDLE", "Flaps – UP", "Master Switch – OFF"]
    },
    {
      "question": "Airspeed for engine failure in flight:",
      "correct": "60 KTS",
      "options": ["85 KTS", "60 KTS", "70 KTS"]
    },
    {
      "question": "Mixture setting for engine fire in flight:",
      "correct": "Mixture – CUT OFF",
      "options": ["Mixture – RICH", "Mixture – CUT OFF", "Throttle – IDLE"]
    },
    {
      "question": "Final step before ditching:",
      "correct": "Life Vests – INFLATE",
      "options": ["Touchdown – LEVEL ATTITUDE", "Life Vests – INFLATE", "Doors – UNLATCH"]
    },
    {
      "question": "If low voltage light remains on:",
      "correct": "Alternator – OFF",
      "options": ["Transponder – STBY", "Alternator – OFF", "Flaps – UP"]
    },
    {
      "question": "Speed for emergency landing with flaps:",
      "correct": "60 KTS",
      "options": ["60 KTS", "55 KTS", "65 KTS"]
    },
    {
      "question": "Initial fire response in flight:",
      "correct": "Master Switch – OFF",
      "options": ["Master Switch – OFF", "Cabin Heat – ON", "Radios – OFF"]
    },
    {
      "question": "What to do with ignition switch if restart fails:",
      "correct": "OFF",
      "options": ["BOTH", "START", "OFF"]
    },
    {
      "question": "Cabin fire – first action:",
      "correct": "Master Switch – OFF",
      "options": ["Cabin Heat – OFF", "Master Switch – OFF", "Flaps – AS REQUIRED"]
    },
  ];

  late List<Map<String, dynamic>> questions;
  int currentIndex = 0;
  int score = 0;
  bool answered = false;
  String? selectedAnswer;

  @override
  void initState() {
    super.initState();
    questions = List.from(allQuestions)..shuffle(Random());
  }

  void checkAnswer(String answer) {
    setState(() {
      selectedAnswer = answer;
      answered = true;
      if (answer == questions[currentIndex]["correct"]) {
        score++;
      }
    });
  }

  void nextQuestion() {
    setState(() {
      if (currentIndex < questions.length - 1) {
        currentIndex++;
        answered = false;
        selectedAnswer = null;
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => GameOverScreen(score: score, total: questions.length),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final question = questions[currentIndex];

    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: Text("🚨 Emergency Learning Game"),
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Question ${currentIndex + 1} of ${questions.length}",
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            SizedBox(height: 10),
            Text(
              question['question'],
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
            SizedBox(height: 20),
            ...question["options"].map<Widget>((option) {
              final isCorrect = option == question["correct"];
              final isSelected = option == selectedAnswer;
              Color tileColor = Colors.grey[850]!;
              if (answered) {
                if (isSelected && isCorrect) tileColor = Colors.green;
                else if (isSelected && !isCorrect) tileColor = Colors.red;
                else if (!isSelected && isCorrect) tileColor = Colors.green.withOpacity(0.5);
              }
              return Card(
                color: tileColor,
                child: ListTile(
                  title: Text(option, style: TextStyle(color: Colors.white)),
                  onTap: () => answered ? null : checkAnswer(option),
                ),
              );
            }).toList(),
            SizedBox(height: 20),
            if (answered)
              Center(
                child: ElevatedButton(
                  onPressed: nextQuestion,
                  child: Text("Next"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                ),
              )
          ],
        ),
      ),
    );
  }
}

class GameOverScreen extends StatelessWidget {
  final int score;
  final int total;

  GameOverScreen({required this.score, required this.total});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: Text("Game Over"),
        backgroundColor: Colors.orange,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("✅ You scored $score out of $total!",
                  style: TextStyle(color: Colors.white, fontSize: 24)),
              SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                child: Text("🔁 Play Again", style: TextStyle(color: Colors.white)),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: Text("🏠 Back to Home", style: TextStyle(color: Colors.white)),
              )
            ],
          ),
        ),
      ),
    );
  }
}
