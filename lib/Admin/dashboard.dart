import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:resq_admin/Admin/view_respondants_page.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return const DashboardBody();
  }
}

class DashboardBody extends StatefulWidget {
  const DashboardBody({super.key});

  @override
  State<DashboardBody> createState() => _DashboardBodyState();
}

class _DashboardBodyState extends State<DashboardBody> {
  final MapController _mapController = MapController();
  final LatLng center = const LatLng(7.8731, 80.7718); // Sri Lanka
  double zoom = 7;

  Color statusColor(String status) {
    switch (status) {
      case 'Escalated':
        return Colors.red;
      case 'Resolved':
        return Colors.green;
      default:
        return Colors.orange;
    }
  }

  void _openReport(DocumentSnapshot report) {
    final data = report.data() as Map<String, dynamic>;

    final lat = data['location']?['lat'];
    final lng = data['location']?['lng'];

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(data['incidentType'] ?? 'Incident'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (lat != null && lng != null)
                Text('Location: Lat $lat, Lng $lng'),
              Text('People Affected: ${data['numberOfPeople'] ?? '-'}'),
              Text('Severity: ${data['severity'] ?? '-'}'),
              Text('Status: ${data['status'] ?? '-'}'),
              const SizedBox(height: 8),
              const Text(
                'Supply Needs:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              if (data['supplyNeeds'] != null)
                Text(
                  (data['supplyNeeds'] as Map<String, dynamic>)
                      .entries
                      .map((e) => '${e.key}: ${e.value}')
                      .join(', '),
                ),
              const SizedBox(height: 8),
              if (data['createdAt'] != null)
                Text(
                  'Reported At: ${DateFormat('dd MMM yyyy, hh:mm a').format(
                    (data['createdAt'] as Timestamp).toDate(),
                  )}',
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ResQ HQ Dashboard'),
        backgroundColor: Colors.orange,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ViewRespondentsPage(),
                ),
              );
            },
            child: const Text(
              'View Respondents',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('incidents').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final reports = snapshot.data!.docs;

          return Row(
            children: [
              // ================= MAP (LEFT) =================
              Expanded(
                flex: 2,
                child: Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: center,
                        initialZoom: zoom,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                          subdomains: const ['a', 'b', 'c'],
                        ),
                        MarkerLayer(
                          markers: reports
                              .where((r) => r['location'] != null)
                              .map((r) {
                            final loc = r['location'] as Map<String, dynamic>;
                            final lat = (loc['lat'] as num).toDouble();
                            final lng = (loc['lng'] as num).toDouble();

                            return Marker(
                              width: 50,
                              height: 50,
                              point: LatLng(lat, lng),
                              child: GestureDetector(
                                onTap: () {
                                  _mapController.move(
                                    LatLng(lat, lng),
                                    13,
                                  );
                                  _openReport(r);
                                },
                                child: const Icon(
                                  Icons.location_on,
                                  color: Colors.red,
                                  size: 40,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),

                    // Zoom buttons
                    Positioned(
                      right: 12,
                      bottom: 20,
                      child: Column(
                        children: [
                          FloatingActionButton(
                            mini: true,
                            heroTag: 'zoom_in',
                            onPressed: () {
                              zoom++;
                              _mapController.move(center, zoom);
                            },
                            child: const Icon(Icons.add),
                          ),
                          const SizedBox(height: 8),
                          FloatingActionButton(
                            mini: true,
                            heroTag: 'zoom_out',
                            onPressed: () {
                              zoom--;
                              _mapController.move(center, zoom);
                            },
                            child: const Icon(Icons.remove),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ================= TABLE (RIGHT) =================
              // ================= TABLE (RIGHT) =================
Expanded(
  flex: 2,
  child: Padding(
    padding: const EdgeInsets.all(12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Incident Logs',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal, // Allow horizontal scrolling
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(
                    Colors.orange.shade100),
                columns: const [
                  DataColumn(label: Text('No')),
                  DataColumn(label: Text('Location')),
                  DataColumn(label: Text('Incident Type')),
                  DataColumn(label: Text('Time')),
                  DataColumn(label: Text('Status')),
                ],
                rows: List.generate(reports.length, (index) {
                  final r = reports[index];
                  final data = r.data() as Map<String, dynamic>;

                  final loc = data['location'] as Map<String, dynamic>?;

                  return DataRow(
                    onSelectChanged: (_) {
                      if (loc != null) {
                        _mapController.move(
                          LatLng(
                            (loc['lat'] as num).toDouble(),
                            (loc['lng'] as num).toDouble(),
                          ),
                          13,
                        );
                      }
                      _openReport(r);
                    },
                    cells: [
                      DataCell(Text((index + 1).toString())),
                      DataCell(
                        SizedBox(
                          width: 120, // fixed width to avoid overflow
                          child: Text(
                            loc != null
                                ? 'Lat: ${loc['lat']}, Lng: ${loc['lng']}'
                                : '-',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      DataCell(
                        SizedBox(
                          width: 120, // fixed width
                          child: Text(
                            data['incidentType'] ?? '-',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          data['createdAt'] != null
                              ? DateFormat('dd MMM, hh:mm a')
                                  .format((data['createdAt'] as Timestamp)
                                      .toDate())
                              : '-',
                        ),
                      ),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor(data['status'] ?? ''),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            data['status'] ?? '-',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ),
      ],
    ),
  ),
),

            ],
          );
        },
      ),
    );
  }
}
