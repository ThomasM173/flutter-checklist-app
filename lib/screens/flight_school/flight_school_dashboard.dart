import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import '../../models/flight_school.dart';
import '../../services/supabase_auth_service.dart';
import '../../services/supabase_pdf_service.dart';
import '../../repositories/local_checklist_repository.dart';
import '../completions/school_completions_screen.dart';

/// Flight School Admin Dashboard - landing screen for admins
class FlightSchoolDashboard extends StatefulWidget {
  const FlightSchoolDashboard({super.key});

  @override
  State<FlightSchoolDashboard> createState() => _FlightSchoolDashboardState();
}

class _FlightSchoolDashboardState extends State<FlightSchoolDashboard> {
  final _authService = SupabaseAuthService();
  final _pdfService = SupabasePdfService();
  final _checklistRepo = LocalChecklistRepository();

  int _totalCompletions = 0;
  int _customChecklists = 0;
  FlightSchool? _school;
  bool _loading = true;
  bool _rotatingCode = false;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _loading = true);

    try {
      await _checklistRepo.init();

      final flightSchoolId = _authService.flightSchoolId;
      final school = await _authService.currentFlightSchool();
      if (flightSchoolId != null) {
        final completions = await _pdfService.listSchoolCompletions();
        final checklists =
            await _checklistRepo.getCustomChecklistsBySchool(flightSchoolId);

        setState(() {
          _totalCompletions = completions.length;
          _customChecklists = checklists.length;
          _school = school;
        });
      }
    } catch (e) {
      debugPrint('Error loading dashboard data: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _rotateInviteCode() async {
    setState(() => _rotatingCode = true);
    try {
      final code = await _authService.rotateInviteCode();
      if (mounted) {
        setState(() {
          _school = _school == null
              ? null
              : FlightSchool(
                  id: _school!.id,
                  name: _school!.name,
                  address: _school!.address,
                  phone: _school!.phone,
                  email: _school!.email,
                  inviteCode: code,
                  createdAt: _school!.createdAt,
                );
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('New invite code issued'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to rotate code: $e'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _rotatingCode = false);
    }
  }

  void _copyInviteCode() {
    final code = _school?.inviteCode;
    if (code == null || code.isEmpty) return;
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Invite code copied')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Flight School Portal',
          style: TextStyle(
              fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
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
      ),
      drawer: _buildDrawer(context),
      backgroundColor: Colors.grey[200],
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome header
                  Text(
                    'Welcome, ${user?.fullName ?? "Admin"}',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    user?.email ?? '',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Stats cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Completions',
                          _totalCompletions.toString(),
                          Icons.checklist_rtl,
                          Colors.green,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          'Custom Checklists',
                          _customChecklists.toString(),
                          Icons.checklist,
                          Colors.blue,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Invite code card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.confirmation_number_outlined,
                                color: Color(0xFF3A7CA5)),
                            const SizedBox(width: 8),
                            const Text(
                              'Pilot Invite Code',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Share this code with pilots so they can join your school.',
                          style: TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: Text(
                                  _school?.inviteCode ?? '—',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: _school?.inviteCode == null
                                  ? null
                                  : _copyInviteCode,
                              icon: const Icon(Icons.copy),
                              tooltip: 'Copy code',
                            ),
                            IconButton(
                              onPressed:
                                  _rotatingCode ? null : _rotateInviteCode,
                              icon: _rotatingCode
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                  : const Icon(Icons.refresh),
                              tooltip: 'Rotate code',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Quick actions
                  const Text(
                    'Quick Actions',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildActionButton(
                    'Checklist Completions',
                    'Every pre-boarding checklist your pilots completed',
                    Icons.checklist_rtl,
                    Colors.green,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SchoolCompletionsScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  _buildActionButton(
                    'Edit Checklists',
                    'Customize checklists for your aircraft',
                    Icons.edit_note,
                    Colors.blue,
                    () => Navigator.pushNamed(
                        context, '/flight-school/checklists'),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Container(
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
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFADD8E6), Color(0xFF87CEEB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text(
                  'Flight School',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _authService.currentUser?.fullName ?? 'Admin',
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          _buildDrawerItem(
            context,
            'Dashboard',
            Icons.dashboard,
            '/flight-school/dashboard',
          ),
          _buildDrawerItem(
            context,
            'Checklist Completions',
            Icons.checklist_rtl,
            '/flight-school/completions',
          ),
          _buildDrawerItem(
            context,
            'Edit Checklists',
            Icons.edit_note,
            '/flight-school/checklists',
          ),
          const Divider(color: Colors.black12),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.black),
            title:
                const Text('Sign Out', style: TextStyle(color: Colors.black)),
            onTap: () async {
              await _authService.signOut();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context,
    String title,
    IconData icon,
    String route,
  ) {
    return ListTile(
      leading: Icon(icon, color: Colors.black),
      title: Text(title, style: const TextStyle(color: Colors.black)),
      onTap: () {
        Navigator.pop(context);
        Navigator.pushReplacementNamed(context, route);
      },
    );
  }
}
