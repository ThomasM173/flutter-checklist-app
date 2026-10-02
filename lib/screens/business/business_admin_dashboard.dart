import 'package:flutter/material.dart';
import 'package:clearedtogo/theme/app_colors.dart';
import 'package:intl/intl.dart';

import '../../services/business_admin_service.dart';
import '../../services/supabase_auth_service.dart';

/// business_admin's read-only, platform-wide dashboard. Deliberately
/// simple per spec: totals, an entitlement breakdown, completion counts,
/// and a per-school table. No charts, no write actions - the
/// business_admin_update_profile/_school RPCs added alongside the RLS
/// policies this screen relies on are infrastructure for later, not
/// wired to any UI here.
class BusinessAdminDashboard extends StatefulWidget {
  const BusinessAdminDashboard({super.key});

  @override
  State<BusinessAdminDashboard> createState() => _BusinessAdminDashboardState();
}

class _BusinessAdminDashboardState extends State<BusinessAdminDashboard> {
  final _dateFmt = DateFormat('d MMM yyyy');
  bool _loading = true;
  String? _error;
  BusinessDashboardStats? _stats;

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
    try {
      final stats = await BusinessAdminService().loadStats();
      if (!mounted) return;
      setState(() {
        _stats = stats;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        title: const Text('Business Dashboard',
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
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await SupabaseAuthService().logout();
              if (mounted) {
                Navigator.of(context)
                    .pushNamedAndRemoveUntil('/login', (route) => false);
              }
            },
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 56, color: Colors.red),
              const SizedBox(height: 16),
              Text('Could not load dashboard: $_error',
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }
    final s = _stats!;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                  child: _statCard(
                      'Flight Schools', '${s.totalSchools}', Icons.school)),
              const SizedBox(width: 12),
              Expanded(
                  child: _statCard(
                      'Total Pilots', '${s.totalPilots}', Icons.person)),
            ],
          ),
          const SizedBox(height: 16),
          _sectionTitle('Access Breakdown'),
          _breakdownCard(s),
          const SizedBox(height: 16),
          _sectionTitle('Completions'),
          Row(
            children: [
              Expanded(
                  child: _statCard(
                      'All Time', '${s.totalCompletions}', Icons.fact_check)),
              const SizedBox(width: 12),
              Expanded(
                  child: _statCard('Last 7 Days', '${s.completionsThisWeek}',
                      Icons.date_range)),
              const SizedBox(width: 12),
              Expanded(
                  child: _statCard('Last 30 Days', '${s.completionsThisMonth}',
                      Icons.calendar_month)),
            ],
          ),
          const SizedBox(height: 16),
          _sectionTitle('Flight Schools'),
          _schoolTable(s),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 8, top: 4),
        child: Text(title,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black)),
      );

  Widget _statCard(String label, String value, IconData icon) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF3A7CA5)),
            const SizedBox(height: 8),
            Text(value,
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black)),
            const SizedBox(height: 4),
            Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: Colors.grey[700])),
          ],
        ),
      ),
    );
  }

  Widget _breakdownCard(BusinessDashboardStats s) {
    final rows = [
      ('Comped (via school)', s.compedCount, Colors.purple),
      ('Subscribed', s.subscribedCount, Colors.green),
      ('Trial', s.trialCount, Colors.blue),
      ('No access', s.noAccessCount, Colors.grey),
    ];
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: rows
              .map((r) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                              color: r.$3, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                            child: Text(r.$1,
                                style: const TextStyle(color: Colors.black))),
                        Text('${r.$2}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black)),
                      ],
                    ),
                  ))
              .toList(),
        ),
      ),
    );
  }

  Widget _schoolTable(BusinessDashboardStats s) {
    if (s.perSchool.isEmpty) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Text('No flight schools yet.'),
        ),
      );
    }
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('School')),
            DataColumn(label: Text('Invite Code')),
            DataColumn(label: Text('Pilots')),
            DataColumn(label: Text('Last Active')),
          ],
          rows: s.perSchool
              .map((school) => DataRow(cells: [
                    DataCell(Text(school.name)),
                    DataCell(Text(school.inviteCode ?? '—')),
                    DataCell(Text('${school.pilotCount}')),
                    DataCell(Text(school.lastActive != null
                        ? _dateFmt.format(school.lastActive!)
                        : 'No activity yet')),
                  ]))
              .toList(),
        ),
      ),
    );
  }
}
