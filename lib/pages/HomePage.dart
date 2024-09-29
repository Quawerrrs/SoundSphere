import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Une seule playlist intitulée "Titres likés"
    final String playlistTitle = "Titres likés";

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start, // Aligne les éléments à gauche
          children: [
            Row(
              children: [
                Expanded(
                  flex: 1, // Chaque container occupe 50% de la largeur
                  child: GestureDetector(
                    onTap: () {
                      // Action à effectuer lors du clic sur la playlist
                      print("Clicked on $playlistTitle");
                    },
                    child: Container(
                      height: 60, // Hauteur du bandeau fixée à 60px
                      margin: const EdgeInsets.symmetric(
                          horizontal: 8.0), // Espacement entre les bandeaux
                      decoration: BoxDecoration(
                        color: Colors.blueAccent, // Couleur du bandeau
                        borderRadius:
                            BorderRadius.circular(4), // Bordure arrondie
                      ),
                      child: Center(
                        child: Text(
                          playlistTitle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14, // Taille du texte ajustée
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ),
                // Deuxième conteneur vide, prêt pour une nouvelle playlist
                Expanded(
                  flex: 1,
                  child:
                      Container(), // Un espace vide qui occupe 50% de la largeur
                ),
              ],
            ),
          ],
        ),
      ),
      backgroundColor: Colors.transparent, // Fond transparent
      // Utilisation de transparent dans l'élément Scaffold
    );
  }
}
