import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:resq_admin/Admin/view_respondants_page.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: DashboardBody(),
    );
  }
}

class DashboardBody extends StatefulWidget {
  const DashboardBody({super.key});

  @override
  State<DashboardBody> createState() => _DashboardBodyState();
}

class _DashboardBodyState extends State<DashboardBody> {
  final MapController _mapController = MapController();
  double zoom = 7;
  LatLng center = LatLng(7.8731, 80.7718);

  Color statusColor(String s) {
    if (s == "Escalated") return Colors.red;
    if (s == "Resolved") return Colors.green;
    return Colors.orange;
  }

  void _openReport(DocumentSnapshot r) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(r['incidentType']),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Respondent: ${r['respondentName']}"),
            Text("Location: ${r['location']}"),
            Text("Severity: ${r['severity']}"),
            Text("People Stranded: ${r['peopleStranded']}"),
            Text("Aid: ${(r['requestedAid'] as List).join(", ")}"),
            Text("Status: ${r['status']}"),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("ResQ HQ Dashboard"),
        backgroundColor: Colors.orange,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ViewRespondentsPage()),
              );
            },
            child: const Text(
              "View Respondents",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('reports').snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final reports = snap.data!.docs;

          return Row(
            children: [
              // MAP
              Expanded(
                flex: 3,
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: center,
                    initialZoom: zoom,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                      subdomains: const ['a', 'b', 'c'],
                    ),
                    MarkerLayer(
                      markers: reports.map((r) {
                        return Marker(
                          point: LatLng(r['lat'], r['lng']),
                          width: 40,
                          height: 40,
                          child: GestureDetector(
                            onTap: () => _openReport(r),
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.red,
                              size: 36,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              // TABLE
              Expanded(
                flex: 2,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text("Name")),
                    DataColumn(label: Text("Location")),
                    DataColumn(label: Text("Status")),
                  ],
                  rows: reports.map((r) {
                    return DataRow(
                      onSelectChanged: (_) => _openReport(r),
                      cells: [
                        DataCell(Text(r['respondentName'])),
                        DataCell(Text(r['location'])),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: statusColor(r['status']),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              r['status'],
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}