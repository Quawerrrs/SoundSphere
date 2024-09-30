import 'package:flutter/material.dart';

class Playlist extends StatefulWidget {
  final String playlistTitle;

  const Playlist({Key? key, required this.playlistTitle}) : super(key: key);

  @override
  _PlaylistState createState() => _PlaylistState();
}

class _PlaylistState extends State<Playlist> {
  String searchQuery = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween, // Espace entre les éléments
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.playlistTitle), // Titre de la playlist
                const SizedBox(height: 4), // Espacement réduit entre le titre et la barre de recherche
                SizedBox(
                  height: 30, // Hauteur de la barre de recherche
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value; // Mettre à jour la requête de recherche
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Rechercher...',
                      filled: true,
                      fillColor: Colors.white,
                      prefixIcon: const Icon(Icons.search, size: 18), // Taille de l'icône
                      contentPadding: const EdgeInsets.symmetric(vertical: 5), // Réduire le padding intérieur
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none, // Pas de bordure
                      ),
                    ),
                  ),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.play_arrow),
              onPressed: () {
                print('Play button pressed');
              },
            ),
          ],
        ),
      ),
      body: Center(
        child: Text('Contenu de la playlist : ${widget.playlistTitle}'),
      ),
    );
  }
}
