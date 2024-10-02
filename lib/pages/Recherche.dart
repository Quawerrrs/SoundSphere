import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class MusicSearchScreen extends StatefulWidget {
  @override
  _MusicSearchScreenState createState() => _MusicSearchScreenState();
}

class _MusicSearchScreenState extends State<MusicSearchScreen> {
  List<dynamic> _musics = []; // Liste des résultats de recherche
  bool _isLoading = false;
  AudioPlayer _audioPlayer = AudioPlayer(); // Instance du lecteur audio

  // Fonction pour rechercher la musique
  Future<void> _searchMusic(String query) async {
    final url = 'https://api.deezer.com/search?q=$query'; // Construire l'URL
    setState(() {
      _isLoading = true; // Indiquer que la recherche est en cours
    });

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _musics = data['data']; // Stocker les résultats
        });
      } else {
        print('Erreur lors de la récupération des musiques');
      }
    } catch (e) {
      print('Erreur: $e');
    } finally {
      setState(() {
        _isLoading = false; // Fin de la recherche
      });
    }
  }

  // Fonction pour jouer la musique
  void _playMusic(String previewUrl) async {
    await _audioPlayer.play(UrlSource(previewUrl)); // Jouer depuis l'URL
  }

  // Fonction pour arrêter la musique
  void _stopMusic() async {
    await _audioPlayer.stop(); // Pas besoin de stocker un résultat
  }

  @override
  void dispose() {
    _audioPlayer
        .dispose(); // Nettoyer le lecteur audio lors de la fermeture de la page
    super.dispose();
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
                _searchMusic(
                    query); // Appeler la fonction de recherche quand l'utilisateur soumet une requête
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
                        return ListTile(
                          leading: Image.network(
                            music['album']
                                ['cover'], // Afficher la couverture de l'album
                            width: 50,
                            height: 50,
                          ),
                          title: Text(music['title']),
                          subtitle: Text(music['artist']['name']),
                          trailing: IconButton(
                            icon: Icon(Icons.play_arrow),
                            onPressed: () {
                              _playMusic(
                                  music['preview']); // Jouer l'extrait musical
                            },
                          ),
                          onTap: () {
                            print('Lecture de ${music['title']}');
                          },
                        );
                      },
                    ),
                  ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _stopMusic, // Bouton pour arrêter la musique
        child: Icon(Icons.stop),
      ),
    );
  }
}
