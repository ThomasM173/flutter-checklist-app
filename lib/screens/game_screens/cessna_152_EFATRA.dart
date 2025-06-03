import 'package:flutter/material.dart';
import 'dart:math';

class Cessna152EFATRA extends StatefulWidget {
  const Cessna152EFATRA({super.key});

  @override
  _Cessna152EFATRA createState() => _Cessna152EFATRA();
}

class _Cessna152EFATRA extends State<Cessna152EFATRA> {
  final List<Map<String, dynamic>> allQuestions = [
  {
    "question": "First action for engine failure after takeoff (RWY available):",
    "correct": "Airspeed - Pitch Down – 65 KTS",
    "options": ["Airspeed - Pitch Down – 65 KTS", "Throttle – IDLE", "Master Switch – OFF"]
  },
  {
    "question": "Second action for engine failure after takeoff (RWY available):",
    "correct": "Throttle – IDLE",
    "options": ["Throttle – IDLE", "Ignition Switch – OFF", "Mixture – CUT OFF"]
  },
  {
    "question": "Third action for engine failure after takeoff (RWY available):",
    "correct": "Mixture – CUT OFF",
    "options": ["Mixture – CUT OFF", "Fuel Shutoff Valve – OFF", "Touch Down"]
  },
  {
    "question": "Fourth action for engine failure after takeoff (RWY available):",
    "correct": "Fuel Shutoff Valve – OFF",
    "options": ["Fuel Shutoff Valve – OFF", "Throttle – IDLE", "Ignition Switch – OFF"]
  },
  {
    "question": "Fifth action for engine failure after takeoff (RWY available):",
    "correct": "Ignition Switch – OFF",
    "options": ["Ignition Switch – OFF", "Airspeed - Pitch Down – 65 KTS", "Mixture – CUT OFF"]
  },
  {
    "question": "Sixth action for engine failure after takeoff (RWY available):",
    "correct": "Master Switch – OFF",
    "options": ["Master Switch – OFF", "Fuel Shutoff Valve – OFF", "Throttle – IDLE"]
  },
  {
    "question": "Final action for engine failure after takeoff (RWY available):",
    "correct": "Touch Down",
    "options": ["Touch Down", "Master Switch – OFF", "Airspeed - Pitch Down – 65 KTS"]
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("🚨 Engine Failure After Takeoff (RWY Available)"),
        backgroundColor: Colors.orange,
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
              Color tileColor = Colors.white!;
              if (answered) {
                if (isSelected && isCorrect) {
                  tileColor = Colors.green;
                } else if (isSelected && !isCorrect) tileColor = Colors.red;
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
              SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                child: Text("🔁 Play Again", style: TextStyle(color: Colors.black)),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: Text("🏠 Back to Home", style: TextStyle(color: Colors.black)),
              )
            ],
          ),
        ),
      ),
    );
  }
}
