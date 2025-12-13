// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

void main() {
  runApp(const AdminDashboard());
}

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ResQ HQ Dashboard',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('ResQ HQ Dashboard'),
          backgroundColor: Colors.orange,
        ),
        body: const DashboardBody(),
      ),
    );
  }
}

class DashboardBody extends StatefulWidget {
  const DashboardBody({super.key});

  @override
  _DashboardBodyState createState() => _DashboardBodyState();
}

class _DashboardBodyState extends State<DashboardBody> {
  final MapController _mapController = MapController();

  double _currentZoom = 7.0;
  LatLng _currentCenter = LatLng(7.8731, 80.7718); // Sri Lanka center

  final List<Map<String, dynamic>> incidentLogs = [
    {
      "no": 1,
      "name": "Christina",
      "location": "Ratnapura",
      "time": "10:42 AM",
      "status": "In Progress",
      "details": {
        "Incident Type": "Landslide",
        "Severity": 2,
        "People Stranded": 5,
        "Requested Aid": ["Trapped Civilians", "Urgent Supply Needs"],
        "Photo": "N/A"
      },
      "lat": 6.705,
      "lng": 80.386
    },
    {
      "no": 2,
      "name": "Sajid",
      "location": "Kegalle",
      "time": "11:15 AM",
      "status": "Escalated",
      "details": {
        "Incident Type": "Flood",
        "Severity": 1,
        "People Stranded": 10,
        "Requested Aid": ["Medical Emergency", "Rescue"],
        "Photo": "N/A"
      },
      "lat": 7.260,
      "lng": 80.340
    },
    {
      "no": 3,
      "name": "Nimal",
      "location": "Galle",
      "time": "11:50 AM",
      "status": "Resolved",
      "details": {
        "Incident Type": "Road Block",
        "Severity": 3,
        "People Stranded": 3,
        "Requested Aid": ["Road Clearance"],
        "Photo": "N/A"
      },
      "lat": 6.032,
      "lng": 80.217
    },
  ];

  Color getStatusColor(String status) {
    switch (status) {
      case "In Progress":
        return Colors.yellow[700]!;
      case "Escalated":
        return Colors.red;
      case "Resolved":
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  void initState() {
    super.initState();
    // Move map to Sri Lanka after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mapController.move(_currentCenter, _currentZoom);
    });
  }

  void _zoomIn() {
    setState(() {
      _currentZoom += 1;
      _mapController.move(_currentCenter, _currentZoom);
    });
  }

  void _zoomOut() {
    setState(() {
      _currentZoom -= 1;
      _mapController.move(_currentCenter, _currentZoom);
    });
  }

  void _showIncidentDetails(Map<String, dynamic> log) {
    if (!mounted) return; // avoid state issues
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Incident Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: log['details'].entries
              .map<Widget>((e) => Text('${e.key}: ${e.value.toString()}'))
              .toList(),
        ),
        actions: [
          TextButton(
              onPressed: () {
                if (mounted) Navigator.pop(context);
              },
              child: const Text('Close'))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Left: Map
        Expanded(
          flex: 3, // slightly bigger map
          child: Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _currentCenter,
                  initialZoom: _currentZoom,
                  minZoom: 6,
                  maxZoom: 12,
                  onTap: (tapPos, point) {},
                  onPositionChanged: (position, hasGesture) {
                    _currentCenter = position.center;
                    _currentZoom = position.zoom;
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                    subdomains: const ['a', 'b', 'c'],
                  ),
                  MarkerLayer(
                    markers: incidentLogs.map((log) {
                      return Marker(
                        point: LatLng(log['lat'], log['lng']),
                        width: 40,
                        height: 40,
                        child: GestureDetector(
                          onTap: () {
                            _showIncidentDetails(log);
                          },
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.red,
                            size: 35,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              // Zoom buttons & current zoom
              Positioned(
                top: 10,
                right: 10,
                child: Column(
                  children: [
                    FloatingActionButton(
                      mini: true,
                      onPressed: _zoomIn,
                      child: const Icon(Icons.add),
                    ),
                    const SizedBox(height: 5),
                    FloatingActionButton(
                      mini: true,
                      onPressed: _zoomOut,
                      child: const Icon(Icons.remove),
                    ),
                    const SizedBox(height: 5),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white70,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.grey),
                      ),
                      child: Text(
                        'Zoom: ${_currentZoom.toStringAsFixed(1)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Right: Incident Logs Table
        Expanded(
          flex: 2, // wider panel
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                Text(
                  'ResQ Incident Logs',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[800]),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: SingleChildScrollView(
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('No')),
                        DataColumn(label: Text('Name')),
                        DataColumn(label: Text('Location')),
                        DataColumn(label: Text('Time')),
                        DataColumn(label: Text('Status')),
                      ],
                      rows: incidentLogs.map((log) {
                        return DataRow(
                          cells: [
                            DataCell(Text(log['no'].toString())),
                            DataCell(Text(log['name'])),
                            DataCell(Text(log['location'])),
                            DataCell(Text(log['time'])),
                            DataCell(Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: getStatusColor(log['status']),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                log['status'],
                                style: const TextStyle(color: Colors.white),
                              ),
                            )),
                          ],
                          onSelectChanged: (_) {
                            _showIncidentDetails(log);
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
