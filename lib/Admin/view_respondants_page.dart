import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:resq_admin/Admin/add_respondents_page.dart';

class ViewRespondentsPage extends StatelessWidget {
  const ViewRespondentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registered Respondents'),
        backgroundColor: Colors.orange,
      ),

      // Add Respondent Button
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.orange,
        icon: const Icon(Icons.person_add),
        label: const Text("Add Respondent"),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddRespondentPage(),
            ),
          );
        },
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('respondents')
            .orderBy('createdAt', descending: true)
            .snapshots(),

        builder: (context, snapshot) {
          // Loading state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Error state
          if (snapshot.hasError) {
            return const Center(
              child: Text('Error loading respondents'),
            );
          }

          final respondents = snapshot.data!.docs;

          // Empty state
          if (respondents.isEmpty) {
            return const Center(
              child: Text(
                'No respondents registered yet.',
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          // Respondents list
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: respondents.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final respondent = respondents[index];

              return Card(
                elevation: 2,
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.orange,
                    child: Icon(Icons.person, color: Colors.white),
                  ),

                  title: Text(
                    respondent['name'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  subtitle: Text(respondent['email']),

                  // Report count
                  trailing: FutureBuilder<QuerySnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('reports')
                        .where(
                          'respondentId',
                          isEqualTo: respondent.id,
                        )
                        .get(),

                    builder: (context, reportSnapshot) {
                      if (!reportSnapshot.hasData) {
                        return const Text("...");
                      }

                      final count = reportSnapshot.data!.docs.length;

                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            count.toString(),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                          const Text(
                            'Reports',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}