import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ModifPlaylist extends StatelessWidget {
  final String playlistName; // Nom de la playlist à modifier
  final Function onPlaylistUpdated; // Callback pour mettre à jour les playlists

  // Mise à jour du constructeur pour accepter onPlaylistUpdated
  ModifPlaylist({required this.playlistName, required this.onPlaylistUpdated});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Modifier Playlist'),
        centerTitle: true,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ListTile(
            title: Text(playlistName),
          ),
          ElevatedButton(
            onPressed: () {
              _deletePlaylist(context);
            },
            child: Text('Supprimer la Playlist'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red, // Couleur du bouton
            ),
          ),
        ],
      ),
    );
  }

  // Fonction pour supprimer la playlist
  Future<void> _deletePlaylist(BuildContext context) async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'playlists': FieldValue.arrayRemove([playlistName])
        });
        
        onPlaylistUpdated(); // Appel du callback pour mettre à jour les playlists
        Navigator.of(context).pop(); // Retour à la page précédente
      } catch (e) {
        print('Erreur lors de la suppression de la playlist : $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la suppression de la playlist.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      print('Aucun utilisateur connecté.');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Vous devez être connecté pour supprimer une playlist.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }
}
