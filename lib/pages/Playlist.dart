import 'package:flutter/material.dart';

class Playlist extends StatefulWidget {
  final String playlistTitle;

  const Playlist({Key? key, required this.playlistTitle}) : super(key: key);

  @override
  _PlaylistState createState() => _PlaylistState();
}

class _PlaylistState extends State<Playlist> {
  String searchQuery = "";
  int numberOfSongs = 20; // Exemple : nombre de titres dans la playlist
  bool isShuffle = false; // Booléen pour déterminer si on lit en mode aléatoire ou dans l'ordre

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.playlistTitle, style: const TextStyle(fontSize: 18)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, // Aligner les éléments à gauche
          children: [
            // Barre de recherche
            SizedBox(
              height: 35,
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Rechercher...',
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.search, size: 18),
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20), // Espacement entre la barre de recherche et les éléments en dessous

            // Texte pour le nombre de titres et les boutons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween, // Espace entre les éléments
              children: [
                Text('Nombre de titres : $numberOfSongs', style: const TextStyle(fontSize: 16)),

                // Boutons Shuffle et Play
                Row(
                  children: [
                    // Bouton pour choisir lecture en ordre ou aléatoire
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          isShuffle = !isShuffle; // Inverser l'état du mode aléatoire
                        });
                        print(isShuffle ? 'Lecture en mode aléatoire' : 'Lecture en ordre');
                      },
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.grey[300], // Couleur gris clair
                          shape: BoxShape.circle, // Forme ronde
                        ),
                        child: Icon(
                          isShuffle ? Icons.shuffle : Icons.format_list_bulleted, // Icône aléatoire ou ordre
                          color: Colors.black,
                          size: 30,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10), // Espacement entre les deux boutons

                    // Bouton Play en bas à droite avec un cercle vert autour
                    GestureDetector(
                      onTap: () {
                        print('Play button pressed');
                        // Action pour lancer la lecture des musiques
                      },
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.green, // Couleur verte
                          shape: BoxShape.circle, // Forme ronde
                        ),
                        child: const Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 20), // Espacement entre les éléments

            // Contenu principal de la playlist
            Center(
              child: Text('Contenu de la playlist : ${widget.playlistTitle}'),
            ),
          ],
        ),
      ),
    );
  }
}
