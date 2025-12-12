import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/super_admin_service.dart';
import '../state/super_admin_providers.dart';

final homeInfoProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, category) async {
  final svc = ref.watch(superAdminServiceProvider);
  return svc.listHomeInfo(category);
});

class SuperAdminHomeInfoPage extends ConsumerStatefulWidget {
  const SuperAdminHomeInfoPage({super.key});

  @override
  ConsumerState<SuperAdminHomeInfoPage> createState() => _SuperAdminHomeInfoPageState();
}

class _SuperAdminHomeInfoPageState extends ConsumerState<SuperAdminHomeInfoPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _imageUrlController = TextEditingController();
  String? _editingItemId;
  String _currentCategory = 'umrah';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _currentCategory = _tabController.index == 0 ? 'umrah' : 'hajj';
          _resetForm();
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  void _resetForm() {
    _titleController.clear();
    _descriptionController.clear();
    _imageUrlController.clear();
    _editingItemId = null;
  }

  Future<void> _saveInfo() async {
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
      await superSvc.upsertHomeInfo(
        id: _editingItemId,
        category: _currentCategory,
        title: title,
        description: description,
        imageUrl: _imageUrlController.text.trim().isEmpty ? null : _imageUrlController.text.trim(),
      );

      ref.invalidate(homeInfoProvider(_currentCategory));
      _resetForm();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_editingItemId == null ? 'Info created successfully' : 'Info updated successfully')),
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

  Future<void> _deleteInfo(String infoId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this home info?'),
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
        await superSvc.deleteHomeInfo(infoId);
        ref.invalidate(homeInfoProvider(_currentCategory));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Info deleted successfully')),
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

  Widget _buildInfoList(String category) {
    final infoAsync = ref.watch(homeInfoProvider(category));

    return Column(
      children: [
        // Form Card
        Card(
          margin: const EdgeInsets.all(16),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _editingItemId == null ? 'Add ${category.toUpperCase()} Info' : 'Edit ${category.toUpperCase()} Info',
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
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Description *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.description),
                  ),
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
                        onPressed: _saveInfo,
                        icon: Icon(_editingItemId == null ? Icons.add : Icons.save),
                        label: Text(_editingItemId == null ? 'Create Info' : 'Update Info'),
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

        // Info List
        Expanded(
          child: infoAsync.when(
            data: (items) {
              if (items.isEmpty) {
                return Center(
                  child: Text('No ${category} info yet. Create your first item above!'),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: item['image_url'] != null && item['image_url'].toString().isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                item['image_url'],
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(Icons.info, size: 50),
                              ),
                            )
                          : CircleAvatar(
                              backgroundColor: const Color(0xFF1A4363),
                              child: Text(
                                category == 'umrah' ? 'U' : 'H',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                      title: Text(
                        item['title'],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        item['description'],
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
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
                                _imageUrlController.text = item['image_url'] ?? '';
                              });
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteInfo(item['id']),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error: $err')),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Info Management', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1A4363),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Umrah', icon: Icon(Icons.mosque)),
            Tab(text: 'Hajj', icon: Icon(Icons.location_city)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildInfoList('umrah'),
          _buildInfoList('hajj'),
        ],
      ),
    );
  }
}
