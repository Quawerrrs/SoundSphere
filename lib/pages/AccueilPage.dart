import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'ProfilePage.dart';
import 'MembersPage.dart';
import 'HomePage.dart';
import 'PlaylisteListe.dart';
import 'dart:async'; // Pour le timer
import 'Recherche.dart'; // Import de la page de recherche
import 'LoginPage.dart'; // Assurez-vous d'importer votre LoginPage

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
        primarySwatch: Colors.deepPurple,
        scaffoldBackgroundColor: Colors.black,
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
              fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
          headlineMedium: TextStyle(
              fontSize: 18, fontWeight: FontWeight.w500, color: Colors.white),
          bodyMedium: TextStyle(fontSize: 14, color: Colors.white70),
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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final User? user = FirebaseAuth.instance.currentUser;
  String? profileImageUrl;
  int _selectedPageIndex = 0;
  double _animationValue = 0;

  // Ajout de la page de recherche dans la liste des pages
  final List<Widget> _pages = [
    HomePage(),
    PlaylisteListe(),
    MusicSearchScreen(), // Ajout de la page de recherche ici
  ];

  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _fetchProfileImage();
    _pageController = PageController(); // Initialisation du PageController
    Timer.periodic(const Duration(seconds: 5), (timer) {
      setState(() {
        _animationValue = _animationValue == 0 ? 1 : 0;
      });
    });
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
    _pageController.jumpToPage(index); // Changer la page dans le PageView
  }

  @override
  void dispose() {
    _pageController.dispose(); // Dispose du PageController
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: SafeArea(
        child: AnimatedContainer(
          duration: const Duration(seconds: 5),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _animationValue == 0
                  ? [Color(0xFF1E1E30), Color(0xFF12121A)] // Dégradé initial
                  : [Color(0xFF12121A), Color(0xFF1E1E30)], // Dégradé final
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    vertical: 16.0, horizontal: 16.0),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16.0),
                    bottomRight: Radius.circular(16.0),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      spreadRadius: 1,
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () {
                        _scaffoldKey.currentState?.openDrawer();
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
                        _onPageSelected(0);
                      },
                      tooltip: 'Accueil',
                    ),
                    IconButton(
                      icon: const Icon(Icons.search, color: Colors.white),
                      iconSize: 40,
                      onPressed: () {
                        _onPageSelected(2); // Sélectionner la page de recherche
                      },
                      tooltip: 'Rechercher',
                    ),
                    IconButton(
                      icon:
                          const Icon(Icons.library_music, color: Colors.white),
                      iconSize: 40,
                      onPressed: () {
                        _onPageSelected(1);
                      },
                      tooltip: 'Vos Playlists',
                    ),
                  ],
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _selectedPageIndex = index;
                    });
                  },
                  children: _pages,
                ),
              ),
            ],
          ),
        ),
      ),
      drawer: Drawer(
        backgroundColor: const Color(0xFF1E1E30),
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.deepPurple, Colors.purpleAccent],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: profileImageUrl != null &&
                            profileImageUrl!.isNotEmpty
                        ? NetworkImage(profileImageUrl!)
                        : const NetworkImage('https://via.placeholder.com/150'),
                  ),
                  const SizedBox(height: 8),
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
                        MaterialPageRoute(builder: (context) => ProfilePage()),
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
            ListTile(
              leading:
                  const Icon(Icons.playlist_play_rounded, color: Colors.white),
              title: const Text('Playlists',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                _onPageSelected(1);
                Navigator.pop(context);
              },
            ),
            const Divider(color: Colors.white70),
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
              onTap: () async {
                // Déconnexion de l'utilisateur
                await FirebaseAuth.instance.signOut();

                // Rediriger vers la page de login
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
