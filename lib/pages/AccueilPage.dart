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
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.deepPurpleAccent,
        scaffoldBackgroundColor: Colors.black87,
        textTheme: const TextTheme(
          headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
          headlineMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.white),
          bodyMedium: TextStyle(fontSize: 14, color: Colors.white70),

        ),
        appBarTheme: const AppBarTheme(
          color: Colors.black87,
          iconTheme: IconThemeData(color: Colors.white),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all(Colors.deepPurple), // Modern purple for buttons
            foregroundColor: MaterialStateProperty.all(Colors.white),
            textStyle: MaterialStateProperty.all(const TextStyle(fontSize: 16)),
            shape: MaterialStateProperty.all(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20), // Rounded corners for buttons
              ),
            ),
          ),
        ),
      ),
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
  int _selectedPageIndex = 0;

  final List<Widget> _pages = [
    HomePage(),
    PlaylistPage(),
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

  void _onPageSelected(int index) {
    setState(() {
      _selectedPageIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.black87, Colors.black54],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            children: [
              Container(
                height: 80,
                color: Colors.black87,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () {
                          Scaffold.of(context).openDrawer();
                        },
                        child: CircleAvatar(
                          radius: 30,
                          backgroundImage: profileImageUrl != null && profileImageUrl!.isNotEmpty
                              ? NetworkImage(profileImageUrl!)
                              : const NetworkImage('https://via.placeholder.com/150'),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.home, color: Colors.white),
                        iconSize: 40,
                        onPressed: () {
                          _onPageSelected(0);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.search, color: Colors.white),
                        iconSize: 40,
                        onPressed: () {
                          print('Rechercher');
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.library_music, color: Colors.white),
                        iconSize: 40,
                        onPressed: () {
                          _onPageSelected(1);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: _pages[_selectedPageIndex],
              ),
            ],
          ),
        ),
      ),
      drawer: Drawer(
        backgroundColor: Colors.black87,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Colors.deepPurpleAccent,
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: profileImageUrl != null && profileImageUrl!.isNotEmpty
                        ? NetworkImage(profileImageUrl!)
                        : const NetworkImage('https://via.placeholder.com/150'),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    user?.email ?? 'Email non disponible',
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ProfilePage()),
                      );
                    },
                    child: const Text('Voir votre Compte', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
            _buildDrawerItem(Icons.playlist_play, 'Playlists', () {
              _onPageSelected(1);
              Navigator.pop(context);
            }),
            _buildDrawerItem(Icons.people, 'Membres', () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MembersPage()),
              );
            }),
            _buildDrawerItem(Icons.settings, 'Paramètres', () {
              Navigator.pop(context);
            }),
            const Divider(color: Colors.white),
            _buildDrawerItem(Icons.logout, 'Déconnexion', () {
              Navigator.pop(context);
              print('Déconnexion');
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, Function() onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      onTap: onTap,
    );
  }
}
