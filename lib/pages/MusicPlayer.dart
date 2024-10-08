import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class MusicPlayer extends StatelessWidget {
  final String title; // Titre de la chanson
  final String videoId; // ID de la vidéo YouTube

  MusicPlayer({
    required this.title,
    required this.videoId,
  });

  @override
  Widget build(BuildContext context) {
    // Initialise le YoutubePlayerController
    final YoutubePlayerController controller = YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        loop: false,
      ),
    );

    return Scaffold(
      backgroundColor:
          Colors.black, // Fond noir similaire à la page de connexion
      appBar: AppBar(
        title: const Text('Lecteur de Musique'),
        backgroundColor: Colors.purple,
      ),
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            color: Colors
                .white, // Couleur de fond blanche pour correspondre au style
            borderRadius: BorderRadius.circular(10), // Coins arrondis
            boxShadow: [
              BoxShadow(
                color: Colors.blueAccent.withOpacity(0.5), // Ombre bleue
                blurRadius: 20.0,
                spreadRadius: 5.0,
              ),
            ],
          ),
          width: 300, // Largeur similaire au conteneur de la page de connexion
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              // Lecteur YouTube avec bordure et style similaire
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.purpleAccent, width: 2),
                ),
                child: YoutubePlayer(
                  controller: controller,
                  showVideoProgressIndicator: true,
                  progressIndicatorColor: Colors.purple,
                ),
              ),
              const SizedBox(height: 30),
              // Titre de la chanson
              Text(
                title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 30),
              // Ajout d'espace pour d'éventuels contrôles
            ],
          ),
        ),
      ),
    );
  }
}
