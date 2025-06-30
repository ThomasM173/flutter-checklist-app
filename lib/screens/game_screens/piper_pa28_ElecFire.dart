import 'package:flutter/material.dart';
import 'dart:math';

class PiperPA28ElecFire extends StatefulWidget {
  const PiperPA28ElecFire({super.key});

  @override
  _PiperPA28ElecFire createState() => _PiperPA28ElecFire();
}

class _PiperPA28ElecFire extends State<PiperPA28ElecFire> {
  final List<Map<String, dynamic>> allQuestions = [
  {
    "question": "First action for electrical fire in flight:",
    "correct": "Master Switch – OFF",
    "options": ["Master Switch – OFF", "Fire Extinguisher – ACTIVATE", "Radios – ON (ONE AT A TIME)"]
  },
  {
    "question": "Second action for electrical fire in flight:",
    "correct": "All Switches (except ign) – OFF",
    "options": ["All Switches (except ign) – OFF", "Circuit Breakers – CHECK TRIPPED", "Vents & Cabin Air/Heat – OPEN"]
  },
  {
    "question": "Third action for electrical fire in flight:",
    "correct": "Vents & Cabin Air/Heat – CLOSED",
    "options": ["Vents & Cabin Air/Heat – CLOSED", "Radios – ON (ONE AT A TIME)", "Master Switch – ON"]
  },
  {
    "question": "Fourth action for electrical fire in flight:",
    "correct": "Fire Extinguisher – ACTIVATE",
    "options": ["Fire Extinguisher – ACTIVATE", "Vents & Cabin Air/Heat – OPEN", "All Switches (except ign) – OFF"]
  },
  {
    "question": "After fire is out and power is needed, what is the first step?",
    "correct": "Master Switch – ON",
    "options": ["Master Switch – ON", "Fire Extinguisher – ACTIVATE", "Vents & Cabin Air/Heat – CLOSED"]
  },
  {
    "question": "After restoring power, what should be checked?",
    "correct": "Circuit Breakers – CHECK TRIPPED",
    "options": ["Circuit Breakers – CHECK TRIPPED", "Vents & Cabin Air/Heat – CLOSED", "All Switches (except ign) – OFF"]
  },
  {
    "question": "After checking circuit breakers, what comes next?",
    "correct": "Radios – ON (ONE AT A TIME)",
    "options": ["Radios – ON (ONE AT A TIME)", "Fire Extinguisher – ACTIVATE", "Master Switch – OFF"]
  },
  {
    "question": "Final action after electrical fire in flight if fire is out:",
    "correct": "Vents & Cabin Air/Heat – OPEN",
    "options": ["Vents & Cabin Air/Heat – OPEN", "Circuit Breakers – CHECK TRIPPED", "Master Switch – ON"]
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
        title: Text("🚨 Electrical Fire In Flight"),
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

