import 'package:supabase_flutter/supabase_flutter.dart' as sb;

/// Read-only, platform-wide stats for the business_admin dashboard.
/// Relies entirely on the business_admin RLS SELECT policies added in
/// supabase/migrations/20261001100000_flight_school_mandatory.sql (reads
/// every flight_schools/profiles/checklist_completions row, not just the
/// caller's own school) - deliberately no write path here, this service
/// never calls business_admin_update_profile/business_admin_update_school.
class BusinessAdminService {
  BusinessAdminService._();
  static final BusinessAdminService instance = BusinessAdminService._();
  factory BusinessAdminService() => instance;

  sb.SupabaseClient get _client => sb.Supabase.instance.client;

  Future<BusinessDashboardStats> loadStats() async {
    final schoolsRows = await _client
        .from('flight_schools')
        .select('id, name, plan_type');
    final pilotRows = await _client
        .from('profiles')
        .select(
            'id, flight_school_id, subscription_status, subscription_expires_at, trial_ends_at')
        .eq('role', 'pilot');
    final completionRows = await _client
        .from('checklist_completions')
        .select('flight_school_id, completed_at');

    final schools = (schoolsRows as List).cast<Map<String, dynamic>>();
    final pilots = (pilotRows as List).cast<Map<String, dynamic>>();
    final completions = (completionRows as List).cast<Map<String, dynamic>>();

    final now = DateTime.now();
    int comped = 0, subscribed = 0, trial = 0, none = 0;
    final schoolPlanType = {
      for (final s in schools) s['id'] as String: s['plan_type'] as String?,
    };

    for (final p in pilots) {
      final schoolId = p['flight_school_id'] as String?;
      final isCompedSchool = schoolId != null &&
          schoolPlanType[schoolId] == 'comped';
      final subStatus = p['subscription_status'] as String?;
      final subExpires = p['subscription_expires_at'] != null
          ? DateTime.tryParse(p['subscription_expires_at'].toString())
          : null;
      final isSubscribed = subStatus == 'premium' &&
          subExpires != null &&
          subExpires.isAfter(now);
      final trialEnds = p['trial_ends_at'] != null
          ? DateTime.tryParse(p['trial_ends_at'].toString())
          : null;
      final isTrialing = trialEnds != null && trialEnds.isAfter(now);

      // Same priority order has_premium_access() resolves in: comped,
      // then a real subscription, then trial, then nothing.
      if (isCompedSchool) {
        comped++;
      } else if (isSubscribed) {
        subscribed++;
      } else if (isTrialing) {
        trial++;
      } else {
        none++;
      }
    }

    final weekAgo = now.subtract(const Duration(days: 7));
    final monthAgo = now.subtract(const Duration(days: 30));
    int thisWeek = 0, thisMonth = 0;
    final lastActiveBySchool = <String, DateTime>{};
    for (final c in completions) {
      final at = DateTime.tryParse(c['completed_at'].toString());
      if (at == null) continue;
      if (at.isAfter(weekAgo)) thisWeek++;
      if (at.isAfter(monthAgo)) thisMonth++;
      final schoolId = c['flight_school_id'] as String?;
      if (schoolId == null) continue;
      final current = lastActiveBySchool[schoolId];
      if (current == null || at.isAfter(current)) {
        lastActiveBySchool[schoolId] = at;
      }
    }

    final pilotCountBySchool = <String, int>{};
    for (final p in pilots) {
      final schoolId = p['flight_school_id'] as String?;
      if (schoolId == null) continue;
      pilotCountBySchool[schoolId] = (pilotCountBySchool[schoolId] ?? 0) + 1;
    }

    final perSchool = [
      for (final s in schools)
        SchoolSummary(
          name: s['name'] as String,
          pilotCount: pilotCountBySchool[s['id'] as String] ?? 0,
          lastActive: lastActiveBySchool[s['id'] as String],
        ),
    ]..sort((a, b) => b.pilotCount.compareTo(a.pilotCount));

    return BusinessDashboardStats(
      totalSchools: schools.length,
      totalPilots: pilots.length,
      compedCount: comped,
      subscribedCount: subscribed,
      trialCount: trial,
      noAccessCount: none,
      totalCompletions: completions.length,
      completionsThisWeek: thisWeek,
      completionsThisMonth: thisMonth,
      perSchool: perSchool,
    );
  }
}

class BusinessDashboardStats {
  final int totalSchools;
  final int totalPilots;
  final int compedCount;
  final int subscribedCount;
  final int trialCount;
  final int noAccessCount;
  final int totalCompletions;
  final int completionsThisWeek;
  final int completionsThisMonth;
  final List<SchoolSummary> perSchool;

  const BusinessDashboardStats({
    required this.totalSchools,
    required this.totalPilots,
    required this.compedCount,
    required this.subscribedCount,
    required this.trialCount,
    required this.noAccessCount,
    required this.totalCompletions,
    required this.completionsThisWeek,
    required this.completionsThisMonth,
    required this.perSchool,
  });
}

class SchoolSummary {
  final String name;
  final int pilotCount;
  final DateTime? lastActive;
  const SchoolSummary({
    required this.name,
    required this.pilotCount,
    this.lastActive,
  });
}
