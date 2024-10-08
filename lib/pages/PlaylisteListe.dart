import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PlaylisteListe extends StatefulWidget {
  @override
  _PlaylisteListeState createState() => _PlaylisteListeState();
}

class _PlaylisteListeState extends State<PlaylisteListe> {
  List<String> playlists = [];
  final User? user = FirebaseAuth.instance.currentUser;
  TextEditingController _playlistController = TextEditingController();

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
            playlists = List<String>.from(userPlaylists);

            // Ajouter "Titres likés" s'il n'existe pas
            if (!playlists.contains('Titres likés')) {
              playlists.add('Titres likés');
            }
          });

          // Créer "Titres likés" dans Firestore si pas existante
          if (!userPlaylists.contains('Titres likés')) {
            await _createPlaylist('Titres likés');
          }
        }
      } catch (e) {
        print('Erreur lors de la récupération des playlists : $e');
      }
    }
  }

  Future<void> _createPlaylist(String playlistName) async {
    if (playlistName.isNotEmpty && user != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .update({
          'playlists': FieldValue.arrayUnion([playlistName])
        });
        setState(() {
          playlists.add(playlistName);
        });
      } catch (e) {
        print('Erreur lors de la création de la playlist : $e');
      }
    }
  }

  Future<void> _deletePlaylist(String playlistName) async {
    // Ne pas permettre la suppression de la playlist "Titres likés"
    if (playlistName != 'Titres likés' && user != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .update({
          'playlists': FieldValue.arrayRemove([playlistName])
        });
        setState(() {
          playlists.remove(playlistName);
        });
      } catch (e) {
        print('Erreur lors de la suppression de la playlist : $e');
      }
    } else {
      // Afficher un message si l'utilisateur essaie de supprimer "Titres likés"
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('La playlist "Titres likés" ne peut pas être supprimée.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gérer les Playlists'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            TextField(
              controller: _playlistController,
              decoration: InputDecoration(
                labelText: 'Nom de la playlist',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                _createPlaylist(_playlistController.text);
                _playlistController.clear();
              },
              child: Text('Créer Playlist'),
            ),
            SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: playlists.length,
                itemBuilder: (context, index) {
                  final playlist = playlists[index];
                  return ListTile(
                    title: Text(playlist),
                    trailing: playlist != 'Titres likés'
                        ? IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () {
                              _deletePlaylist(playlist);
                            },
                          )
                        : null, // Pas de bouton de suppression pour "Titres likés"
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
