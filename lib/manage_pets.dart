import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pawguard/edit_pet_page.dart';

class ManagePetsPage extends StatefulWidget {
  @override
  _ManagePetsPageState createState() => _ManagePetsPageState();
}

class _ManagePetsPageState extends State<ManagePetsPage> {
  final CollectionReference petsCollection =
      FirebaseFirestore.instance.collection('animals');

  Future<void> _deletePet(String petId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: const Text(
              'Are you sure you want to delete this pet? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await petsCollection.doc(petId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pet deleted successfully!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Pets'),
        backgroundColor: Colors.orange,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: petsCollection.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No pets available.'));
          }

          final pets = snapshot.data!.docs;

          return ListView.builder(
            itemCount: pets.length,
            itemBuilder: (context, index) {
              final pet = pets[index];
              final petData = pet.data() as Map<String, dynamic>;

              return Card(
                child: ListTile(
                  leading: petData['images'] != null &&
                          (petData['images'] as List).isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                         
                        )
                      : const Icon(
                          Icons.image_not_supported,
                          size: 50,
                          color: Colors.grey,
                        ),
                  title: Text(petData['name'] ?? 'Unnamed Pet'),
                  subtitle: Text(
                      '${petData['type'] ?? 'Unknown Type'} - ${petData['breed'] ?? 'Unknown Breed'}'),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'edit') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditPetPage(
                              petId: pet.id,
                              petData: petData,
                            ),
                          ),
                        );
                      } else if (value == 'delete') {
                        await _deletePet(pet.id);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Text('Edit'),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete'),
                      ),
                    ],
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
