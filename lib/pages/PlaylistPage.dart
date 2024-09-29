import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PlaylistPage extends StatefulWidget {
  @override
  _PlaylistPageState createState() => _PlaylistPageState();
}

class _PlaylistPageState extends State<PlaylistPage> {
  final User? user = FirebaseAuth.instance.currentUser;
  List<String> playlists = []; // Liste pour stocker les titres de playlists

  @override
  void initState() {
    super.initState();
    _fetchPlaylists(); // Récupérer les playlists lors de l'initialisation
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
            playlists = List<String>.from(userPlaylists);
          });
        }
      } catch (e) {
        print('Erreur lors de la récupération des playlists : $e');
      }
    }
  }

  // Fonction pour créer une nouvelle playlist
  void _createPlaylist() {
    showDialog(
      context: context,
      builder: (context) {
        String newPlaylistName = '';
        return AlertDialog(
          title: Text('Créer une nouvelle playlist'),
          content: TextField(
            onChanged: (value) {
              newPlaylistName = value;
            },
            decoration: InputDecoration(hintText: "Nom de la playlist"),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (newPlaylistName.isNotEmpty) {
                  _addPlaylistToFirestore(newPlaylistName);
                  Navigator.of(context).pop();
                }
              },
              child: Text('Créer'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Annuler'),
            ),
          ],
        );
      },
    );
  }

  // Fonction pour ajouter une playlist dans Firestore
  Future<void> _addPlaylistToFirestore(String playlistName) async {
    if (user != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .update({
          'playlists': FieldValue.arrayUnion([playlistName])
        });
        _fetchPlaylists(); // Met à jour la liste des playlists après ajout
      } catch (e) {
        print('Erreur lors de l\'ajout de la playlist : $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Playlists'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed:
                _createPlaylist, // Appel de la fonction pour créer une playlist
            tooltip: 'Créer une Playlist',
          ),
        ],
      ),
      body: playlists.isEmpty
          ? Center(child: Text('Aucune playlist disponible.'))
          : ListView.builder(
              itemCount: playlists.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(playlists[index]),
                  onTap: () {
                    // Action à effectuer lors de la sélection d'une playlist
                    print("Playlist sélectionnée : ${playlists[index]}");
                  },
                );
              },
            ),
      backgroundColor: Colors.transparent,
    );
  }
}
