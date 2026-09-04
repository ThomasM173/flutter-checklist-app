import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';

import '../../models/checklist_completion.dart';
import '../../services/supabase_auth_service.dart';
import '../../services/supabase_pdf_service.dart';

/// Flight-school-admin view of every checklist completion for their school.
/// RLS scopes the rows; this screen adds a pilot-name search + aircraft filter.
class SchoolCompletionsScreen extends StatefulWidget {
  const SchoolCompletionsScreen({super.key});

  @override
  State<SchoolCompletionsScreen> createState() =>
      _SchoolCompletionsScreenState();
}

class _SchoolCompletionsScreenState extends State<SchoolCompletionsScreen> {
  final _auth = SupabaseAuthService();
  final _pdf = SupabasePdfService();
  final _dateFmt = DateFormat('d MMM yyyy · HH:mm');
  final _search = TextEditingController();

  bool _loading = true;
  bool _authorised = false;
  String? _error;
  String? _openingId;
  String _aircraftFilter = 'All aircraft';
  String _typeFilter = 'All types';
  List<ChecklistCompletion> _all = [];

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    await _auth.init();
    _authorised = _auth.isAdmin;
    if (!_authorised) {
      setState(() => _loading = false);
      return;
    }
    try {
      final items = await _pdf.listSchoolCompletions();
      if (!mounted) return;
      setState(() {
        _all = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  List<String> get _aircraftOptions {
    final set = {'All aircraft', ..._all.map((e) => e.aircraftType)};
    return set.toList();
  }

  List<String> get _typeOptions {
    final set = {'All types', ..._all.map((e) => e.completionTypeLabel)};
    return set.toList();
  }

  List<ChecklistCompletion> get _filtered {
    final q = _search.text.trim().toLowerCase();
    return _all.where((c) {
      final matchesAircraft = _aircraftFilter == 'All aircraft' ||
          c.aircraftType == _aircraftFilter;
      final matchesType =
          _typeFilter == 'All types' || c.completionTypeLabel == _typeFilter;
      final matchesSearch = q.isEmpty ||
          (c.pilotName?.toLowerCase().contains(q) ?? false) ||
          c.checklistName.toLowerCase().contains(q);
      return matchesAircraft && matchesType && matchesSearch;
    }).toList();
  }

  Future<void> _open(ChecklistCompletion c) async {
    if (!c.hasPdf) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No PDF was stored for this completion.')),
      );
      return;
    }
    setState(() => _openingId = c.id);
    try {
      final path = await _pdf.downloadPdfToTemp(c);
      final res = await OpenFile.open(path);
      if (res.type != ResultType.done && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open PDF: ${res.message}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to open PDF: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _openingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text('Checklist Completions',
            style: TextStyle(color: Colors.black)),
        iconTheme: const IconThemeData(color: Colors.black),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFADD8E6), Color(0xFF87CEEB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 4,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (!_authorised) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'This area is for flight school admins only.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.black54),
          ),
        ),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.grey),
              const SizedBox(height: 12),
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black54)),
              const SizedBox(height: 12),
              FilledButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    final items = _filtered;
    return Column(
      children: [
        Container(
          color: Colors.grey[100],
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            children: [
              TextField(
                controller: _search,
                decoration: InputDecoration(
                  hintText: 'Search pilot or checklist…',
                  prefixIcon: const Icon(Icons.search),
                  isDense: true,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _aircraftFilter,
                      isDense: true,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      items: _aircraftOptions
                          .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _aircraftFilter = v ?? 'All aircraft'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _typeFilter,
                      isDense: true,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      items: _typeOptions
                          .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _typeFilter = v ?? 'All types'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '${items.length} completion${items.length == 1 ? '' : 's'}',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
          ),
        ),
        Expanded(
          child: items.isEmpty
              ? Center(
                  child: Text(
                    _all.isEmpty
                        ? 'No completions from your pilots yet.'
                        : 'No completions match your filters.',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _card(items[i]),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _card(ChecklistCompletion c) {
    final opening = _openingId == c.id;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: Colors.red[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.picture_as_pdf, color: Colors.red),
        ),
        title: Text(
          c.pilotName?.isNotEmpty == true ? c.pilotName! : 'Unnamed pilot',
          style:
              const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            '${c.completionTypeLabel} · ${c.checklistName} · ${c.aircraftType}\n'
            '${_dateFmt.format(c.completedAt)}'
            '${c.hasPdf ? '' : '  ·  (no PDF)'}',
            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
          ),
        ),
        isThreeLine: true,
        trailing: opening
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.open_in_new, color: Color(0xFF3A7CA5)),
        onTap: opening ? null : () => _open(c),
      ),
    );
  }
}
