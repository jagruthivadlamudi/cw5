import 'package:flutter/material.dart';
import 'dart:math';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

void main() {
  runApp(VirtualAquariumApp());
}

class VirtualAquariumApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Virtual Aquarium',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: AquariumScreen(),
    );
  }
}

class Fish {
  Color color;
  double speed;
  Offset position;
  double directionX;
  double directionY;
  double size;

  Fish({
    required this.color,
    required this.speed,
    required this.position,
    required this.directionX,
    required this.directionY,
    this.size = 20, // Ensure the size is always initialized
  });

  void move(Size containerSize) {
    // Update fish position based on direction and speed
    position = Offset(
      position.dx + directionX * speed,
      position.dy + directionY * speed,
    );

    // Bounce off the edges
    if (position.dx <= 0 || position.dx >= containerSize.width - size) {
      directionX = -directionX; // Reverse horizontal direction
    }
    if (position.dy <= 0 || position.dy >= containerSize.height - size) {
      directionY = -directionY; // Reverse vertical direction
    }
  }
}

class AquariumScreen extends StatefulWidget {
  @override
  _AquariumScreenState createState() => _AquariumScreenState();
}

class _AquariumScreenState extends State<AquariumScreen>
    with SingleTickerProviderStateMixin {
  List<Fish> fishList = [];
  Color selectedColor = Colors.blue;
  double selectedSpeed = 1.0;
  AnimationController? _controller;
  Random random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 50),
    )..repeat();

    _controller?.addListener(() {
      setState(() {
        for (var fish in fishList) {
          fish.move(
              Size(300, 300)); // Move each fish within the 300x300 container
        }
      });
    });

    loadPreferences();
  }

  void _addFish() {
    if (fishList.length < 10) {
      setState(() {
        double randomDirectionX = random.nextBool() ? 1.0 : -1.0;
        double randomDirectionY = random.nextBool() ? 1.0 : -1.0;
        Fish newFish = Fish(
          color: selectedColor,
          speed: selectedSpeed,
          position:
              Offset(random.nextDouble() * 280, random.nextDouble() * 280),
          directionX: randomDirectionX,
          directionY: randomDirectionY,
          size: 20, // Explicitly set the size to avoid null issues
        );
        fishList.add(newFish);
      });
    }
  }

  void loadPreferences() async {
    final database = await openDatabase(
      join(await getDatabasesPath(), 'settings.db'),
      onCreate: (db, version) {
        return db.execute(
          "CREATE TABLE settings(id INTEGER PRIMARY KEY, color INTEGER, speed REAL)",
        );
      },
      version: 1,
    );

    final List<Map<String, dynamic>> settings =
        await database.query('settings');
    if (settings.isNotEmpty) {
      setState(() {
        Color restoredColor = Color(settings.first['color']);
        if (restoredColor != Colors.blue &&
            restoredColor != Colors.red &&
            restoredColor != Colors.green) {
          selectedColor = Colors.blue; // Default if mismatch
        } else {
          selectedColor = restoredColor;
        }
        selectedSpeed = settings.first['speed'];
      });
    }
  }

  void savePreferences() async {
    final database =
        await openDatabase(join(await getDatabasesPath(), 'settings.db'));
    await database.insert(
      'settings',
      {
        'color': selectedColor.value,
        'speed': selectedSpeed,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Virtual Aquarium'),
      ),
      body: Column(
        children: [
          Container(
            width: 300,
            height: 300,
            color: Colors.lightBlueAccent,
            child: Stack(
              children: fishList.map((fish) {
                return Positioned(
                  left: fish.position.dx,
                  top: fish.position.dy,
                  child: Container(
                    width: fish.size,
                    height: fish.size,
                    decoration: BoxDecoration(
                      color: fish.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          Row(
            children: [
              ElevatedButton(onPressed: _addFish, child: Text('Add Fish')),
              ElevatedButton(
                  onPressed: savePreferences, child: Text('Save Settings')),
            ],
          ),
          Slider(
            value: selectedSpeed,
            min: 0.5,
            max: 5.0,
            onChanged: (double value) {
              setState(() {
                selectedSpeed = value;
              });
            },
          ),
          DropdownButton<Color>(
            value: selectedColor,
            items: [
              DropdownMenuItem(
                value: Colors.blue,
                child: Text('Blue'),
              ),
              DropdownMenuItem(
                value: Colors.red,
                child: Text('Red'),
              ),
              DropdownMenuItem(
                value: Colors.green,
                child: Text('Green'),
              ),
            ],
            onChanged: (Color? value) {
              setState(() {
                selectedColor = value!;
              });
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}
