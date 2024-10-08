import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'Playlist.dart'; // Import de la page Playlist

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final User? user = FirebaseAuth.instance.currentUser;
  List<String> playlists = [];
  Map<String, List<String>> playlistSongs = {};
  final String likedPlaylist =
      "Titres likés"; // Définir le nom de la playlist "Titres likés"

  @override
  void initState() {
    super.initState();
    _fetchPlaylists();
  }

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
            playlists = List<String>.from(userPlaylists).take(6).toList();
          });

          for (var playlist in playlists) {
            DocumentSnapshot playlistDoc = await FirebaseFirestore.instance
                .collection('users')
                .doc(user!.uid)
                .collection('playlists')
                .doc(playlist)
                .get();

            if (playlistDoc.exists) {
              List<dynamic> songs = playlistDoc['songs'] ?? [];
              setState(() {
                playlistSongs[playlist] =
                    List<String>.from(songs.map((song) => song['videoId']));
              });
            }
          }
        }
      } catch (e) {
        print('Erreur lors de la récupération des playlists : $e');
      }
    }
  }

  Widget _buildPlaylistCard(String playlistTitle) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Playlist(
              playlistName: playlistTitle,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 95, 95, 95), // Couleur gris foncé
          borderRadius: BorderRadius.circular(16), // Bords arrondis
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.5), // Ombre lumineuse
              spreadRadius: 3,
              blurRadius: 15,
              offset: const Offset(0, 3), // Déplacement de l'ombre
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.2), // Ombre douce
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 2), // Déplacement de l'ombre
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: CircleAvatar(
                backgroundColor: Colors.black,
                child: Icon(
                  Icons.music_note, // Icône par défaut
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                playlistTitle,
                style: const TextStyle(
                  color: Colors.white, // Texte en blanc
                  fontSize: 14, // Taille du texte ajustée
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.left, // Aligner le texte à gauche
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Ajoutez "Titres likés" en premier, seulement si elle n'est pas déjà dans les playlists de l'utilisateur
    final List<String> allPlaylists = [
      likedPlaylist,
      ...playlists.where((playlist) => playlist != likedPlaylist)
    ];

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // Nombre de colonnes
            crossAxisSpacing: 16.0, // Espacement horizontal
            mainAxisSpacing: 20.0, // Espacement vertical
            childAspectRatio: 3 / 1, // Ratio largeur/hauteur pour les cellules
          ),
          itemCount: allPlaylists.length.clamp(0, 6), // Maximum de 6 éléments
          itemBuilder: (context, index) {
            String playlistTitle = allPlaylists[index];
            return _buildPlaylistCard(
                playlistTitle); // Utiliser la fonction pour créer la carte
          },
        ),
      ),
      backgroundColor: Colors.transparent, // Fond transparent
    );
  }
}
