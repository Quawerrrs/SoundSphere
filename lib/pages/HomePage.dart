import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'Playlist.dart'; // Import de la page PlaylistPage

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final User? user = FirebaseAuth.instance.currentUser;
  List<String> playlists = []; // Liste des playlists récupérées depuis Firestore

  @override
  void initState() {
    super.initState();
    _fetchPlaylists(); // Récupérer les playlists au chargement de la page
  }

  // Fonction pour récupérer les playlists de Firestore
  Future<void> _fetchPlaylists() async {
    if (user != null) {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .get();

        if (userDoc.exists) {
          List<dynamic> userPlaylists = userDoc['playlists'] ?? [];
          setState(() {
            // Limiter les playlists à un maximum de 6
            playlists = List<String>.from(userPlaylists).take(6).toList();
          });
        }
      } catch (e) {
        print('Erreur lors de la récupération des playlists : $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Une playlist fixe intitulée "Titres likés"
    final String playlistLiked = "Titres likés";

    // Ajouter la playlist "Titres likés" en première position
    final List<String> allPlaylists = [playlistLiked, ...playlists];

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // Nombre de colonnes
            crossAxisSpacing: 16.0, // Plus d'espacement horizontal
            mainAxisSpacing: 16.0, // Plus d'espacement vertical
            childAspectRatio: 3 / 1, // Ratio largeur/hauteur pour les cellules
          ),
          itemCount: allPlaylists.length.clamp(0, 6), // Maximum de 6 éléments
          itemBuilder: (context, index) {
            String playlistTitle = allPlaylists[index];
            return GestureDetector(
              onTap: () {
                // Navigation vers la page PlaylistPage lors du clic
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Playlist(playlistTitle: playlistTitle),
                  ),
                );
              },
              child: Container(
                height: 60, // Hauteur du bandeau fixée à 60px
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 95, 95, 95), // Couleur gris foncé
                  borderRadius: BorderRadius.circular(16), // Bords plus arrondis
                ),
                child: Center(
                  child: Text(
                    playlistTitle,
                    style: const TextStyle(
                      color: Colors.white, // Texte en blanc
                      fontSize: 14, // Taille du texte ajustée
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            );
          },
        ),
      ),
      backgroundColor: Colors.transparent, // Fond transparent
    );
  }
}
