import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/super_admin_service.dart';
import '../state/super_admin_providers.dart';

final exploreItemsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final svc = ref.watch(superAdminServiceProvider);
  return svc.listExploreItems();
});

class SuperAdminExplorePage extends ConsumerStatefulWidget {
  const SuperAdminExplorePage({super.key});

  @override
  ConsumerState<SuperAdminExplorePage> createState() => _SuperAdminExplorePageState();
}

class _SuperAdminExplorePageState extends ConsumerState<SuperAdminExplorePage> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _imageUrlController = TextEditingController();
  String? _editingItemId;
  String? _selectedCity = 'Makkah'; // Default city
  String? _selectedType = 'Hotel'; // Default type

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  void _resetForm() {
    _titleController.clear();
    _descriptionController.clear();
    _latitudeController.clear();
    _longitudeController.clear();
    _imageUrlController.clear();
    _editingItemId = null;
    setState(() {
      _selectedCity = 'Makkah'; // Reset dropdown to default
      _selectedType = 'Hotel'; // Reset dropdown to default
    });
  }

  Future<void> _saveItem() async {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();

    if (title.isEmpty || description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title and description are required')),
      );
      return;
    }

    try {
      final superSvc = ref.read(superAdminServiceProvider);
      
      double? latitude;
      double? longitude;
      if (_latitudeController.text.trim().isNotEmpty) {
        latitude = double.tryParse(_latitudeController.text.trim());
      }
      if (_longitudeController.text.trim().isNotEmpty) {
        longitude = double.tryParse(_longitudeController.text.trim());
      }

      await superSvc.upsertExploreItem(
        id: _editingItemId,
        title: title,
        description: description,
        latitude: latitude,
        longitude: longitude,
        city: _selectedCity,
        type: _selectedType,
        imageUrl: _imageUrlController.text.trim().isEmpty ? null : _imageUrlController.text.trim(),
      );

      ref.invalidate(exploreItemsProvider);
      _resetForm();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_editingItemId == null ? 'Item created successfully' : 'Item updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _deleteItem(String itemId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this explore item?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final superSvc = ref.read(superAdminServiceProvider);
        await superSvc.deleteExploreItem(itemId);
        ref.invalidate(exploreItemsProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Item deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(exploreItemsProvider);
    final viewInsets = MediaQuery.of(context).viewInsets;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                Color(0xFF1A4363),
                Color(0xFF3572A6),
                Color(0xFF67A9D5),
                Color(0xFFA2D0E6),
                Color(0xFFEBF2F6),
              ],
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Explore Management', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      // Use resizeToAvoidBottomInset to prevent the scaffold from resizing,
      // we will handle the padding manually.
      resizeToAvoidBottomInset: false,
      body: Padding(
        // Add padding to the bottom to account for the keyboard height
        padding: EdgeInsets.only(bottom: viewInsets.bottom),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Form Card
              Card(
                margin: const EdgeInsets.all(16),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _editingItemId == null ? 'Add Explore Item' : 'Edit Explore Item',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Title *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.title),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _descriptionController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Description *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.description),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _latitudeController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                              decoration: const InputDecoration(
                                labelText: 'Latitude',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.location_on),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _longitudeController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                              decoration: const InputDecoration(
                                labelText: 'Longitude',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.location_on),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // --- Dropdown for City ---
                      DropdownButtonFormField<String>(
                        value: _selectedCity,
                        decoration: const InputDecoration(
                          labelText: 'City',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.location_city),
                        ),
                        items: ['Makkah', 'Madinah']
                            .map((city) => DropdownMenuItem(
                                  value: city,
                                  child: Text(city),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCity = value;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      // --- Dropdown for Type ---
                      DropdownButtonFormField<String>(
                        value: _selectedType,
                        decoration: const InputDecoration(
                          labelText: 'Type',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.category),
                        ),
                        items: ['Hotel', 'Hospital', 'Restaurant', 'Landmark', 'Other']
                            .map((type) => DropdownMenuItem(
                                  value: type,
                                  child: Text(type),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedType = value;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _imageUrlController,
                        decoration: const InputDecoration(
                          labelText: 'Image URL',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.image),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _saveItem,
                              icon: Icon(_editingItemId == null ? Icons.add : Icons.save),
                              label: Text(_editingItemId == null ? 'Create Item' : 'Update Item'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1A4363),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          if (_editingItemId != null) ...[
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: _resetForm,
                              icon: const Icon(Icons.clear),
                              label: const Text('Cancel'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              const Divider(height: 1, indent: 16, endIndent: 16),
              const SizedBox(height: 16),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Current Explore Items',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const SizedBox(height: 8),

              // Items List
              itemsAsync.when(
                data: (items) {
                  if (items.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Text('No explore items yet. Create one above!'),
                      ),
                    );
                  }
                  // This renders the list inside the scroll view without conflict.
                  return Column(
                    children: items.map((item) {
                      final hasLocation = item['latitude'] != null && item['longitude'] != null;
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: ListTile(
                          leading: item['image_url'] != null && item['image_url'].toString().isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    item['image_url'],
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(Icons.explore, size: 50),
                                  ),
                                )
                              : const CircleAvatar(
                                  backgroundColor: Color(0xFF1A4363),
                                  child: Icon(Icons.explore, color: Colors.white),
                                ),
                          title: Text(
                            item['title'] ?? 'No Title',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['description'] ?? '',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (hasLocation)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text(
                                    '📍 ${item['latitude']}, ${item['longitude']}',
                                    style: const TextStyle(fontSize: 11, color: Colors.blue),
                                  ),
                                ),
                              if (item['city'] != null && item['city'].toString().isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2.0),
                                  child: Text(
                                    '🏙️ ${item['city']}',
                                    style: const TextStyle(fontSize: 11, color: Colors.purple),
                                  ),
                                ),
                              if (item['type'] != null && item['type'].toString().isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2.0),
                                  child: Text(
                                    '🏷️ ${item['type']}',
                                    style: const TextStyle(fontSize: 11, color: Colors.green),
                                  ),
                                ),
                            ],
                          ),
                          isThreeLine: true,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Color(0xFF1A4363)),
                                onPressed: () {
                                  setState(() {
                                    _editingItemId = item['id'];
                                    _titleController.text = item['title'] ?? '';
                                    _descriptionController.text = item['description'] ?? '';
                                    _latitudeController.text = item['latitude']?.toString() ?? '';
                                    _longitudeController.text = item['longitude']?.toString() ?? '';
                                    _selectedCity = item['city'] ?? 'Makkah';
                                    _selectedType = item['type'] ?? 'Hotel';
                                    _imageUrlController.text = item['image_url'] ?? '';
                                  });
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteItem(item['id']),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
                loading: () => const Center(child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                )),
                error: (err, stack) => Center(child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Text('Error: $err'),
                )),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
