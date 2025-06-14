import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdoptionDisplay extends StatelessWidget {
  const AdoptionDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Animals for Adoption'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('animals').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          // Get list of animals
          final animals = snapshot.data!.docs;

          return GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // Number of columns
              childAspectRatio: 0.8, // Aspect ratio of each item
              crossAxisSpacing: 10.0, // Space between columns
              mainAxisSpacing: 10.0, // Space between rows
            ),
            itemCount: animals.length,
            itemBuilder: (context, index) {
              final animal = animals[index].data() as Map<String, dynamic>;

              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.grey[200],
                ),
                padding: EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    // Display animal image
                    animal['image'] != null
                        ? Image.network(
                            animal['image'],
                            height: 100,
                            width: 100,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            height: 100,
                            width: 100,
                            decoration: BoxDecoration(
                              color: Colors.grey,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child:
                                Icon(Icons.pets, size: 50, color: Colors.white),
                          ),
                    SizedBox(height: 8.0),
                    Text(
                      animal['name'],
                      style: TextStyle(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    Text('Gender: ${animal['gender']}'),
                    Text('Breed: ${animal['breed']}'),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
