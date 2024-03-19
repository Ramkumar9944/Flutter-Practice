import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shopping_list/data/categories.dart';

import 'package:shopping_list/models/grocery_item.dart';
import 'package:shopping_list/widgets/new_item.dart';

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  List<GroceryItem> groceryItems = [];
  var isLoading = true;
  String? isError;

  @override
  void initState() {
    super.initState();
    loadItems();
  }

  void loadItems() async {
    final url = Uri.https(
        'flutter-c8dc9-default-rtdb.firebaseio.com', 'shopping_list.json');
    try {
      final response = await http.get(url);

      if (response.statusCode >= 400) {
        setState(() {
          isError = 'Failed to fetch data. Please try again later.';
        });
      }

      if (response.body == 'null') {
        setState(() {
          isLoading = false;
        });
        return;
      }

      final Map<String, dynamic> listData = json.decode(response.body);
      final List<GroceryItem> loadedItems = [];
      for (final item in listData.entries) {
        final category = categories.entries
            .firstWhere(
                (catItem) => catItem.value.title == item.value['category'])
            .value;
        loadedItems.add(
          GroceryItem(
            id: item.key,
            name: item.value['name'],
            quantity: item.value['quantity'],
            category: category,
          ),
        );
      }
      setState(() {
        groceryItems = loadedItems;
        isLoading = false;
      });
    } catch (error) {
      print(error);
      setState(() {
        isError = 'Something went wrong! Please try again later.';
      });
    }
  }

  void addItem() async {
    final newItem = await Navigator.of(context).push<GroceryItem>(
      MaterialPageRoute(
        builder: (ctx) => const NewItem(),
      ),
    );
    if (newItem == null) {
      return;
    }
    setState(() {
      groceryItems.add(newItem);
    });
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text("Grocery added successfully!"),
      duration: Duration(seconds: 3),
    ));
  }

  void removeItem(GroceryItem item) async {
    final itemIndex = groceryItems.indexOf(item);

    // Remove the item from the list temporarily
    setState(() {
      groceryItems.removeAt(itemIndex);
    });

    // Show a SnackBar with an undo option
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text("Grocery removed successfully!"),
      duration: const Duration(seconds: 3),
      action: SnackBarAction(
        label: "Undo",
        onPressed: () {
          // If undo is pressed, re-insert the item into the list
          setState(() {
            groceryItems.insert(itemIndex, item);
          });
        },
      ),
    ));

    // Wait for 3 seconds for the user to press undo
    await Future.delayed(const Duration(seconds: 3));

    // If the item hasn't been re-inserted into the list, delete it from the database
    if (!groceryItems.contains(item)) {
      final url = Uri.https('flutter-c8dc9-default-rtdb.firebaseio.com',
          'shopping_list/${item.id}.json');
      final response = await http.delete(url);
      if (response.statusCode >= 400) {
        // Handle error if needed
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content = const Center(child: Text('No items added yet.'));

    if (groceryItems.isNotEmpty) {
      content = ListView.builder(
        itemCount: groceryItems.length,
        itemBuilder: (ctx, index) => Dismissible(
          background: Container(
            color: Theme.of(context).colorScheme.error.withOpacity(0.5),
          ),
          onDismissed: (direction) {
            removeItem(groceryItems[index]);
          },
          key: ValueKey(groceryItems[index].id),
          child: ListTile(
            title: Text(groceryItems[index].name),
            leading: Container(
              width: 24,
              height: 24,
              color: groceryItems[index].category.color,
            ),
            trailing: Text(
              groceryItems[index].quantity.toString(),
            ),
          ),
        ),
      );
    }

    if (isLoading) {
      content = const Center(child: CircularProgressIndicator());
    }

    if (isError != null) {
      content = Center(child: Text(isError!));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Groceries'),
        actions: [
          IconButton(
            onPressed: addItem,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: content,
    );
  }
}
