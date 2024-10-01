import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ModifPlaylist extends StatefulWidget {
  final String playlistName;
  final Function onPlaylistUpdated;

  ModifPlaylist({required this.playlistName, required this.onPlaylistUpdated});

  @override
  _ModifPlaylistState createState() => _ModifPlaylistState();
}

class _ModifPlaylistState extends State<ModifPlaylist> {
  final TextEditingController _nameController = TextEditingController();
  final User? user = FirebaseAuth.instance.currentUser;
  File? _imageFile; // Pour stocker l'image de l'icône de la playlist
  final ImagePicker _picker = ImagePicker(); // Pour choisir l'image

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.playlistName;
    _fetchPlaylistIcon(); // Charger l'icône actuelle de la playlist
  }

  // Fonction pour récupérer l'icône actuelle de la playlist
  Future<void> _fetchPlaylistIcon() async {
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();

      List<dynamic> playlists = userDoc['playlists'] ?? [];
      // Parcours des playlists pour trouver l'icône associée
      // Ce code suppose que l'icône est stockée dans Firestore comme une URL d'image
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
              // Affichage de l'image actuelle de l'icône ou de l'image par défaut
              GestureDetector(
                onTap: _pickImage, // Appel pour changer l'icône
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: _imageFile != null
                      ? FileImage(_imageFile!)
                      : const AssetImage('assets/default_playlist_icon.png')
                          as ImageProvider, // Afficher une image par défaut
                  child: Icon(Icons.edit, color: Colors.white),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                style: const TextStyle(color: Colors.black),
                decoration: const InputDecoration(
                  labelText: 'Modifier le nom de la Playlist',
                  labelStyle: TextStyle(color: Colors.black),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[300],
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                ),
                onPressed: () {
                  _updatePlaylistName(context);
                },
                child: const Text(
                  'Modifier le Nom',
                  style: TextStyle(color: Colors.black),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                ),
                onPressed: () {
                  _deletePlaylist(context);
                },
                child: const Text(
                  'Supprimer la Playlist',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              if (_imageFile != null)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[300]),
                  onPressed: _uploadImage, // Enregistrer l'icône dans Firebase
                  child: const Text(
                    'Enregistrer l\'icône',
                    style: TextStyle(color: Colors.black),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Fonction pour choisir une image
  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path); // Stocker l'image sélectionnée
      });
    }
  }

  // Fonction pour télécharger l'image dans Firebase Storage
  Future<void> _uploadImage() async {
    if (_imageFile == null || user == null) return;

    try {
      final String playlistId =
          widget.playlistName; // Utiliser le nom de la playlist comme ID unique

      // Chemin de stockage de l'image dans Firebase Storage
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('playlist_icons')
          .child('$playlistId.jpg'); // Utiliser le nom de la playlist

      // Télécharger l'image dans Firebase Storage
      await storageRef.putFile(_imageFile!);

      // Récupérer l'URL de l'image téléchargée
      final imageUrl = await storageRef.getDownloadURL();

      // Mettre à jour l'URL de l'image dans Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .update({
        'playlists.$playlistId.icon': imageUrl, // Associer l'URL de l'icône
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Icône de la playlist mise à jour avec succès')),
      );
      setState(() {}); // Rafraîchir l'interface utilisateur
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Erreur lors du téléchargement de l\'image : $e')),
      );
    }
  }

  // Fonction pour mettre à jour le nom de la playlist
  Future<void> _updatePlaylistName(BuildContext context) async {
    if (user != null) {
      try {
        String newName = _nameController.text.trim();
        if (newName.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Le nom ne peut pas être vide.'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }

        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .get();

        List<dynamic> playlists = userDoc['playlists'] ?? [];

        // Vérifier si le nom existe déjà
        if (playlists.contains(newName)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Une playlist avec ce nom existe déjà.'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }

        // Supprimer l'ancien nom et ajouter le nouveau
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .update({
          'playlists': FieldValue.arrayRemove([widget.playlistName]),
        });
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .update({
          'playlists': FieldValue.arrayUnion([newName]),
        });

        widget.onPlaylistUpdated(); // Mettre à jour la liste des playlists
        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Le nom a été modifié avec succès.'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la modification du nom : $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vous devez être connecté pour modifier une playlist.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  // Fonction pour supprimer la playlist
  Future<void> _deletePlaylist(BuildContext context) async {
    if (user != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .update({
          'playlists': FieldValue.arrayRemove([widget.playlistName])
        });

        widget.onPlaylistUpdated(); // Mettre à jour la liste des playlists
        Navigator.of(context).pop(); // Retour à la page précédente
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la suppression de la playlist : $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Vous devez être connecté pour supprimer une playlist.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }
}
