import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import './pages/PlaylistPage.dart';

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
            return const PlaylistPage();
          } else {
            return const LoginPage();
          }
        },
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _auth = FirebaseAuth.instance;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _pseudoController = TextEditingController();
  bool isLogin = true;
  bool stayLoggedIn = false; // Variable pour gérer l'état de la case à cocher

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _pseudoController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    try {
      if (stayLoggedIn) {
        // Si l'utilisateur souhaite rester connecté, utiliser la persistance locale
        await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
      } else {
        // Sinon, n'utiliser la persistance que pour la session en cours
        await FirebaseAuth.instance.setPersistence(Persistence.NONE);
      }

      await _auth.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur de connexion : $e")),
      );
    }
  }

  Future<void> _register() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Les mots de passe ne correspondent pas")),
      );
      return;
    }

    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user?.uid)
          .set({
        'email': _emailController.text,
        'pseudo': _pseudoController.text,
        'createdAt': Timestamp.now(),
      });

      await userCredential.user!
          .updateProfile(displayName: _pseudoController.text);
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur d'inscription : $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.blueAccent.withOpacity(0.5),
                blurRadius: 20.0,
                spreadRadius: 5.0,
              ),
            ],
          ),
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        isLogin = true;
                      });
                    },
                    child: Text(
                      'Login',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight:
                            isLogin ? FontWeight.bold : FontWeight.normal,
                        color: isLogin ? Colors.black : Colors.grey,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        isLogin = false;
                      });
                    },
                    child: Text(
                      'Register',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight:
                            !isLogin ? FontWeight.bold : FontWeight.normal,
                        color: !isLogin ? Colors.black : Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              if (!isLogin) const SizedBox(height: 10),
              if (!isLogin)
                TextField(
                  controller: _pseudoController,
                  style: const TextStyle(color: Colors.black),
                  decoration: InputDecoration(
                    labelText: 'Pseudo',
                    labelStyle: const TextStyle(color: Colors.black),
                    border: const OutlineInputBorder(),
                  ),
                ),

              TextField(
                controller: _emailController,
                style: const TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  labelText: 'Email',
                  labelStyle: const TextStyle(color: Colors.black),
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),

              const SizedBox(height: 10),

              TextField(
                controller: _passwordController,
                style: const TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  labelText: 'Password',
                  labelStyle: const TextStyle(color: Colors.black),
                  border: const OutlineInputBorder(),
                ),
                obscureText: true,
              ),

              if (!isLogin) const SizedBox(height: 10),

              if (!isLogin)
                TextField(
                  controller: _confirmPasswordController,
                  style: const TextStyle(color: Colors.black),
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    labelStyle: const TextStyle(color: Colors.black),
                    border: const OutlineInputBorder(),
                  ),
                  obscureText: true,
                ),

              const SizedBox(height: 20),

              // Checkbox pour "Rester connecté"
              Row(
                children: [
                  Checkbox(
                    value: stayLoggedIn,
                    onChanged: (bool? value) {
                      setState(() {
                        stayLoggedIn = value ?? false;
                      });
                    },
                  ),
                  const Text(
                    'Rester connecté',
                    style: TextStyle(color: Colors.black),
                  ),
                ],
              ),

              ElevatedButton(
                onPressed: () {
                  if (isLogin) {
                    _login();
                  } else {
                    _register();
                  }
                },
                child: Text(isLogin ? 'Se connecter' : 'S\'inscrire'),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
