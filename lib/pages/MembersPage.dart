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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this); // 4 onglets
    _fetchFriends();
    _fetchMembers();
    _fetchPendingRequests();
    _fetchReceivedRequests(); // Récupérer les demandes reçues
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

    // Récupérer les amis à partir de la collection 'users'
    DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser!.uid)
        .get();
    List<dynamic> friendIds = userSnapshot.data()?['friends'] ?? [];

    setState(() {
      friends = friendIds.map((friendId) => friendId.toString()).toList();
    });
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
        // Ajouter l'ami à la collection 'friends'
        await FirebaseFirestore.instance.collection('friends').add({
          'userId': currentUser.uid,
          'friendId': userId,
          'timestamp': FieldValue.serverTimestamp(),
        });

        // Ajouter l'ID de l'ami à la liste 'friends' de l'utilisateur courant
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .update({
          'friends': FieldValue.arrayUnion([userId])
        });

        // Ajouter l'ID de l'utilisateur courant à la liste 'friends' de l'ami
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .update({
          'friends': FieldValue.arrayUnion([currentUser.uid])
        });

        // Supprimer la demande d'ami
        await FirebaseFirestore.instance
            .collection('friend_requests')
            .doc(requestId)
            .delete();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Demande d'ami acceptée.")),
        );

        // Recharger la liste des amis
        _fetchFriends();

        // Mettre à jour l'état pour supprimer la demande reçue
        setState(() {
          receivedRequests
              .removeWhere((request) => request['requestId'] == requestId);
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

      // Mettre à jour l'état
      setState(() {
        receivedRequests
            .removeWhere((request) => request['requestId'] == requestId);
      });
    } catch (e) {
      print("Erreur lors du refus de la demande : $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erreur lors du refus.")),
      );
    }
  }

  // Fonction pour envoyer une demande d'ami
  void _sendFriendRequest(String userId) async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      try {
        await FirebaseFirestore.instance.collection('friend_requests').add({
          'from': currentUser.uid,
          'to': userId,
          'timestamp': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Demande d'ami envoyée.")),
        );
      } catch (e) {
        print("Erreur lors de l'envoi de la demande : $e");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Erreur lors de l'envoi de la demande.")),
        );
      }
    }
  }

  // Fonction pour filtrer les membres
  void _filterMembers(String query) {
    setState(() {
      filteredMembers = members.where((member) {
        final data = member.data() as Map<String, dynamic>;
        final pseudo = data['pseudo']?.toLowerCase() ?? '';
        return pseudo.contains(query.toLowerCase());
      }).toList();
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
              final friendId = friends[index].id;
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(friendId)
                    .get(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError || !snapshot.hasData) {
                    return const Center(
                        child: Text('Erreur lors de la récupération des amis'));
                  }
                  final friendData =
                      snapshot.data!.data() as Map<String, dynamic>;
                  return ListTile(
                    title:
                        Text(friendData['pseudo'] ?? 'Pseudo non disponible'),
                  );
                },
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
                    labelText: 'Rechercher par pseudo',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: filteredMembers.length,
                  itemBuilder: (context, index) {
                    final memberData =
                        filteredMembers[index].data() as Map<String, dynamic>;
                    final userId = filteredMembers[index].id;

                    return ListTile(
                      title:
                          Text(memberData['pseudo'] ?? 'Pseudo non disponible'),
                      trailing: IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          _sendFriendRequest(userId);
                        },
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
              return ListTile(
                title: Text(request['pseudo']),
                subtitle: const Text('Demande envoyée'),
              );
            },
          ),

          // Onglet Demandes reçues
          ListView.builder(
            itemCount: receivedRequests.length,
            itemBuilder: (context, index) {
              final request = receivedRequests[index];
              return ListTile(
                title: Text(request['pseudo']),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check),
                      onPressed: () {
                        _acceptFriendRequest(
                            request['userId'], request['requestId']);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        _declineFriendRequest(request['requestId']);
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}
