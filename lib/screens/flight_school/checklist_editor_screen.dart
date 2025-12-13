import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../services/auth_service_manager.dart';
import '../../repositories/local_checklist_repository.dart';
import '../../models/checklist_models.dart';

/// Checklist Editor screen for flight school admins
class ChecklistEditorScreen extends StatefulWidget {
  const ChecklistEditorScreen({Key? key}) : super(key: key);

  @override
  State<ChecklistEditorScreen> createState() => _ChecklistEditorScreenState();
}

class _ChecklistEditorScreenState extends State<ChecklistEditorScreen> {
  final _authService = AuthServiceManager();
  final _checklistRepo = LocalChecklistRepository();
  final _uuid = const Uuid();
  
  String? _selectedAircraftType;
  ChecklistTemplate? _currentTemplate;
  bool _loading = false;
  bool _hasChanges = false;

  final List<String> _aircraftTypes = ['C152', 'C172', 'PA28'];

  @override
  void initState() {
    super.initState();
    _checklistRepo.init();
  }

  Future<void> _loadChecklist(String aircraftType) async {
    setState(() => _loading = true);
    
    try {
      final flightSchoolId = _authService.flightSchoolId;
      if (flightSchoolId == null) return;
      
      final template = await _checklistRepo.getChecklistTemplate(
        aircraftType: aircraftType,
        flightSchoolId: flightSchoolId,
      );
      
      setState(() {
        if (template != null && template.flightSchoolId == flightSchoolId) {
          // Custom checklist exists
          _currentTemplate = template;
        } else {
          // Create new custom checklist from default
          _currentTemplate = ChecklistTemplate(
            id: _uuid.v4(),
            aircraftType: aircraftType,
            flightSchoolId: flightSchoolId,
            sections: template?.sections ?? [],
          );
        }
        _hasChanges = false;
      });
    } catch (e) {
      print('Error loading checklist: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _saveChecklist() async {
    if (_currentTemplate == null) return;
    
    try {
      await _checklistRepo.saveChecklistTemplate(_currentTemplate!);
      setState(() => _hasChanges = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Checklist saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving checklist: $e')),
        );
      }
    }
  }

  void _addSection() {
    if (_currentTemplate == null) return;
    
    final newSection = ChecklistSection(
      id: _uuid.v4(),
      title: 'New Section',
      order: _currentTemplate!.sections.length + 1,
      items: [],
    );
    
    setState(() {
      _currentTemplate = _currentTemplate!.copyWith(
        sections: [..._currentTemplate!.sections, newSection],
      );
      _hasChanges = true;
    });
  }

  void _deleteSection(ChecklistSection section) {
    if (_currentTemplate == null) return;
    
    setState(() {
      final sections = _currentTemplate!.sections.where((s) => s.id != section.id).toList();
      _currentTemplate = _currentTemplate!.copyWith(sections: sections);
      _hasChanges = true;
    });
  }

  void _updateSection(ChecklistSection oldSection, ChecklistSection newSection) {
    if (_currentTemplate == null) return;
    
    setState(() {
      final sections = _currentTemplate!.sections.map((s) {
        return s.id == oldSection.id ? newSection : s;
      }).toList();
      _currentTemplate = _currentTemplate!.copyWith(sections: sections);
      _hasChanges = true;
    });
  }

  void _addItemToSection(ChecklistSection section) {
    final newItem = ChecklistItem(
      id: _uuid.v4(),
      text: 'New Item',
      order: section.items.length + 1,
    );
    
    final updatedSection = section.copyWith(
      items: [...section.items, newItem],
    );
    
    _updateSection(section, updatedSection);
  }

  void _deleteItem(ChecklistSection section, ChecklistItem item) {
    final updatedSection = section.copyWith(
      items: section.items.where((i) => i.id != item.id).toList(),
    );
    
    _updateSection(section, updatedSection);
  }

  void _updateItem(ChecklistSection section, ChecklistItem oldItem, ChecklistItem newItem) {
    final updatedSection = section.copyWith(
      items: section.items.map((i) => i.id == oldItem.id ? newItem : i).toList(),
    );
    
    _updateSection(section, updatedSection);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Edit Checklists',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFADD8E6), Color(0xFF87CEEB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 4,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          if (_hasChanges)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveChecklist,
              tooltip: 'Save Changes',
            ),
        ],
      ),
      backgroundColor: Colors.grey[200],
      body: Column(
        children: [
          // Aircraft type selector
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: DropdownButtonFormField<String>(
              value: _selectedAircraftType,
              decoration: InputDecoration(
                labelText: 'Select Aircraft Type',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              items: _aircraftTypes.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedAircraftType = value);
                  _loadChecklist(value);
                }
              },
            ),
          ),
          
          // Checklist editor
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _currentTemplate == null
                    ? _buildEmptyState()
                    : _buildChecklistEditor(),
          ),
        ],
      ),
      floatingActionButton: _currentTemplate != null
          ? FloatingActionButton(
              onPressed: _addSection,
              backgroundColor: const Color(0xFF87CEEB),
              child: const Icon(Icons.add, color: Colors.black),
            )
          : null,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.checklist, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Select an aircraft type to edit',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistEditor() {
    if (_currentTemplate == null) return const SizedBox();
    
    return Column(
      children: [
        // Info banner
        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.blue.withOpacity(0.1),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _currentTemplate!.isCustom
                      ? 'Editing custom checklist for ${_currentTemplate!.aircraftType}'
                      : 'Creating new custom checklist based on default',
                  style: const TextStyle(fontSize: 13, color: Colors.blue),
                ),
              ),
            ],
          ),
        ),
        
        // Sections list
        Expanded(
          child: _currentTemplate!.sections.isEmpty
              ? Center(
                  child: Text(
                    'No sections yet. Tap + to add one.',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                )
              : ReorderableListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _currentTemplate!.sections.length,
                  onReorder: (oldIndex, newIndex) {
                    setState(() {
                      if (newIndex > oldIndex) newIndex--;
                      final sections = List<ChecklistSection>.from(_currentTemplate!.sections);
                      final section = sections.removeAt(oldIndex);
                      sections.insert(newIndex, section);
                      
                      // Update order numbers
                      for (int i = 0; i < sections.length; i++) {
                        sections[i] = sections[i].copyWith(order: i + 1);
                      }
                      
                      _currentTemplate = _currentTemplate!.copyWith(sections: sections);
                      _hasChanges = true;
                    });
                  },
                  itemBuilder: (context, index) {
                    final section = _currentTemplate!.sections[index];
                    return _buildSectionCard(section, key: ValueKey(section.id));
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSectionCard(ChecklistSection section, {required Key key}) {
    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: ExpansionTile(
        leading: const Icon(Icons.drag_handle),
        title: InkWell(
          onTap: () => _editSectionTitle(section),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  section.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              Text(
                '${section.items.length} items',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'rename') {
              _editSectionTitle(section);
            } else if (value == 'delete') {
              _confirmDeleteSection(section);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'rename',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 8),
                  Text('Rename'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
        children: [
          ...section.items.map((item) => _buildItemTile(section, item)),
          ListTile(
            leading: const Icon(Icons.add_circle_outline, color: Colors.blue),
            title: const Text('Add Item', style: TextStyle(color: Colors.blue)),
            onTap: () => _addItemToSection(section),
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildItemTile(ChecklistSection section, ChecklistItem item) {
    return ListTile(
      leading: const Icon(Icons.check_box_outline_blank, size: 20),
      title: InkWell(
        onTap: () => _editItemText(section, item),
        child: Text(item.text),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete, color: Colors.red, size: 20),
        onPressed: () => _deleteItem(section, item),
      ),
    );
  }

  Future<void> _editSectionTitle(ChecklistSection section) async {
    final controller = TextEditingController(text: section.title);
    
    final newTitle = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Section Title'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Section Title',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    
    if (newTitle != null && newTitle.isNotEmpty) {
      _updateSection(section, section.copyWith(title: newTitle));
    }
  }

  Future<void> _editItemText(ChecklistSection section, ChecklistItem item) async {
    final controller = TextEditingController(text: item.text);
    
    final newText = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Item'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Item Text',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    
    if (newText != null && newText.isNotEmpty) {
      _updateItem(section, item, item.copyWith(text: newText));
    }
  }

  Future<void> _confirmDeleteSection(ChecklistSection section) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Section'),
        content: Text('Are you sure you want to delete "${section.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      _deleteSection(section);
    }
  }
}
