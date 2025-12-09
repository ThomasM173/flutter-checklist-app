import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/preflight_systems/pave_assessment_screen.dart';
import 'package:flutter_application_1/screens/preflight_systems/weight_balance_screen.dart';
import 'package:flutter_application_1/screens/preflight_systems/tech_log_screen.dart';
import 'package:flutter_application_1/screens/preflight_systems/fuel_uplift_screen.dart';
import 'package:flutter_application_1/screens/preflight_systems/departure_briefing_screen.dart';
import 'package:flutter_application_1/screens/preflight_systems/passenger_brief_screen.dart';

class PreflightGroundSystemsHub extends StatelessWidget {
  const PreflightGroundSystemsHub({super.key});

  @override
  Widget build(BuildContext context) {
    final systems = [
      {
        'title': 'PAVE & IMSAFE\nRisk Assessment',
        'subtitle': 'Pilot, Aircraft, enVironment, External pressures',
        'icon': Icons.psychology_outlined,
        'color': Colors.purple,
        'screen': const PaveAssessmentScreen(),
      },
      {
        'title': 'Weight & Balance\nLoadsheet',
        'subtitle': 'Calculate W&B, CG envelope, sign-off',
        'icon': Icons.scale_outlined,
        'color': Colors.orange,
        'screen': const WeightBalanceScreen(),
      },
      {
        'title': 'Aircraft Tech Log\nDefects Log',
        'subtitle': 'Record snags, serviceability status',
        'icon': Icons.build_outlined,
        'color': Colors.red,
        'screen': const TechLogScreen(),
      },
      {
        'title': 'Fuel Uplift\nBowser Checks',
        'subtitle': 'Pre-fuel, upload, water checks, total fuel',
        'icon': Icons.local_gas_station_outlined,
        'color': Colors.green,
        'screen': const FuelUpliftScreen(),
      },
      {
        'title': 'Departure Briefing\nThreat & Error Mgmt',
        'subtitle': 'Abort point, engine failure, threats',
        'icon': Icons.flight_takeoff_outlined,
        'color': Colors.blue,
        'screen': const DepartureBriefingScreen(),
      },
      {
        'title': 'Passenger Safety Brief\n& Details Record',
        'subtitle': 'Safety briefing, passenger list, compliance',
        'icon': Icons.airline_seat_recline_normal_outlined,
        'color': Colors.teal,
        'screen': const PassengerBriefScreen(),
      },
    ];

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text(
          "Pre-Flight & Ground Systems",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
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
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: systems.length,
        itemBuilder: (context, index) {
          final system = systems[index];
          return Card(
            elevation: 4,
            color: Colors.white,
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Colors.black, width: 2),
            ),
            child: InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => system['screen'] as Widget),
              ),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.black, width: 1),
                      ),
                      child: Icon(
                        system['icon'] as IconData,
                        size: 32,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            system['title'] as String,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            system['subtitle'] as String,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.black,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
