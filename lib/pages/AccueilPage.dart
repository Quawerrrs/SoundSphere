import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Importez Firestore pour accéder aux données de l'utilisateur
import 'ProfilePage.dart';
import 'MembersPage.dart';
import 'HomePage.dart'; // Importez votre HomePage
import 'PlaylistPage.dart';

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
      home: const AccueilPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AccueilPage extends StatefulWidget {
  const AccueilPage({super.key});

  @override
  _AccueilPageState createState() => _AccueilPageState();
}

class _AccueilPageState extends State<AccueilPage> {
  final User? user = FirebaseAuth.instance.currentUser;
  String? profileImageUrl;
  int _selectedPageIndex = 0; // Variable pour suivre la page sélectionnée

  // Liste des pages à afficher en fonction de l'index sélectionné
  final List<Widget> _pages = [
    HomePage(), // Page d'accueil
    PlaylistPage(), // Page des playlists
  ];

  @override
  void initState() {
    super.initState();
    _fetchProfileImage();
  }

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

  // Fonction pour changer la page affichée
  void _onPageSelected(int index) {
    setState(() {
      _selectedPageIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Builder(
          builder: (context) => Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF00008B), Colors.black],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Stack(
              children: [
                Container(
                  height: 80,
                  color: Colors.black,
                ),
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 16.0, horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () {
                              Scaffold.of(context).openDrawer();
                            },
                            child: CircleAvatar(
                              radius: 25,
                              backgroundImage: profileImageUrl != null &&
                                      profileImageUrl!.isNotEmpty
                                  ? NetworkImage(profileImageUrl!)
                                  : const NetworkImage(
                                      'https://via.placeholder.com/150'),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.home, color: Colors.white),
                            iconSize: 40,
                            onPressed: () {
                              _onPageSelected(0); // Affiche HomePage
                            },
                            tooltip: 'Accueil',
                          ),
                          IconButton(
                            icon: const Icon(Icons.search, color: Colors.white),
                            iconSize: 40,
                            onPressed: () {
                              print('Rechercher');
                            },
                            tooltip: 'Rechercher',
                          ),
                          IconButton(
                            icon: const Icon(Icons.library_music,
                                color: Colors.white),
                            iconSize: 40,
                            onPressed: () {
                              _onPageSelected(1); // Affiche PlaylistPage
                            },
                            tooltip: 'Vos Playlists',
                          ),
                        ],
                      ),
                    ),
                    // Affichage de la page sélectionnée
                    Expanded(
                      child: _pages[_selectedPageIndex],
                    ),
                  ],
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
                _onPageSelected(1); // Affiche PlaylistPage
                Navigator.pop(context); // Ferme le Drawer
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
