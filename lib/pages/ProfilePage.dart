import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final User? user =
      FirebaseAuth.instance.currentUser; // Récupérer l'utilisateur
  final ImagePicker _picker = ImagePicker();
  File? _imageFile; // Fichier pour stocker l'image sélectionnée

  // Fonction pour choisir une image depuis la galerie
  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path); // Stocker l'image sélectionnée
      });
    }
  }

  // Fonction pour télécharger l'image sélectionnée dans Firebase Storage
  Future<void> _uploadImage() async {
    if (_imageFile == null || user == null) return;

    try {
      // Créer un jeton unique pour l'image en utilisant l'UID de l'utilisateur
      final String userId = user!.uid;

      // Chemin de stockage de l'image dans Firebase Storage
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child('$userId.jpg'); // Utiliser l'UID comme nom de fichier

      // Télécharger l'image dans Firebase Storage
      await storageRef.putFile(_imageFile!);

      // Récupérer l'URL de l'image téléchargée
      final imageUrl = await storageRef.getDownloadURL();

      // Mettre à jour l'URL de la photo de profil dans Firebase Authentication
      await user!.updatePhotoURL(imageUrl);
      await user!.reload();

      // Remplacer le document de l'utilisateur dans Firestore avec l'URL de l'image
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!
              .uid) // Utiliser l'UID de l'utilisateur comme identifiant de document
          .set({
        'photoURL': imageUrl,
        'displayName': user?.displayName,
        'email': user?.email
      }); // Remplacer le champ 'photoURL', 'displayName' et 'email'

      setState(() {
        // Rafraîchir l'interface utilisateur avec la nouvelle image
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Image de profil mise à jour avec succès')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Erreur lors du téléchargement de l\'image : $e')),
      );
    }
  }

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
            // Affichage de l'image de profil actuelle ou de l'image sélectionnée
            CircleAvatar(
              radius: 50,
              backgroundImage: _imageFile != null
                  ? FileImage(_imageFile!)
                  : NetworkImage(
                      user?.photoURL ?? 'https://via.placeholder.com/150',
                    ) as ImageProvider,
            ),
            const SizedBox(height: 16),
            // Bouton pour choisir une image depuis la galerie
            ElevatedButton(
              onPressed: _pickImage,
              child: const Text('Choisir une nouvelle image de profil'),
            ),
            const SizedBox(height: 16),
            // Bouton pour télécharger l'image si une nouvelle image est sélectionnée
            if (_imageFile != null)
              ElevatedButton(
                onPressed: _uploadImage,
                child: const Text('Enregistrer l\'image de profil'),
              ),
            const SizedBox(height: 16),
            // Afficher le pseudo (displayName) ou un message par défaut
            Text(
              user?.displayName ?? 'Pseudo non disponible',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
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
//caca