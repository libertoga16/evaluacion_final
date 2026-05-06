import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'mock_seeder.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  runApp(const MaterialApp(
    home: SeederScreen(),
  ));
}

class SeederScreen extends StatefulWidget {
  const SeederScreen({super.key});

  @override
  State<SeederScreen> createState() => _SeederScreenState();
}

class _SeederScreenState extends State<SeederScreen> {
  String status = 'Iniciando carga de usuarios y canciones falsas...';

  @override
  void initState() {
    super.initState();
    _runSeeder();
  }

  Future<void> _runSeeder() async {
    try {
      await MockSeeder.seedDatabase();
      setState(() => status = '✅ Base de datos rellenada con éxito!\n\nYa puedes cerrar esto y volver a arrancar tu app normal.');
    } catch (e) {
      setState(() => status = '❌ Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Text(
            status, 
            style: const TextStyle(color: Colors.white, fontSize: 20),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
