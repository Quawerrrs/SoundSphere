import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'MusicPlayer.dart';

class MusicSearchScreen extends StatefulWidget {
  @override
  _MusicSearchScreenState createState() => _MusicSearchScreenState();
}

class _MusicSearchScreenState extends State<MusicSearchScreen> {
  List<dynamic> _musics = [];
  bool _isLoading = false;
  List<String> playlists = [];
  final User? user = FirebaseAuth.instance.currentUser;

  final String _apiKey = 'AIzaSyC_W6fPUm85JrI_ErzbF-1Atrz_RnUWnT8';

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
          });
        }
      } catch (e) {
        print('Erreur lors de la récupération des playlists : $e');
      }
    }
  }

  Future<void> _searchMusic(String query) async {
    final url =
        'https://www.googleapis.com/youtube/v3/search?part=snippet&type=video&q=$query&key=$_apiKey&maxResults=10';

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _musics = data['items'];
        });
      } else {
        print('Erreur lors de la récupération des musiques');
      }
    } catch (e) {
      print('Erreur: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _addToPlaylist(String videoId, String title) {
    showDialog(
      context: context,
      builder: (context) {
        String selectedPlaylist = playlists.isNotEmpty ? playlists[0] : '';
        return AlertDialog(
          title: Text('Ajouter à une playlist'),
          content: DropdownButton<String>(
            value: selectedPlaylist,
            items: playlists.map((playlist) {
              return DropdownMenuItem<String>(
                value: playlist,
                child: Text(playlist),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  selectedPlaylist = value;
                });
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (selectedPlaylist.isNotEmpty) {
                  _addMusicToPlaylist(selectedPlaylist, videoId, title);
                  Navigator.of(context).pop();
                }
              },
              child: Text('Ajouter'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Annuler'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addMusicToPlaylist(
      String playlistName, String videoId, String title) async {
    if (user != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .collection('playlists')
            .doc(playlistName)
            .update({
          'songs': FieldValue.arrayUnion([
            {'videoId': videoId, 'title': title}
          ]),
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('$title ajouté à $playlistName!'),
        ));
      } catch (e) {
        print('Erreur lors de l\'ajout de la musique à la playlist : $e');
      }
    }
  }

  Future<void> _addToLiked(String videoId, String title) async {
    // Ajoutez cette méthode pour ajouter à "Titres likés"
    const String likedPlaylist =
        "Titres likés"; // Le nom de votre playlist "Titres likés"
    await _addMusicToPlaylist(likedPlaylist, videoId, title);
  }

  void _playMusic(String videoId, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MusicPlayer(
          title: title,
          videoId: videoId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Recherche de Musiques'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Rechercher une musique',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (query) {
                _searchMusic(query);
              },
            ),
            SizedBox(height: 20),
            _isLoading
                ? CircularProgressIndicator()
                : Expanded(
                    child: ListView.builder(
                      itemCount: _musics.length,
                      itemBuilder: (context, index) {
                        final music = _musics[index];
                        final videoId = music['id']['videoId'];
                        final title = music['snippet']['title'];
                        final thumbnailUrl =
                            music['snippet']['thumbnails']['default']['url'];
                        final channelTitle = music['snippet']['channelTitle'];

                        return ListTile(
                          leading: Image.network(
                            thumbnailUrl,
                            width: 50,
                            height: 50,
                          ),
                          title: Text(title),
                          subtitle: Text(channelTitle),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.play_arrow),
                                onPressed: () {
                                  _playMusic(videoId, title);
                                },
                              ),
                              IconButton(
                                icon: Icon(Icons.playlist_add),
                                onPressed: () {
                                  _addToPlaylist(videoId, title);
                                },
                              ),
                              IconButton(
                                icon: Icon(Icons
                                    .thumb_up), // Icône pour ajouter à "Titres likés"
                                onPressed: () {
                                  _addToLiked(videoId, title);
                                },
                              ),
                            ],
                          ),
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
