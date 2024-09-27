import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MembersPage extends StatefulWidget {
  const MembersPage({super.key});

  @override
  _MembersPageState createState() => _MembersPageState();
}

class _MembersPageState extends State<MembersPage> {
  final TextEditingController _searchController = TextEditingController();
  List<DocumentSnapshot> members = [];
  List<DocumentSnapshot> filteredMembers = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMembers(); // Initialiser la récupération des utilisateurs
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fetchMembers(); // Recharger les utilisateurs chaque fois que la page est affichée
  }

  // Utiliser un stream pour écouter les changements en temps réel dans Firestore
  void _fetchMembers() {
    print("Démarrage de la récupération des utilisateurs...");
    FirebaseFirestore.instance.collection('users').snapshots().listen(
      (snapshot) {
        if (snapshot.docs.isEmpty) {
          print("Aucun utilisateur trouvé dans la collection 'users'.");
        } else {
          for (var doc in snapshot.docs) {
            print(
                "Utilisateur trouvé : ${doc.data()}"); // Affiche les données de chaque utilisateur
          }
        }

        setState(() {
          members = snapshot.docs;
          // Filtrer uniquement les utilisateurs ayant un champ 'pseudo'
          filteredMembers = members.where((member) {
            final data = member.data();
            return data != null &&
                data is Map<String, dynamic> &&
                data.containsKey('pseudo');
          }).toList();
          isLoading = false; // Arrêter l'indicateur de chargement
        });
        print(
            "Récupération des utilisateurs réussie : ${members.length} utilisateurs trouvés.");
      },
      onError: (e) {
        print("Erreur lors de la récupération des utilisateurs : $e");
        setState(() {
          isLoading =
              false; // Arrêter l'indicateur de chargement en cas d'erreur
        });
      },
    );
  }

  void _filterMembers(String query) {
    final filteredList = members.where((member) {
      final data = member.data();
      return data != null &&
          data is Map<String, dynamic> &&
          data.containsKey('pseudo') &&
          data['pseudo'].toString().toLowerCase().contains(query.toLowerCase());
    }).toList();
    setState(() {
      filteredMembers = filteredList;
    });
    print(
        "Utilisateurs filtrés : ${filteredMembers.length} résultats trouvés pour '$query'.");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Utilisateurs'),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed:
                _fetchMembers, // Ajoute un bouton pour rafraîchir manuellement
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher par pseudo...',
                prefixIcon: const Icon(Icons.search, color: Colors.white),
                filled: true,
                fillColor: Colors.grey[800],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
              style: const TextStyle(color: Colors.white),
              onChanged: _filterMembers, // Appel de la fonction de filtrage
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(
                    child:
                        CircularProgressIndicator()) // Indicateur de chargement
                : filteredMembers.isEmpty && _searchController.text.isEmpty
                    ? const Center(
                        child: Text('Aucun utilisateur trouvé.',
                            style: TextStyle(color: Colors.white)))
                    : ListView.builder(
                        itemCount: filteredMembers.length,
                        itemBuilder: (context, index) {
                          final member = filteredMembers[index];
                          final data = member.data()
                              as Map<String, dynamic>; // Conversion explicite
                          return Card(
                            color:
                                Colors.grey[850], // Couleur de fond de la carte
                            margin: const EdgeInsets.symmetric(
                                vertical: 8, horizontal: 16),
                            child: ListTile(
                              title: Text(
                                // Afficher le pseudo de l'utilisateur
                                data['pseudo'] ?? 'Pseudo non disponible',
                                style: const TextStyle(color: Colors.white),
                              ),
                              onTap: () {
                                // Action lors du clic sur un utilisateur
                                print(
                                    'Utilisateur sélectionné avec pseudo : ${data['pseudo']}');
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
