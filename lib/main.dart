// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'pages/AccueilPage.dart';
import 'pages/LoginPage.dart'; // Importer la page de login

// Remplacez par votre configuration Firebase
const firebaseOptions = FirebaseOptions(
  apiKey: "AIzaSyDDt6Y6coCexAJOnVgrlPz_tpC8uqi_pIc",
  appId: "1:661358917252:android:49a297801ccd930d5934d1",
  messagingSenderId: "661358917252",
  projectId: "music-k1zust",
  authDomain: "music-k1zust.firebaseapp.com",
  storageBucket: "music-k1zust.appspot.com",
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(options: firebaseOptions);
  } catch (e) {
    print("Firebase déjà initialisé: $e");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SoundSphere',
      theme: ThemeData.dark(),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          } else if (snapshot.hasData) {
            return const AccueilPage(); // Rediriger vers la page d'accueil si l'utilisateur est connecté
          } else {
            return const LoginPage(); // Sinon, rediriger vers la page de login
          }
        },
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
