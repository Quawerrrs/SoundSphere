import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MembersPage extends StatefulWidget {
  const MembersPage({super.key});

  @override
  _MembersPageState createState() => _MembersPageState();
}

class _MembersPageState extends State<MembersPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  List<DocumentSnapshot> friends = [];
  List<DocumentSnapshot> members = [];
  List<DocumentSnapshot> filteredMembers = [];
  List<Map<String, dynamic>> pendingRequests = []; // Changement ici
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchFriends();
    _fetchMembers();
    _fetchPendingRequests();
  }

  // Fonction pour récupérer les amis de l'utilisateur
  void _fetchFriends() async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('friends')
          .where('userId', isEqualTo: currentUser.uid)
          .get();

      setState(() {
        friends = snapshot.docs;
      });
    }
  }

  // Fonction pour récupérer les utilisateurs de Firestore
  void _fetchMembers() {
    print("Démarrage de la récupération des utilisateurs...");
    FirebaseFirestore.instance.collection('users').snapshots().listen(
      (snapshot) {
        setState(() {
          members = snapshot.docs;
          filteredMembers = members.where((member) {
            final data = member.data();
            return data != null &&
                data is Map<String, dynamic> &&
                data.containsKey('pseudo');
          }).toList();
          isLoading = false;
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

  // Fonction pour récupérer les demandes d'amis en cours avec les pseudos
  void _fetchPendingRequests() async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('friend_requests')
          .where('from', isEqualTo: currentUser.uid)
          .get();

      List<Map<String, dynamic>> requestsWithPseudos = [];

      for (var request in snapshot.docs) {
        final requestData = request.data() as Map<String, dynamic>;
        final userId = requestData['to'];

        // Récupérer le pseudo de chaque utilisateur lié à la demande
        DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();
        final userData = userSnapshot.data() as Map<String, dynamic>?;

        if (userData != null && userData.containsKey('pseudo')) {
          requestsWithPseudos.add({
            'requestId': request.id, // Ajout de l'ID de la demande
            'userId': userId,
            'pseudo': userData['pseudo'],
          });
        }
      }

      setState(() {
        pendingRequests = requestsWithPseudos;
      });
    }
  }

  // Filtrage des membres en fonction de la recherche par pseudo
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

  // Fonction pour envoyer une demande d'ami
  void _sendFriendRequest(String userId) async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erreur: Utilisateur non connecté.")),
      );
      return;
    }

    try {
      // Ajouter la demande d'ami à la collection "friend_requests"
      await FirebaseFirestore.instance.collection('friend_requests').add({
        'from': currentUser.uid,
        'to': userId,
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Demande d'ami envoyée!")),
      );
    } catch (e) {
      print("Erreur lors de l'envoi de la demande d'ami : $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Erreur lors de l'envoi de la demande d'ami")),
      );
    }
  }

  // Fonction pour supprimer une demande d'ami
  void _deleteFriendRequest(String requestId) async {
    try {
      await FirebaseFirestore.instance
          .collection('friend_requests')
          .doc(requestId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Demande d'ami supprimée.")),
      );

      // Met à jour la liste des demandes après la suppression
      setState(() {
        pendingRequests
            .removeWhere((request) => request['requestId'] == requestId);
      });
    } catch (e) {
      print("Erreur lors de la suppression de la demande d'ami : $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text("Erreur lors de la suppression de la demande d'ami.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Utilisateurs'),
        backgroundColor: Colors.black,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Amis'),
            Tab(text: 'Recherche'),
            Tab(text: 'Demandes en cours'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Onglet Amis
          ListView.builder(
            itemCount: friends.length,
            itemBuilder: (context, index) {
              final friend = friends[index].data() as Map<String, dynamic>;
              return Card(
                color: Colors.grey[850],
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: ListTile(
                  title: Text(
                    friend['pseudo'] ?? 'Pseudo non disponible',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              );
            },
          ),

          // Onglet Recherche
          Column(
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
                  onChanged: _filterMembers,
                ),
              ),
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : filteredMembers.isEmpty && _searchController.text.isEmpty
                        ? const Center(
                            child: Text('Aucun utilisateur trouvé.',
                                style: TextStyle(color: Colors.white)))
                        : ListView.builder(
                            itemCount: filteredMembers.length,
                            itemBuilder: (context, index) {
                              final member = filteredMembers[index];
                              final data =
                                  member.data() as Map<String, dynamic>;
                              return Card(
                                color: Colors.grey[850],
                                margin: const EdgeInsets.symmetric(
                                    vertical: 8, horizontal: 16),
                                child: ListTile(
                                  title: Text(
                                    data['pseudo'] ?? 'Pseudo non disponible',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.person_add,
                                        color: Colors.blue),
                                    onPressed: () {
                                      // Appel de la méthode pour envoyer une demande d'ami
                                      _sendFriendRequest(member.id);
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),

          // Onglet Demandes en cours
          ListView.builder(
            itemCount: pendingRequests.length,
            itemBuilder: (context, index) {
              final request = pendingRequests[index];
              return Card(
                color: Colors.grey[850],
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: ListTile(
                  title: Text(
                    'Demande d\'ami à ${request['pseudo']}',
                    style: const TextStyle(color: Colors.white),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      // Appel de la méthode pour supprimer la demande d'ami
                      _deleteFriendRequest(request['requestId']);
                    },
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
