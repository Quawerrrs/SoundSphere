import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfilePage extends StatelessWidget {
  final User? user = FirebaseAuth.instance.currentUser; // Récupérer l'utilisateur

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon Profil'),
        backgroundColor: Colors.black,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: NetworkImage(
                user?.photoURL ?? 'https://via.placeholder.com/150', // Utiliser la photo de l'utilisateur si disponible
              ),
            ),
            const SizedBox(height: 16),
            // Afficher le pseudo (displayName) ou un message par défaut
            Text(
              user?.displayName ?? 'Pseudo non disponible', 
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            // Afficher l'email
            Text(
              user?.email ?? 'Email non disponible',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Revenir à la page précédente
              },
              child: const Text('Retour'),
            ),
          ],
        ),
      ),
    );
  }
}
//test
//test 
//test 