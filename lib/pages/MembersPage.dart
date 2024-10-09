import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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

  // Fonction pour récupérer les utilisateurs de Firestore
  void _fetchMembers() {
    print("Démarrage de la récupération des utilisateurs...");
    FirebaseFirestore.instance.collection('users').snapshots().listen(
      (snapshot) {
        if (snapshot.docs.isEmpty) {
          print("Aucun utilisateur trouvé dans la collection 'users'.");
        } else {
          for (var doc in snapshot.docs) {
            print("Utilisateur trouvé : ${doc.data()}");
          }
        }

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

      // Notification pour l'utilisateur ciblé
      await _sendNotification(userId, "Vous avez reçu une demande d'ami!");

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

  // Fonction pour envoyer une notification via FCM
  Future<void> _sendNotification(String userId, String message) async {
    try {
      // Récupérer le token de notification de l'utilisateur cible
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      String? token = userDoc['fcmToken'];

      if (token == null) {
        print("Aucun token de notification trouvé pour l'utilisateur $userId");
        return;
      }

      // Préparer les données de la notification
      final notificationData = {
        'to': token,
        'notification': {
          'title': 'Nouvelle demande d\'ami',
          'body': message,
        },
        'data': {
          'click_action': 'FLUTTER_NOTIFICATION_CLICK',
        },
      };

      // Envoyer la notification via Firebase Cloud Messaging
      final response = await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization':
              'key=YOUR_SERVER_KEY', // Remplacez par votre clé de serveur FCM
        },
        body: json.encode(notificationData),
      );

      if (response.statusCode == 200) {
        print('Notification envoyée avec succès.');
      } else {
        print('Erreur lors de l\'envoi de la notification : ${response.body}');
      }
    } catch (e) {
      print("Erreur lors de l'envoi de la notification : $e");
    }
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
            onPressed: _fetchMembers,
          ),
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
                          final data = member.data() as Map<String, dynamic>;
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
                              onTap: () {
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
