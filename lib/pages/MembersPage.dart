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
  List<Map<String, dynamic>> pendingRequests = []; // Demandes envoyées
  List<Map<String, dynamic>> receivedRequests = []; // Demandes reçues
  bool isLoading = true;
  List<dynamic> friendsList = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this); // 4 onglets
    _fetchFriends();
    _fetchMembers();
    _fetchPendingRequests();
    _fetchReceivedRequests(); // Récupérer les demandes reçues
  }

  // Fonction pour récupérer les amis de l'utilisateur avec leurs pseudos
  void _fetchFriends() async {
  final currentUser = FirebaseAuth.instance.currentUser;

  if (currentUser != null) {
    // Récupérer la liste des amis à partir de Firestore
    DocumentSnapshot currentUserDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .get();

    // Vérification que les données sont bien un Map<String, dynamic>
    if (currentUserDoc.data() != null && currentUserDoc.data() is Map<String, dynamic>) {
      Map<String, dynamic> currentUserData = currentUserDoc.data() as Map<String, dynamic>;

      friendsList = currentUserData['friends'] ?? [];
    }

    List<DocumentSnapshot> fetchedFriends = [];
    for (String friendId in friendsList) {
      DocumentSnapshot friendSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(friendId)
          .get();
      fetchedFriends.add(friendSnapshot);
    }

    setState(() {
      friends = fetchedFriends; // Mettre à jour la liste d'amis avec les documents utilisateurs complets
    });
  }
}


  // Fonction pour récupérer les utilisateurs de Firestore
  void _fetchMembers() {
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
      },
      onError: (e) {
        setState(() {
          isLoading = false;
        });
      },
    );
  }

  // Fonction pour récupérer les demandes d'amis envoyées
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

        DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();
        final userData = userSnapshot.data() as Map<String, dynamic>?;

        if (userData != null && userData.containsKey('pseudo')) {
          requestsWithPseudos.add({
            'requestId': request.id,
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

  // Fonction pour récupérer les demandes d'amis reçues
  void _fetchReceivedRequests() async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('friend_requests')
          .where('to', isEqualTo: currentUser.uid)
          .get();

      List<Map<String, dynamic>> requestsWithPseudos = [];

      for (var request in snapshot.docs) {
        final requestData = request.data() as Map<String, dynamic>;
        final userId = requestData['from'];

        DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();
        final userData = userSnapshot.data() as Map<String, dynamic>?;

        if (userData != null && userData.containsKey('pseudo')) {
          requestsWithPseudos.add({
            'requestId': request.id,
            'userId': userId,
            'pseudo': userData['pseudo'],
          });
        }
      }

      setState(() {
        receivedRequests = requestsWithPseudos;
      });
    }
  }

  // Fonction pour accepter une demande d'ami
  void _acceptFriendRequest(String userId, String requestId) async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      try {
        // Ajouter l'ami à la collection 'friends' de l'utilisateur actuel
        await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).update({
          'friends': FieldValue.arrayUnion([userId]),
        });

        // Ajouter l'utilisateur actuel dans la liste des amis de l'autre utilisateur
        await FirebaseFirestore.instance.collection('users').doc(userId).update({
          'friends': FieldValue.arrayUnion([currentUser.uid]),
        });

        // Supprimer la demande d'ami
        await FirebaseFirestore.instance
            .collection('friend_requests')
            .doc(requestId)
            .delete();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Demande d'ami acceptée.")),
        );

        // Mettre à jour l'état
        setState(() {
          receivedRequests.removeWhere((request) => request['requestId'] == requestId);
          _fetchFriends(); // Rafraîchir la liste d'amis
        });
      } catch (e) {
        print("Erreur lors de l'acceptation de la demande : $e");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Erreur lors de l'acceptation.")),
        );
      }
    }
  }

  // Fonction pour refuser une demande d'ami
  void _declineFriendRequest(String requestId) async {
    try {
      await FirebaseFirestore.instance
          .collection('friend_requests')
          .doc(requestId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Demande d'ami refusée.")),
      );

      setState(() {
        receivedRequests.removeWhere((request) => request['requestId'] == requestId);
      });
    } catch (e) {
      print("Erreur lors du refus de la demande : $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erreur lors du refus.")),
      );
    }
  }

  // Fonction pour filtrer les membres (recherche)
  void _filterMembers(String query) {
    setState(() {
      filteredMembers = members.where((member) {
        final data = member.data() as Map<String, dynamic>;
        final pseudo = data['pseudo']?.toLowerCase() ?? '';
        return pseudo.contains(query.toLowerCase()) &&
            !friendsList.contains(member.id); // Vérifie si déjà ami
      }).toList();
    });
  }

  // Fonction pour envoyer une demande d'ami
  void _sendFriendRequest(String userId) async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      await FirebaseFirestore.instance.collection('friend_requests').add({
        'from': currentUser.uid,
        'to': userId,
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Demande d'ami envoyée.")),
      );
    }
  }

  // Fonction pour supprimer une demande d'ami envoyée
  void _deleteFriendRequest(String requestId) async {
    await FirebaseFirestore.instance.collection('friend_requests').doc(requestId).delete();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Demande d'ami annulée.")),
    );

    setState(() {
      pendingRequests.removeWhere((request) => request['requestId'] == requestId);
    });
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
            Tab(text: 'Demandes reçues'), // Onglet pour les demandes reçues
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
              final friendData = friends[index].data() as Map<String, dynamic>;

              return Card(
                color: Colors.grey[850],
                margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                child: ListTile(
                  title: Text(
                    friendData['pseudo'] ?? 'Pseudo non disponible',
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
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: _searchController,
                  onChanged: _filterMembers,
                  decoration: const InputDecoration(
                    labelText: 'Rechercher des utilisateurs...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        itemCount: filteredMembers.length,
                        itemBuilder: (context, index) {
                          final memberData = filteredMembers[index].data()
                              as Map<String, dynamic>;

                          return Card(
                            color: Colors.grey[850],
                            margin: const EdgeInsets.symmetric(
                                vertical: 5, horizontal: 10),
                            child: ListTile(
                              title: Text(
                                memberData['pseudo'] ?? 'Pseudo non disponible',
                                style: const TextStyle(color: Colors.white),
                              ),
                              trailing: friendsList.contains(filteredMembers[index].id)
                                  ? const Text(
                                      'Ami',
                                      style: TextStyle(color: Colors.green),
                                    )
                                  : IconButton(
                                      icon: const Icon(Icons.person_add,
                                          color: Colors.white),
                                      onPressed: () {
                                        _sendFriendRequest(
                                            filteredMembers[index].id);
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
                margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                child: ListTile(
                  title: Text(
                    request['pseudo'] ?? 'Pseudo non disponible',
                    style: const TextStyle(color: Colors.white),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.cancel, color: Colors.red),
                    onPressed: () {
                      _deleteFriendRequest(request['requestId']);
                    },
                  ),
                ),
              );
            },
          ),

          // Onglet Demandes reçues
          ListView.builder(
            itemCount: receivedRequests.length,
            itemBuilder: (context, index) {
              final request = receivedRequests[index];

              return Card(
                color: Colors.grey[850],
                margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                child: ListTile(
                  title: Text(
                    request['pseudo'] ?? 'Pseudo non disponible',
                    style: const TextStyle(color: Colors.white),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),
                        onPressed: () {
                          _acceptFriendRequest(
                              request['userId'], request['requestId']);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.red),
                        onPressed: () {
                          _declineFriendRequest(request['requestId']);
                        },
                      ),
                    ],
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
