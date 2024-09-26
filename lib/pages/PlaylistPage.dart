import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'ProfilePage.dart'; // Importez la page de profil
import 'MembersPage.dart'; // Ajoutez cette importation

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

class Playlist {
  final String title;
  final String description;

  Playlist({required this.title, required this.description});
}

class PlaylistPage extends StatelessWidget {
  const PlaylistPage({super.key});

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser; // Récupérer l'utilisateur connecté

    // Exemple de listes de playlists
    final List<Playlist> playlists = [
      Playlist(title: 'Chill Vibes', description: 'Musique relaxante pour se détendre'),
      Playlist(title: 'Workout Beats', description: 'Musique énergique pour le sport'),
      Playlist(title: 'Top Hits 2024', description: 'Les meilleurs succès de l\'année'),
      Playlist(title: 'Classic Rock', description: 'Les classiques du rock à ne pas manquer'),
    ];

    return Scaffold(
      // Suppression de l'AppBar de la hiérarchie du Container
      appBar: AppBar(
        title: const Text('SoundSphere'),
        backgroundColor: Colors.black,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue[800]!, Colors.black], // Dégradé bleu foncé vers noir
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20), // Ajout d'un espace en haut
                const Text(
                  'Bienvenue à l\'accueil de MUSIC',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20), // Ajout d'un espace
                // Affichage de la liste des playlists
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: playlists.length,
                  itemBuilder: (context, index) {
                    final playlist = playlists[index];
                    return Card(
                      color: Colors.grey[850], // Couleur de fond de la carte
                      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      child: ListTile(
                        title: Text(
                          playlist.title,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          playlist.description,
                          style: const TextStyle(color: Colors.white70),
                        ),
                        onTap: () {
                          // Ajoutez l'action pour naviguer vers une page de playlist
                          print('Playlist sélectionnée : ${playlist.title}');
                        },
                      ),
                    );
                  },
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
                  const CircleAvatar(
                    radius: 40,
                    backgroundImage: NetworkImage(
                      'https://via.placeholder.com/150', // Remplacez par l'URL de l'image
                    ),
                  ),
                  const SizedBox(height: 8),
                  Flexible(
                    child: Column(
                      children: [
                        // Limiter l'affichage de l'email avec ellipsis pour les emails longs
                        Text(
                          user?.email ?? 'Email non disponible', // Affichage de l'email utilisateur
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis, // Tronquer si trop long
                          maxLines: 1, // Limiter à une seule ligne
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => ProfilePage()), // Naviguer vers la page profil
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
              title: const Text('Playlists', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.people, color: Colors.white), // Icône pour Membres
              title: const Text('Membres', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MembersPage()), // Naviguer vers la page Membres
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings, color: Colors.white),
              title: const Text('Paramètres', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            const Divider(color: Colors.white),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.white),
              title: const Text('Déconnexion', style: TextStyle(color: Colors.white)),
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
//test 
//test 