import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // Importez firebase_core
import 'package:firebase_auth/firebase_auth.dart'; // Importez firebase_auth
import 'package:cloud_firestore/cloud_firestore.dart'; // Importez Firestore
import './pages/PlaylistPage.dart'; // Remplacez par le chemin correct vers PlaylistPage

// Remplacez par votre configuration Firebase
const firebaseOptions = FirebaseOptions(
  apiKey: "AIzaSyDDt6Y6coCexAJOnVgrlPz_tpC8uqi_pIc", // Clé API
  appId: "1:661358917252:android:49a297801ccd930d5934d1", // ID de l'application
  messagingSenderId: "661358917252", // ID de l'expéditeur
  projectId: "music-k1zust", // ID du projet
  authDomain: "music-k1zust.firebaseapp.com", // Domaine d'authentification
  storageBucket: "music-k1zust.appspot.com", // Bucket de stockage
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Assurez-vous que Flutter est initialisé

  // Vérifiez si Firebase a déjà été initialisé
  try {
    await Firebase.initializeApp(options: firebaseOptions); // Initialisez Firebase avec les options
  } catch (e) {
    print("Firebase déjà initialisé: $e"); // Gérer l'erreur
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
      home: const LoginPage(), // Page d'accueil
      debugShowCheckedModeBanner: false, // Enlève le bandeau de démo
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
  final _pseudoController = TextEditingController(); // Contrôleur pour le pseudo
  bool isLogin = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _pseudoController.dispose(); // Dispose du contrôleur pseudo
    super.dispose();
  }

  Future<void> _login() async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: _emailController.text, 
        password: _passwordController.text,
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const PlaylistPage()), // Redirection vers PlaylistPage
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
      // Créer l'utilisateur avec Firebase Auth
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      // Enregistrer le pseudo et d'autres informations dans Firestore
      await FirebaseFirestore.instance
          .collection('users') // Collection "users" dans Firestore
          .doc(userCredential.user?.uid) // Utiliser l'UID de l'utilisateur comme ID du document
          .set({
        'email': _emailController.text,
        'pseudo': _pseudoController.text, // Stocker le pseudo dans Firestore
        'createdAt': Timestamp.now(), // Ajouter un timestamp pour la création
      });

      // Mettre à jour le displayName de l'utilisateur
      await userCredential.user!.updateProfile(displayName: _pseudoController.text);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const PlaylistPage()), // Redirection vers PlaylistPage
      );
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
              // Toggle entre Login et Register
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
                        fontWeight: isLogin ? FontWeight.bold : FontWeight.normal,
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
                        fontWeight: !isLogin ? FontWeight.bold : FontWeight.normal,
                        color: !isLogin ? Colors.black : Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Champ Email
              TextField(
                controller: _emailController,
                style: const TextStyle(color: Colors.black), // Couleur du texte
                decoration: InputDecoration(
                  labelText: 'Email',
                  labelStyle: const TextStyle(color: Colors.black), // Couleur de l'étiquette
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),

              const SizedBox(height: 10),

              // Champ Password
              TextField(
                controller: _passwordController,
                style: const TextStyle(color: Colors.black), // Couleur du texte
                decoration: InputDecoration(
                  labelText: 'Password',
                  labelStyle: const TextStyle(color: Colors.black), // Couleur de l'étiquette
                  border: const OutlineInputBorder(),
                ),
                obscureText: true,
              ),

              if (!isLogin) const SizedBox(height: 10),

              // Champ Confirm Password (si inscription)
              if (!isLogin)
                TextField(
                  controller: _confirmPasswordController,
                  style: const TextStyle(color: Colors.black), // Couleur du texte
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    labelStyle: const TextStyle(color: Colors.black), // Couleur de l'étiquette
                    border: const OutlineInputBorder(),
                  ),
                  obscureText: true,
                ),

              // Champ Pseudo (si inscription)
              if (!isLogin) const SizedBox(height: 10),
              if (!isLogin)
                TextField(
                  controller: _pseudoController,  // Nouveau champ pseudo
                  style: const TextStyle(color: Colors.black), // Couleur du texte
                  decoration: InputDecoration(
                    labelText: 'Pseudo',
                    labelStyle: const TextStyle(color: Colors.black), // Couleur de l'étiquette
                    border: const OutlineInputBorder(),
                  ),
                ),

              const SizedBox(height: 20),

              // Bouton Se connecter / S'inscrire
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
//test 
//test 
//test 