import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';

import '../../models/checklist_completion.dart';
import '../../services/supabase_auth_service.dart';
import '../../services/supabase_pdf_service.dart';
import '../auth/login_screen.dart';

/// A pilot's own checklist-completion history (Supabase-backed).
/// Replaces the old local-only, fake "My PDFs" screen.
class MyCompletionsScreen extends StatefulWidget {
  const MyCompletionsScreen({super.key});

  @override
  State<MyCompletionsScreen> createState() => _MyCompletionsScreenState();
}

class _MyCompletionsScreenState extends State<MyCompletionsScreen> {
  final _auth = SupabaseAuthService();
  final _pdf = SupabasePdfService();
  final _dateFmt = DateFormat('d MMM yyyy · HH:mm');

  bool _loading = true;
  bool _signedIn = false;
  String? _error;
  String? _openingId;
  String _typeFilter = 'All types';
  List<ChecklistCompletion> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    await _auth.init();
    _signedIn = _auth.isSignedIn;
    if (!_signedIn) {
      setState(() => _loading = false);
      return;
    }
    try {
      final items = await _pdf.listMyCompletions();
      if (!mounted) return;
      setState(() {
        _items = items;
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

  List<String> get _typeOptions {
    final set = {'All types', ..._items.map((e) => e.completionTypeLabel)};
    return set.toList();
  }

  List<ChecklistCompletion> get _filtered {
    if (_typeFilter == 'All types') return _items;
    return _items.where((c) => c.completionTypeLabel == _typeFilter).toList();
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
        title: const Text('My Checklists', style: TextStyle(color: Colors.black)),
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
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (!_signedIn) return _signInPrompt();
    if (_error != null) {
      return _centered(
        icon: Icons.error_outline,
        title: 'Couldn\'t load your checklists',
        subtitle: _error!,
        action: FilledButton(onPressed: _load, child: const Text('Retry')),
      );
    }
    if (_items.isEmpty) {
      return _centered(
        icon: Icons.checklist_rtl,
        title: 'No completed checklists yet',
        subtitle:
            'Finish a pre-boarding checklist and generate its PDF — it will '
            'be saved here and visible to your flight school.',
      );
    }
    final items = _filtered;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: DropdownButtonFormField<String>(
            initialValue: _typeFilter,
            isDense: true,
            decoration: InputDecoration(
              labelText: 'Type',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            items: _typeOptions
                .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                .toList(),
            onChanged: (v) => setState(() => _typeFilter = v ?? 'All types'),
          ),
        ),
        Expanded(
          child: items.isEmpty
              ? Center(
                  child: Text(
                    'No completions match this filter.',
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
          c.checklistName,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            '${c.completionTypeLabel} · ${c.aircraftType}\n${_dateFmt.format(c.completedAt)}'
            '${c.hasPdf ? '' : '  ·  (no PDF)'}',
            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
          ),
        ),
        isThreeLine: true,
        trailing: opening
            ? const SizedBox(
                width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.open_in_new, color: Color(0xFF3A7CA5)),
        onTap: opening ? null : () => _open(c),
      ),
    );
  }

  Widget _centered({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? action,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 72, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600])),
            ],
            if (action != null) ...[const SizedBox(height: 16), action],
          ],
        ),
      ),
    );
  }

  Widget _signInPrompt() {
    return _centered(
      icon: Icons.person_outline,
      title: 'Sign in to see your checklists',
      subtitle:
          'Completed checklists are saved to your account so you — and your '
          'flight school — can review them later.',
      action: ElevatedButton(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
          if (mounted) _load();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF87CEEB),
          foregroundColor: Colors.black,
        ),
        child: const Text('Login / Sign Up'),
      ),
    );
  }
}
