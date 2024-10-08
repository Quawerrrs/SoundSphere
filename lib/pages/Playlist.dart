import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Playlist extends StatefulWidget {
  final String playlistName;

  Playlist({required this.playlistName});

  @override
  _PlaylistState createState() => _PlaylistState();
}

class _PlaylistState extends State<Playlist> {
  List<Map<String, String>> _songs = [];
  final User? user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _fetchPlaylistSongs();
  }

  Future<void> _fetchPlaylistSongs() async {
    if (user != null) {
      try {
        DocumentSnapshot playlistDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .collection('playlists')
            .doc(widget.playlistName)
            .get();

        if (playlistDoc.exists) {
          List<dynamic> playlistSongs = playlistDoc['songs'] ?? [];
          setState(() {
            _songs = List<Map<String, String>>.from(
                playlistSongs.map((song) => Map<String, String>.from(song)));
          });
        }
      } catch (e) {
        print(
            'Erreur lors de la récupération des musiques de la playlist : $e');
      }
    }
  }

  void _playSong(String videoId) {
    YoutubePlayerController _controller = YoutubePlayerController(
      initialVideoId: videoId,
      flags: YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
      ),
    );
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: YoutubePlayer(controller: _controller),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Fond noir
      appBar: AppBar(
        title: Text('Playlist: ${widget.playlistName}'),
        backgroundColor: Colors.purple, // Garde la couleur de la barre d'app
      ),
      body: _songs.isEmpty
          ? Center(
              child: Text(
                'Aucune musique dans cette playlist.',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            )
          : ListView.builder(
              itemCount: _songs.length,
              itemBuilder: (context, index) {
                final song = _songs[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 8.0, horizontal: 16.0),
                  child: ListTile(
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    tileColor:
                        Colors.grey[900], // Fond sombre pour les chansons
                    leading: Icon(Icons.music_note, color: Colors.purple),
                    title: Text(
                      song['title'] ?? 'Titre inconnu',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18),
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.play_arrow, color: Colors.purple),
                      onPressed: () {
                        _playSong(song['videoId'] ?? '');
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }
}
