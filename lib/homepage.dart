
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_service.dart';
import 'login.dart';
import 'crud.dart';

class HomePage extends StatefulWidget {
  final User user;

  const HomePage({
    super.key,
    required this.user,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final quantityController = TextEditingController();
  final Crud crud = Crud();
  bool showFavOnly = false;

  @override
  void dispose() {
    nameController.dispose();
    quantityController.dispose();
    super.dispose();
  }

  void addItemDialog() {
    nameController.clear();
    quantityController.clear();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Add Item'),

          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    hintText: 'Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Name is required';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 15),

                TextFormField(
                  controller: quantityController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: 'Quantity',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Quantity is required';
                    }

                    if (int.tryParse(value) == null) {
                      return 'Enter a valid number';
                    }

                    if (int.parse(value) < 0) {
                      return 'Quantity cannot be negative';
                    }

                    return null;
                  },
                ),
              ],
            ),
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),

            ElevatedButton(
              onPressed: () async {
                if (!_formKey.currentState!.validate()) {
                  return;
                }

                try {
                  await crud.add(
                    nameController.text.trim(),
                    int.parse(quantityController.text),
                  );

                  if (!mounted) return;

                  Navigator.pop(dialogContext);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Item successfully added!'),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to add item: $e'),
                      
                    ),
                  );

                  print('This is the print error: $e');
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

   void openEditDialog(BuildContext context, DocumentSnapshot item) {
    final data = item.data() as Map<String, dynamic>;
    nameController.text = data['name'];
    quantityController.text = data['quantity'].toString();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: quantityController,
              decoration: InputDecoration(
                labelText: 'Quantity',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty &
                  quantityController.text.isNotEmpty) {
                crud.update(
                  item.id,
                  nameController.text,
                  int.parse(quantityController.text),
                );
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadiusGeometry.circular(8),
              ),
            ),
            child: const Text('Edit'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey,
      appBar: AppBar(
        backgroundColor: Colors.teal,
        title: const Center(
          child: Text('Firebase Aranda'),
        ),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                showFavOnly = !showFavOnly;
              });
            },
            // Icon changes based on filter state
            icon: Icon(
              showFavOnly ? Icons.favorite : Icons.favorite_border,
              color: Colors.white,
            ),
            tooltip: 'Filter Favorites',
          ),
        ],
      ),

      // READ ITEMS FROM FIRESTORE
      body: StreamBuilder<QuerySnapshot>(
        stream: crud.getItems(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('Something went wrong'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final documents = snapshot.data!.docs;

          if (documents.isEmpty) {
            return const Center(
              child: Text('No items found. Add an item!'),
            );
          }

          return ListView.builder(
            itemCount: documents.length,
            itemBuilder: (context, index) {
              final doc = documents[index];
              final data = doc.data() as Map<String, dynamic>;
              bool isFavorite = data.containsKey('is_favorite')
                ? data['is_favorite']
                : false;

              return Card (
                margin: EdgeInsets.fromLTRB(10, 5, 10, 5),
                elevation: 3,
                child: ListTile(
                  title: Text(
                    data['name'] ?? 'Unnamed item',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20
                    ),
                    ),
                  subtitle: Text(
                    'Quantity: ${data['quantity'] ?? 0}',
                  ),


                  trailing: Row (
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                          onPressed: () =>
                              crud.toggleFavorite(doc.id, isFavorite),
                          icon: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: isFavorite ? Colors.red : Colors.grey,
                          ),
                        ),

                      IconButton(
                        icon: const Icon(
                          Icons.edit,
                          color: Colors.yellow,
                        ),
                        onPressed: () => openEditDialog(context, doc),                    
                      ),

                      IconButton(
                        icon: const Icon(
                          Icons.delete,
                          color: Colors.red,
                        ),
                        onPressed: () async {
                          await crud.delete(doc.id);
                        },
                      ),
                    ],
                  )
                ),
              );
            },
          );
        },
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        onPressed: addItemDialog,
        tooltip: 'Add Item',
        child: const Icon(Icons.add),
      ),
    );
  }

  
}
