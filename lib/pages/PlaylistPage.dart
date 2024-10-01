import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart'; // Importez firebase_storage
import 'dart:typed_data'; // Importez dart:typed_data ici
import 'ModifPlaylist.dart'; // Assurez-vous d'importer la page ModifPlaylist

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

  // Fonction pour ajouter une playlist dans Firestore et créer un dossier pour les icônes
  Future<void> _addPlaylistToFirestore(String playlistName) async {
    if (user != null) {
      try {
        // Créer un dossier pour la playlist dans Firebase Storage
        final storageRef =
            FirebaseStorage.instance.ref().child('playlists/$playlistName');

        // Créer un dossier (une référence à un dossier) sans fichier
        await storageRef.putData(Uint8List(
            0)); // Utiliser un tableau d'octets vide pour créer le dossier

        // Ajouter la playlist à Firestore
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

  // Ouvre la page ModifPlaylist pour renommer ou supprimer la playlist
  void _openPlaylistOptions(String playlistName) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ModifPlaylist(
          playlistName: playlistName,
          onPlaylistUpdated:
              _fetchPlaylists, // Passer la fonction de mise à jour
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Vos Playlists'),
        centerTitle: true,
        backgroundColor: Colors.white30,
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _createPlaylist,
            tooltip: 'Créer une Playlist',
          ),
        ],
      ),
      body: playlists.isEmpty
          ? Center(child: Text('Aucune playlist disponible.'))
          : ListView.builder(
              itemCount: playlists.length,
              itemBuilder: (context, index) {
                final color =
                    index % 2 == 0 ? Colors.grey[400] : Colors.grey[600];

                return Container(
                  color: color,
                  child: ListTile(
                    title: Text(
                      playlists[index],
                      style: TextStyle(color: Colors.black),
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.more_vert),
                      onPressed: () => _openPlaylistOptions(playlists[index]),
                    ),
                    onTap: () {
                      print("Ouverture de la playlist : ${playlists[index]}");
                    },
                  ),
                );
              },
            ),
      backgroundColor: Colors.transparent,
    );
  }
}
