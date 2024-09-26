import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'ProfilePage.dart';
import 'MembersPage.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

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
  final String url;

  Playlist({required this.title, required this.description, required this.url});
}

class PlaylistPage extends StatefulWidget {
  const PlaylistPage({super.key});

  @override
  _PlaylistPageState createState() => _PlaylistPageState();
}

class _PlaylistPageState extends State<PlaylistPage> {
  final User? user = FirebaseAuth.instance.currentUser;
  final AudioPlayer _audioPlayer =
      AudioPlayer(); // Initialisation d'audio player
  bool isPlaying = false;
  String currentTrack = '';
  String _searchQuery = ''; // Variable de recherche
  List<dynamic> _youtubeResults = []; // Résultats de la recherche YouTube
  YoutubePlayerController?
      _youtubePlayerController; // Contrôleur pour le lecteur YouTube

  final List<Playlist> playlists = [
    Playlist(
        title: 'Chill Vibes',
        description: 'Musique relaxante pour se détendre',
        url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3'),
    Playlist(
        title: 'Workout Beats',
        description: 'Musique énergique pour le sport',
        url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3'),
    Playlist(
        title: 'Top Hits 2024',
        description: 'Les meilleurs succès de l\'année',
        url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3'),
    Playlist(
        title: 'Classic Rock',
        description: 'Les classiques du rock à ne pas manquer',
        url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3'),
  ];

  void _playPauseMusic(String url) async {
    if (isPlaying && currentTrack == url) {
      await _audioPlayer.pause();
      setState(() {
        isPlaying = false;
      });
    } else {
      await _audioPlayer.play(url); // Jouer l'URL directement
      setState(() {
        isPlaying = true;
        currentTrack = url;
      });
    }
  }

  // Fonction pour rechercher des vidéos YouTube
  Future<void> _searchYouTube(String query) async {
    final apiKey =
        'AIzaSyC_W6fPUm85JrI_ErzbF-1Atrz_RnUWnT8'; // Remplacez par votre propre clé API YouTube
    final url = Uri.https(
      'www.googleapis.com',
      '/youtube/v3/search',
      {
        'part': 'snippet',
        'maxResults': '10',
        'q': query,
        'type': 'video',
        'key': apiKey,
      },
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        _youtubeResults = data['items'];
      });
    } else {
      print(
          'Erreur lors de la récupération des vidéos: ${response.statusCode}');
    }
  }

  // Fonction pour jouer la vidéo YouTube
  void _playYouTubeVideo(String videoId) {
    if (_youtubePlayerController != null) {
      _youtubePlayerController!
          .dispose(); // Dispose de l'ancien contrôleur s'il existe
    }
    _youtubePlayerController = YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
      ),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SoundSphere'),
        backgroundColor: Colors.black,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue[800]!, Colors.black],
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
                const SizedBox(height: 20),
                const Text(
                  'Bienvenue à l\'accueil de MUSIC',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                // Barre de recherche
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Rechercher sur YouTube...',
                      prefixIcon: const Icon(Icons.search, color: Colors.white),
                      filled: true,
                      fillColor: Colors.grey[800],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                    onSubmitted: (query) {
                      setState(() {
                        _searchQuery = query;
                      });
                      _searchYouTube(query); // Lancer la recherche YouTube
                    },
                  ),
                ),
                const SizedBox(height: 20),
                // Affichage du lecteur YouTube
                if (_youtubePlayerController != null)
                  YoutubePlayer(
                    controller: _youtubePlayerController!,
                    showVideoProgressIndicator: true,
                    onReady: () {
                      _youtubePlayerController!.addListener(() {});
                    },
                  ),
                const SizedBox(height: 20),
                // Affichage des résultats de recherche YouTube
                _youtubeResults.isNotEmpty
                    ? ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _youtubeResults.length,
                        itemBuilder: (context, index) {
                          final video = _youtubeResults[index];
                          final videoId = video['id']['videoId'];
                          final videoTitle = video['snippet']['title'];
                          final videoDescription =
                              video['snippet']['description'];
                          final thumbnailUrl =
                              video['snippet']['thumbnails']['high']['url'];

                          return Card(
                            color: Colors.grey[850],
                            margin: const EdgeInsets.symmetric(
                                vertical: 8, horizontal: 16),
                            child: ListTile(
                              leading: Image.network(thumbnailUrl,
                                  fit: BoxFit.cover),
                              title: Text(videoTitle,
                                  style: const TextStyle(color: Colors.white)),
                              subtitle: Text(
                                videoDescription,
                                style: const TextStyle(color: Colors.white70),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              onTap: () =>
                                  _playYouTubeVideo(videoId), // Jouer la vidéo
                            ),
                          );
                        },
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: playlists.length,
                        itemBuilder: (context, index) {
                          final playlist = playlists[index];
                          return Card(
                            color: Colors.grey[850],
                            margin: const EdgeInsets.symmetric(
                                vertical: 8, horizontal: 16),
                            child: ListTile(
                              title: Text(
                                playlist.title,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                playlist.description,
                                style: const TextStyle(color: Colors.white70),
                              ),
                              trailing: IconButton(
                                icon: Icon(
                                  isPlaying && currentTrack == playlist.url
                                      ? Icons.pause
                                      : Icons.play_arrow,
                                  color: Colors.white,
                                ),
                                onPressed: () {
                                  _playPauseMusic(
                                      playlist.url); // Jouer ou mettre en pause
                                },
                              ),
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
                      'https://via.placeholder.com/150',
                    ),
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
