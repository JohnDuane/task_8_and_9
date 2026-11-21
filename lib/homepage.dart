
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

  // ADD ITEM
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
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),

            ElevatedButton(
              onPressed: () async {
                if (!_formKey.currentState!.validate()) return;

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
                  if (!mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to add item: $e'),
                    ),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  // EDIT ITEM
  void openEditDialog(DocumentSnapshot item) {
    final data = item.data() as Map<String, dynamic>;

    nameController.text = data['name'] ?? '';
    quantityController.text =
        (data['quantity'] ?? 0).toString();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Edit Item'),

          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 12),

              TextField(
                controller: quantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Quantity',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),

          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),

            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final quantity =
                    int.tryParse(quantityController.text);

                if (name.isEmpty || quantity == null || quantity < 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Enter a valid name and quantity.'),
                    ),
                  );
                  return;
                }

                try {
                  await crud.update(
                    item.id,
                    name,
                    quantity,
                  );

                  if (!mounted) return;

                  Navigator.pop(dialogContext);
                } catch (e) {
                  if (!mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to update item: $e'),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Edit'),
            ),
          ],
        );
      },
    );
  }

  // TOGGLE FAVORITE
  Future<void> _toggleFavorite(
    String id,
    bool currentStatus,
  ) async {
    try {
      await crud.toggleFavorite(id, currentStatus);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update favorite: $e'),
        ),
      );
    }
  }

  // LOGOUT
  Future<void> _logout() async {
    try {
      await AuthService().signOut();

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => const Login(),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logout failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],

      appBar: AppBar(
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,

        title: const Text('Firebase Aranda'),

        actions: [
          // FAVORITE FILTER
          IconButton(
            onPressed: () {
              setState(() {
                showFavOnly = !showFavOnly;
              });
            },
            icon: Icon(
              showFavOnly
                  ? Icons.favorite
                  : Icons.favorite_border,
              color: Colors.white,
            ),
            tooltip: showFavOnly
                ? 'Show All Items'
                : 'Show Favorites Only',
          ),

          // LOGOUT
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),

      // READ ITEMS
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: crud.getItems(),

        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('Something went wrong.'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final documents = snapshot.data!.docs;

          // FILTER FAVORITES
          final filteredDocuments = showFavOnly
              ? documents.where((doc) {
                  final data = doc.data();

                  return data['is_favorite'] == true;
                }).toList()
              : documents;

          if (filteredDocuments.isEmpty) {
            return Center(
              child: Text(
                showFavOnly
                    ? 'No favorite items found.'
                    : 'No items found. Add an item!',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),
            );
          }

          return ListView.builder(
            itemCount: filteredDocuments.length,

            itemBuilder: (context, index) {
              final doc = filteredDocuments[index];
              final data = doc.data();

              final isFavorite =
                  data['is_favorite'] == true;

              return Card(
                margin: const EdgeInsets.fromLTRB(
                  10, 5, 10, 5,
                ),
                elevation: 3,

                child: ListTile(
                  title: Text(
                    data['name'] ?? 'Unnamed item',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),

                  subtitle: Text(
                    'Quantity: ${data['quantity'] ?? 0}',
                  ),

                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // FAVORITE BUTTON
                      IconButton(
                        onPressed: () {
                          _toggleFavorite(
                            doc.id,
                            isFavorite,
                          );
                        },
                        icon: Icon(
                          isFavorite
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: isFavorite
                              ? Colors.red
                              : Colors.grey,
                        ),
                      ),

                      // EDIT BUTTON
                      IconButton(
                        icon: const Icon(
                          Icons.edit,
                          color: Colors.orange,
                        ),
                        onPressed: () {
                          openEditDialog(doc);
                        },
                      ),

                      // DELETE BUTTON
                      IconButton(
                        icon: const Icon(
                          Icons.delete,
                          color: Colors.red,
                        ),
                        onPressed: () async {
                          try {
                            await crud.delete(doc.id);
                          } catch (e) {
                            if (!mounted) return;

                            ScaffoldMessenger.of(context)
                                .showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Failed to delete item: $e',
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),

      // ADD ITEM BUTTON
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
