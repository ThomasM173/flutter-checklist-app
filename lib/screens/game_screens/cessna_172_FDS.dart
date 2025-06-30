import 'package:flutter/material.dart';
import 'dart:math';

class Cessna172FDS extends StatefulWidget {
  const Cessna172FDS({super.key});

  @override
  _Cessna172FDS createState() => _Cessna172FDS();
}

class _Cessna172FDS extends State<Cessna172FDS> {
  final List<Map<String, dynamic>> allQuestions = [
  {
    "question": "First action for engine fire during start:",
    "correct": "Cranking – CONTINUE",
    "options": ["Cranking – CONTINUE", "Mixture – CUT OFF", "Throttle – FULL OPEN"]
  },
  {
    "question": "If engine starts during fire, next action:",
    "correct": "Power – 1700 RPM → Engine – SHUTDOWN",
    "options": ["Power – 1700 RPM → Engine – SHUTDOWN", "Fire – EXTINGUISH", "Throttle – FULL OPEN"]
  },
  {
    "question": "If engine does not start during fire, next action:",
    "correct": "Throttle – FULL OPEN",
    "options": ["Throttle – FULL OPEN", "Cranking – CONTINUE", "Engine – SECURE (Ignition, Master, Fuel OFF)"]
  },
  {
    "question": "After opening throttle, what’s the next action for engine fire during start?",
    "correct": "Mixture – CUT OFF",
    "options": ["Mixture – CUT OFF", "Fire Extinguisher – OBTAIN", "Cranking – CONTINUE"]
  },
  {
    "question": "After mixture is cut off, what’s next action for engine fire during start?",
    "correct": "Cranking – CONTINUE",
    "options": ["Cranking – CONTINUE", "Engine – SECURE (Ignition, Master, Fuel OFF)", "Throttle – FULL OPEN"]
  },
  {
    "question": "Once engine shutdown steps are complete, what do you obtain?",
    "correct": "Fire Extinguisher – OBTAIN",
    "options": ["Fire Extinguisher – OBTAIN", "Cranking – CONTINUE", "Mixture – CUT OFF"]
  },
  {
    "question": "After obtaining fire extinguisher, what must you do to the engine?",
    "correct": "Engine – SECURE (Ignition, Master, Fuel OFF)",
    "options": ["Engine – SECURE (Ignition, Master, Fuel OFF)", "Power – 1700 RPM → Engine – SHUTDOWN", "Throttle – FULL OPEN"]
  },
  {
    "question": "Final action for engine fire during start:",
    "correct": "Fire – EXTINGUISH",
    "options": ["Fire – EXTINGUISH", "Mixture – CUT OFF", "Fire Extinguisher – OBTAIN"]
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
        title: Text("🚨 Engine Fire During Start"),
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

