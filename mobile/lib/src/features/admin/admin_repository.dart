import 'package:supabase_flutter/supabase_flutter.dart';
import '../bookings/models/appointment_model.dart';

class AdminDashboardStats {
  final int pendingBookings;
  final double totalRevenue;
  final List<AppointmentModel> recentActivity;

  AdminDashboardStats({
    required this.pendingBookings,
    required this.totalRevenue,
    required this.recentActivity,
  });
}

class AdminRepository {
  SupabaseClient get _client => Supabase.instance.client;

  Future<AdminDashboardStats> getDashboardStats() async {
    // Fetch pending bookings
    final pendingRes = await _client
        .from('appointments')
        .select('id')
        .eq('status', 'PENDING');

    final pendingCount = (pendingRes as List).length;

    // Fetch total revenue (Sum of estimated_cost for COMPLETED appointments approx)
    final revenueRes = await _client
        .from('appointments')
        .select('estimated_cost, actual_cost, status');

    double totalRevenue = 0.0;
    for (var row in revenueRes as List<dynamic>) {
      // Aggregate either actual or estimated cost
      if (row['status'] != 'CANCELLED') {
        final cost = row['actual_cost'] ?? row['estimated_cost'] ?? 0.0;
        totalRevenue += (cost as num).toDouble();
      }
    }

    // Fetch recent activity
    final recentRes = await _client
        .from('appointments')
        .select('''
          id, profile_id, vehicle_id, service_type, appointment_date,
          status, location, notes, estimated_cost, actual_cost, created_at,
          vehicles ( make, model )
        ''')
        .order('created_at', ascending: false)
        .limit(5);

    final recentActivity = (recentRes as List<dynamic>)
        .map((e) => AppointmentModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return AdminDashboardStats(
      pendingBookings: pendingCount,
      totalRevenue: totalRevenue,
      recentActivity: recentActivity,
    );
  }
}
