import 'dart:math';

import 'package:bubbles_app/constants/bubble_sizes.dart';
import 'package:bubbles_app/models/bubble.dart';
import 'package:bubbles_app/services/database_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:get_it/get_it.dart';
import 'package:latlong2/latlong.dart';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:latlong2/latlong.dart';
import 'dart:async';

class MapPage extends StatefulWidget {
  const MapPage({Key? key}) : super(key: key);

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  late Timer _timer;
  final LatLng _currentLatLng = LatLng(31.808700, 34.654860);

  final DatabaseService _db = GetIt.instance.get<DatabaseService>();

  List<Map<String, dynamic>> _bubblesMarks = [];

  @override
  void initState() {
    super.initState();
    // Start the timer when the widget is initialized
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      _fetchBubbles();
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Color _getRandomColor() {
    final random = Random();
    return Color.fromARGB(
      255,
      random.nextInt(256),
      random.nextInt(256),
      random.nextInt(256),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(child: Text('Map')),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
      ),
      body: _buildMap(),
    );
  }

  Widget _buildMap() {
    var x = _currentLatLng.latitude;
    var y = _currentLatLng.longitude;
    return FlutterMap(
      options:
          MapOptions(zoom: 18, center: LatLng(x, y), maxZoom: 18, minZoom: 18),
      children: [
        _buildTileLayer(),
        _buildMarkerLayer(),
      ],
    );
  }

  TileLayer _buildTileLayer() {
    return TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    );
  }

  MarkerLayer _buildMarkerLayer() {
    List<Marker> markers = [];

    for (var bubble in _bubblesMarks) {
      // double latitude = bubble['location'].latitude;
      // double longitude = bubble['location'].longitude;
      final bubbleColor = [
        Colors.green,
        Colors.lightBlue,
        Colors.purple,
        Colors.red,
        Colors.blue
      ][bubble['keyType']];

      double size =
          BubbleSize.getSizeByIndex(bubble['location'].length)?.markSize ?? 0.0;

      markers.add(
        Marker(
          width: size,
          height: size,
          point: _currentLatLng,
          builder: (ctx) {
            return Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: bubbleColor.withOpacity(0.25),
                  ),
                ),
                Text(
                  bubble['name'],
                  style: TextStyle(
                    color: bubbleColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            );
          },
        ),
      );
    }

    // Add current location marker
    markers.add(
      Marker(
        width: 80.0,
        height: 80.0,
        point: _currentLatLng,
        builder: (ctx) => const Icon(
          Icons.location_on,
          color: Colors.red,
        ),
      ),
    );

    return MarkerLayer(markers: markers);
  }

  Future<void> _fetchBubbles() async {
    List<Map<String, dynamic>> bubbles = await _db.getBubblesFormarks();
    setState(() {
      _bubblesMarks = bubbles;
    });
  }
}