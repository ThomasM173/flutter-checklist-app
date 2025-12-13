import 'package:flutter/material.dart';
import 'dart:math';

class PiperPA28PFL extends StatefulWidget {
  const PiperPA28PFL({super.key});

  @override
  _PiperPA28PFL createState() => _PiperPA28PFL();
}

class _PiperPA28PFL extends State<PiperPA28PFL> {
  final List<Map<String, dynamic>> allQuestions = [
  {
    "question": "First action for emergency landing without engine power:",
    "correct": "Airspeed - Pitch Down – 65 KTS",
    "options": ["Airspeed - Pitch Down – 65 KTS", "Mixture – RICH", "Throttle – IDLE"]
  },
  {
    "question": "After establishing best glide, what should you do next?",
    "correct": "Find Field Suitable, Then RESTART",
    "options": ["Find Field Suitable, Then RESTART", "MAYDAY RADIO CALL", "Flaps – AS REQUIRED"]
  },
  {
    "question": "First step in engine restart attempt:",
    "correct": "Mixture – RICH",
    "options": ["Mixture – RICH", "Primer – IN AND LOCKED", "Throttle – IDLE"]
  },
  {
    "question": "Second step in engine restart attempt:",
    "correct": "Fuel Shutoff Valve – ON",
    "options": ["Fuel Shutoff Valve – ON", "Doors – UNLATCH", "Flaps – AS REQUIRED"]
  },
  {
    "question": "Third step in engine restart attempt:",
    "correct": "Carb Heat – HOT",
    "options": ["Carb Heat – HOT", "Mixture – CUT OFF", "Master Switch – WHEN FLAPS AND RADIOS DONE"]
  },
  {
    "question": "Fourth step in engine restart attempt:",
    "correct": "Ignition Switch – BOTH, TRY L AND R",
    "options": ["Ignition Switch – BOTH, TRY L AND R", "MAYDAY RADIO CALL", "Fuel Shutoff Valve – OFF"]
  },
  {
    "question": "Final step in restart attempt:",
    "correct": "Primer – IN AND LOCKED",
    "options": ["Primer – IN AND LOCKED", "Ignition Switch – OFF", "Throttle – IDLE"]
  },
  {
    "question": "If restart unsuccessful, what is the first action?",
    "correct": "MAYDAY RADIO CALL",
    "options": ["MAYDAY RADIO CALL", "Fuel Shutoff Valve – OFF", "Mixture – CUT OFF"]
  },
  {
    "question": "First shutdown step after unsuccessful restart:",
    "correct": "Throttle – IDLE",
    "options": ["Throttle – IDLE", "Mixture – RICH", "Carb Heat – HOT"]
  },
  {
    "question": "After setting throttle to idle, next shutdown action:",
    "correct": "Mixture – CUT OFF",
    "options": ["Mixture – CUT OFF", "Ignition Switch – OFF", "Flaps – AS REQUIRED"]
  },
  {
    "question": "After mixture is cut off, next shutdown action:",
    "correct": "Fuel Shutoff Valve – OFF",
    "options": ["Fuel Shutoff Valve – OFF", "Primer – IN AND LOCKED", "MAYDAY RADIO CALL"]
  },
  {
    "question": "Next step after fuel shutoff valve is OFF:",
    "correct": "Ignition Switch – OFF",
    "options": ["Ignition Switch – OFF", "Carb Heat – HOT", "Mixture – CUT OFF"]
  },
  {
    "question": "When should flaps be set during engine-out emergency?",
    "correct": "Flaps – AS REQUIRED",
    "options": ["Flaps – AS REQUIRED", "Fuel Shutoff Valve – OFF", "Master Switch – WHEN FLAPS AND RADIOS DONE"]
  },
  {
    "question": "When should the master switch be turned off?",
    "correct": "Master Switch – WHEN FLAPS AND RADIOS DONE",
    "options": ["Master Switch – WHEN FLAPS AND RADIOS DONE", "Mixture – RICH", "Doors – UNLATCH"]
  },
  {
    "question": "Final cockpit action before touchdown during PFL:",
    "correct": "Doors – UNLATCH",
    "options": ["Doors – UNLATCH", "Mixture – CUT OFF", "Ignition Switch – OFF"]
  }
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
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: Text("🚨 Engine Failure In Flight / PFL"),
        backgroundColor: Colors.orange[400],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Question ${currentIndex + 1} of ${questions.length}",
              style: TextStyle(color: Colors.grey[500], fontSize: 16),
            ),
            SizedBox(height: 10),
            Text(
              question['question'],
              style: TextStyle(color: Colors.black, fontSize: 20),
            ),
            SizedBox(height: 20),
            ...question["options"].map<Widget>((option) {
              final isCorrect = option == question["correct"];
              final isSelected = option == selectedAnswer;
              Color tileColor = Colors.white;
              if (answered) {
                if (isSelected && isCorrect) {
                  tileColor = Colors.green;
                } else if (isSelected && !isCorrect) tileColor = Colors.red;
                else if (!isSelected && isCorrect) tileColor = Colors.green.withOpacity(0.5);
              }
              return Card(
                color: tileColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
                  title: Text(option, style: TextStyle(color: Colors.black)),
                  onTap: () => answered ? null : checkAnswer(option),
                ),
              );
            }).toList(),
            SizedBox(height: 20),
            if (answered)
              Center(
                child: ElevatedButton(
                  onPressed: nextQuestion,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  child: Text("Next"),
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

  const GameOverScreen({super.key, required this.score, required this.total});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
                  style: TextStyle(color: Colors.black, fontSize: 24)),
              SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                child: Text("🔁 PLAY AGAIN", style: TextStyle(color: Colors.black)),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: Text("🏠 Back to HOME", style: TextStyle(color: Colors.black)),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: Text("🏠 Back to GAME SCREEN", style: TextStyle(color: Colors.black)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
