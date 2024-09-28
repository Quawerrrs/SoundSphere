import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Importez Firestore pour accéder aux données de l'utilisateur
import 'ProfilePage.dart';
import 'MembersPage.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SoundSphere',
      theme: ThemeData.dark(),
      home: const PlaylistPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class PlaylistPage extends StatefulWidget {
  const PlaylistPage({super.key});

  @override
  _PlaylistPageState createState() => _PlaylistPageState();
}

class _PlaylistPageState extends State<PlaylistPage> {
  final User? user = FirebaseAuth.instance.currentUser;
  String? profileImageUrl; // Variable pour stocker l'URL de l'image de profil

  @override
  void initState() {
    super.initState();
    _fetchProfileImage(); // Récupérer l'image de profil lors de l'initialisation
  }

  // Fonction pour récupérer l'image de profil de Firestore
  Future<void> _fetchProfileImage() async {
    if (user != null) {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .get();

        if (userDoc.exists) {
          setState(() {
            profileImageUrl = userDoc['photoURL'] ?? '';
          });
        }
      } catch (e) {
        print('Erreur lors de la récupération de l\'image de profil : $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Builder(
          builder: (context) => Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue[800]!, Colors.black],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              children: [
                // Row pour les trois boutons ronds "Accueil", "Rechercher", "Vos Playlists"
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Bouton Accueil
                      IconButton(
                        icon: const Icon(Icons.home, color: Colors.white),
                        iconSize: 40,
                        onPressed: () {
                          // Action pour le bouton Accueil
                          Navigator.popUntil(context, (route) => route.isFirst);
                        },
                        tooltip: 'Accueil',
                      ),
                      // Bouton Rechercher
                      IconButton(
                        icon: const Icon(Icons.search, color: Colors.white),
                        iconSize: 40,
                        onPressed: () {
                          // Action pour le bouton Rechercher
                          print('Rechercher');
                        },
                        tooltip: 'Rechercher',
                      ),
                      // Bouton Vos Playlists
                      IconButton(
                        icon: const Icon(Icons.library_music, color: Colors.white),
                        iconSize: 40,
                        onPressed: () {
                          // Action pour le bouton "Vos Playlists"
                          print('Vos Playlists');
                        },
                        tooltip: 'Vos Playlists',
                      ),
                    ],
                  ),
                ),
                // Alignement pour le bouton de menu (avec l'image de profil)
                Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: GestureDetector(
                      onTap: () {
                        Scaffold.of(context).openDrawer();
                      },
                      child: CircleAvatar(
                        radius: 25,
                        backgroundImage: profileImageUrl != null && profileImageUrl!.isNotEmpty
                            ? NetworkImage(profileImageUrl!)
                            : const NetworkImage('https://via.placeholder.com/150'),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      drawer: Drawer(
        backgroundColor: Colors.black,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Colors.blueAccent,
              ),
              child: Column(
                children: [
                  // Affichez l'image de profil ou une image par défaut si aucune n'est disponible
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: profileImageUrl != null &&
                            profileImageUrl!.isNotEmpty
                        ? NetworkImage(profileImageUrl!)
                        : const NetworkImage('https://via.placeholder.com/150'),
                  ),
                  const SizedBox(height: 8),
                  Flexible(
                    child: Column(
                      children: [
                        Text(
                          user?.email ?? 'Email non disponible',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => ProfilePage()),
                            );
                          },
                          child: const Text(
                            'Voir votre Compte',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.playlist_play, color: Colors.white),
              title: const Text('Playlists',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.people, color: Colors.white),
              title:
                  const Text('Membres', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MembersPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings, color: Colors.white),
              title: const Text('Paramètres',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            const Divider(color: Colors.white),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.white),
              title: const Text('Déconnexion',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                print('Déconnexion');
              },
            ),
          ],
        ),
      ),
    );
  }
}
