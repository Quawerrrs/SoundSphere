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

  @override
  void initState() {
    super.initState();
    _fetchMembers(); // Récupérer les membres depuis Firestore
  }

  void _fetchMembers() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('members').get();
      setState(() {
        members = snapshot.docs;
        filteredMembers = members; // Initialiser la liste filtrée avec tous les membres
      });
    } catch (e) {
      print("Erreur lors de la récupération des membres : $e");
      // Vous pouvez également afficher une alerte ou un message d'erreur à l'utilisateur ici
    }
  }

  void _filterMembers(String query) {
    final filteredList = members.where((member) {
      return member['name'].toString().toLowerCase().contains(query.toLowerCase());
    }).toList();
    setState(() {
      filteredMembers = filteredList;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Membres'),
        backgroundColor: Colors.black,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher un membre...',
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
            child: filteredMembers.isEmpty
                ? const Center(child: CircularProgressIndicator()) // Indicateur de chargement
                : ListView.builder(
                    itemCount: filteredMembers.length,
                    itemBuilder: (context, index) {
                      return Card(
                        color: Colors.grey[850], // Couleur de fond de la carte
                        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        child: ListTile(
                          title: Text(
                            filteredMembers[index]['name'],
                            style: const TextStyle(color: Colors.white),
                          ),
                          subtitle: Text(
                            filteredMembers[index]['email'], // Affichez l'email du membre
                            style: const TextStyle(color: Colors.white70),
                          ),
                          onTap: () {
                            // Action lors du clic sur un membre
                            print('Membre sélectionné : ${filteredMembers[index]['name']}');
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
//test 
//test 