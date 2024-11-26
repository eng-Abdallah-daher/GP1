import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'dart:math' as Math;

class MapService {
  final String apiKey =
      '5b3ce3597851110001cf62482a1520537959448fb30c5526d252e996'; 

  Future<List<LatLng>> getRoute(LatLng start, LatLng end) async {
    final url =
        'https://api.openrouteservice.org/v2/directions/driving-car/geojson';

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Accept':
            'application/json, application/geo+json, application/gpx+xml, img/png; charset=utf-8',
        'Content-Type': 'application/json',
        'Authorization': apiKey,
      },
      body: jsonEncode({
        'coordinates': [
          [start.longitude, start.latitude],
          [end.longitude, end.latitude]
        ]
      }),
    );

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      var coordinates = data['features'][0]['geometry']['coordinates'];
      List<LatLng> path = [];
      for (var coord in coordinates) {
        path.add(LatLng(coord[1], coord[0]));
      }
      return path;
    } else {
      throw Exception('Failed to load route');
    }
  }
}

void main() {
  runApp(MapPage());
}

class MapPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Advanced Map App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MapScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final GlobalKey<ScaffoldState> _scaffoldKey =
      GlobalKey<ScaffoldState>(); 
  LatLng? currentLocation;
  double currentZoom = 13.0;
  List<LatLng> pathCoordinates = [];
  List<Marker> markers = [];
  final MapService mapService = MapService();
  Marker? lastTappedMarker; 
  final TextEditingController _searchController = TextEditingController();
  String placeDetails = ''; 
  bool _isListening = false;
  String _lastWords = '';
  final background = 'Screenshot 2024-08-15 143537.png';
  stt.SpeechToText _speech = stt.SpeechToText();

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _initSpeech(); 
  }

  void _getCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    setState(() {
      currentLocation = LatLng(position.latitude, position.longitude);
      _mapController.move(currentLocation!, currentZoom);
      markers.add(Marker(
        width: 80.0,
        height: 80.0,
        point: currentLocation!,
        builder: (ctx) => Icon(
          Icons.my_location,
          color: Colors.blue,
          size: 40,
        ),
      ));
    });
  }

  Future<List<String>> _getSearchSuggestions(String query) async {
    final response = await http.get(Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=5'));

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      return List<String>.from(data.map((item) => item['display_name']));
    }
    return [];
  }

  void _searchLocation(String query) async {
    final response = await http.get(Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=1'));

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      if (data.isNotEmpty) {
        double lat = double.parse(data[0]['lat']);
        double lon = double.parse(data[0]['lon']);
        LatLng searchedLocation = LatLng(lat, lon);
        _mapController.move(searchedLocation, currentZoom);

        setState(() {
          markers = [
            Marker(
              width: 80.0,
              height: 80.0,
              point: searchedLocation,
              builder: (ctx) => Icon(
                Icons.location_on,
                color: Colors.green,
                size: 40,
              ),
            ),
            if (lastTappedMarker != null) lastTappedMarker!,
          ];
        });
      }
    }
  }

  void _findNearby(String amenity) async {
    if (currentLocation != null) {
      final response = await http.get(Uri.parse(
          'https://overpass-api.de/api/interpreter?data=[out:json];node[amenity=$amenity](around:5000,${currentLocation!.latitude},${currentLocation!.longitude});out;'));

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);

        List<Marker> foundMarkers = [];
        List<Map<String, dynamic>> sortedElements = [];

        for (var element in data['elements']) {
          double lat = element['lat'];
          double lon = element['lon'];
          LatLng location = LatLng(lat, lon);
          double distance = _calculateDistance(currentLocation!, location);

          sortedElements.add({
            'distance': distance,
            'element': element,
            'location': location,
          });
        }

        sortedElements.sort((a, b) => a['distance'].compareTo(b['distance']));

        if (sortedElements.isNotEmpty) {
          var closest = sortedElements.first['element'];
          LatLng closestLocation = sortedElements.first['location'];

          setState(() {
            markers = [
              Marker(
                width: 80.0,
                height: 80.0,
                point: currentLocation!,
                builder: (ctx) => Icon(
                  Icons.my_location,
                  color: Colors.blue,
                  size: 40,
                ),
              ),
              if (lastTappedMarker != null) lastTappedMarker!,
              Marker(
                width: 80.0,
                height: 80.0,
                point: closestLocation,
                builder: (ctx) => GestureDetector(
                  onTap: () {
                    setState(() {
                      placeDetails = '${closest['tags']['name'] ?? 'Unknown'}';
                    });
                    _scaffoldKey.currentState?.openDrawer();
                  },
                  child: Icon(
                    amenity == 'fuel'
                        ? Icons.local_gas_station
                        : Icons.restaurant,
                    color: amenity == 'fuel' ? Colors.red : Colors.green,
                    size: 40,
                  ),
                ),
              ),
            ];
          });
        }
      }
    }
  }

  double _calculateDistance(LatLng start, LatLng end) {
    const double pi = 3.1415926535897932;
    const double earthRadius = 6371000;

    double lat1 = start.latitude * pi / 180;
    double lon1 = start.longitude * pi / 180;
    double lat2 = end.latitude * pi / 180;
    double lon2 = end.longitude * pi / 180;

    double dLat = lat2 - lat1;
    double dLon = lon2 - lon1;

    double a = (Math.sin(dLat / 2) * Math.sin(dLat / 2)) +
        (Math.cos(lat1) *
            Math.cos(lat2) *
            Math.sin(dLon / 2) *
            Math.sin(dLon / 2));
    double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    double distance = earthRadius * c;

    return distance;
  }

  Future<String> _getPlaceDetails(LatLng latLng) async {
    try {
      final response = await http.get(Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?lat=${latLng.latitude}&lon=${latLng.longitude}&format=json'));

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        return data['display_name'] ?? 'Unknown Place';
      } else {
        return 'Failed to retrieve details';
      }
    } catch (e) {
      print('Error fetching place details: $e');
      return 'Error fetching place details';
    }
  }

  void _showPlaceDetails(LatLng latLng) async {
    String details = await _getPlaceDetails(latLng);
    setState(() {
      placeDetails = details;
    });
  }

  void _drawPath(LatLng destination) async {
    if (currentLocation != null) {
      try {
        List<LatLng> route =
            await mapService.getRoute(currentLocation!, destination);
        setState(() {
          pathCoordinates = route;
          markers = [
            Marker(
              width: 80.0,
              height: 80.0,
              point: currentLocation!,
              builder: (ctx) => Icon(
                Icons.my_location,
                color: Colors.blue,
                size: 40,
              ),
            ),
            Marker(
              width: 80.0,
              height: 80.0,
              point: destination,
              builder: (ctx) => Icon(
                Icons.location_on,
                color: Colors.red,
                size: 40,
              ),
            ),
            if (lastTappedMarker != null) lastTappedMarker!,
          ];
        });
      } catch (e) {
        print(e);
      }
    }
  }

  void _initSpeech() async {
    bool isInitialized = await _speech.initialize();
    if (isInitialized) {
      setState(() {
        _isListening = false;
      });
    }
  }

  void _startListening() async {
    if (_isListening) return;
    await _speech.listen(onResult: (result) {
      setState(() {
        _lastWords = result.recognizedWords;
        _searchController.text = _lastWords; 
      });
      if (_lastWords.isNotEmpty) {
        _searchLocation(_lastWords);
        _speech.stop();
      }
    });
    setState(() {
      _isListening = true;
    });
  }

  void _stopListening() async {
    await _speech.stop();
    setState(() {
      _isListening = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Container(
          padding: EdgeInsets.symmetric(horizontal: 10.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30.0),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.5),
                spreadRadius: 2,
                blurRadius: 7,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(Icons.map, color: Colors.blueAccent),
              Expanded(
                child: TypeAheadField<String>(
                  textFieldConfiguration: TextFieldConfiguration(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Try gas stations, ATMs',
                      border: InputBorder.none,
                    ),
                  ),
                  suggestionsCallback: _getSearchSuggestions,
                  itemBuilder: (context, suggestion) {
                    return ListTile(
                      title: Text(suggestion),
                    );
                  },
                  onSuggestionSelected: (suggestion) {
                    _searchLocation(suggestion);
                  },
                ),
              ),
              IconButton(
                icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
                onPressed: _isListening ? _stopListening : _startListening,
              ),
              CircleAvatar(
                backgroundImage: NetworkImage('../images/' + background),
              ),
            ],
          ),
        ),
      ),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          center: currentLocation ?? LatLng(37.7749, -122.4194),
          zoom: currentZoom,
          onTap: (tapPosition, latLng) {
            setState(() {
              lastTappedMarker = Marker(
                width: 80.0,
                height: 80.0,
                point: latLng,
                builder: (ctx) => Icon(
                  Icons.location_on,
                  color: Colors.red,
                  size: 40,
                ),
              );
              if (lastTappedMarker != null) {
                markers = [
                  ...markers.where((marker) => marker != lastTappedMarker),
                  lastTappedMarker!,
                ];
              }
              _showPlaceDetails(latLng);
              _drawPath(latLng);
              _scaffoldKey.currentState?.openDrawer(); 
            });
          },
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
            subdomains: ['a', 'b', 'c'],
          ),
          MarkerLayer(markers: markers),
          PolylineLayer(
            polylines: [
              Polyline(
                points: pathCoordinates,
                color: Colors.blue,
                strokeWidth: 4.0,
              ),
            ],
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.all(16.0),
          children: [
            Text(
              'Place Details',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
            ),
            SizedBox(height: 16.0),
            if (placeDetails.isNotEmpty)
              Card(
                elevation: 4.0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        leading: Icon(
                          Icons.place,
                          color: Colors.redAccent,
                          size: 40.0,
                        ),
                        title: Text(
                          'Location Name',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18.0,
                          ),
                        ),
                        subtitle: Text(
                          placeDetails,
                          style: TextStyle(
                            fontSize: 16.0,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                      SizedBox(height: 10.0),
                      Text(
                        'Additional Information',
                        style: TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey,
                        ),
                      ),
                      SizedBox(height: 5.0),
                      Text(
                        'More details about this place can be shown here.',
                        style: TextStyle(
                          fontSize: 14.0,
                          color: Colors.grey[700],
                        ),
                      ),
                      SizedBox(height: 10.0),
                      Container(
                        height: 200.0,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12.0),
                          color: Colors.grey[300],
                        ),
                        child: Center(
                          child: Text(
                            'Photo Placeholder',
                            style: TextStyle(
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Center(
                child: Text(
                  'Tap on the map to see details',
                  style: TextStyle(
                    fontSize: 16.0,
                    color: Colors.grey[600],
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'zoomIn',
            onPressed: () {
              setState(() {
                currentZoom += 1;
                _mapController.move(_mapController.center, currentZoom);
              });
            },
            child: Icon(Icons.add),
          ),
          SizedBox(height: 10),
          FloatingActionButton(
            heroTag: 'zoomOut',
            onPressed: () {
              setState(() {
                currentZoom -= 1;
                _mapController.move(_mapController.center, currentZoom);
              });
            },
            child: Icon(Icons.remove),
          ),
          SizedBox(height: 10),
          FloatingActionButton(
            heroTag: 'findGasStations',
            onPressed: () {
              _findNearby('fuel');
            },
            child: Icon(Icons.local_gas_station),
          ),
          SizedBox(height: 10),
          FloatingActionButton(
            heroTag: 'findRestaurants',
            onPressed: () {
              _findNearby('restaurant');
            },
            child: Icon(Icons.restaurant),
          ),
          SizedBox(height: 10),
          FloatingActionButton(
            heroTag: 'currentLocation',
            onPressed: () {
              if (currentLocation != null) {
                _mapController.move(currentLocation!, currentZoom);
              }
              markers.add(Marker(
                width: 80.0,
                height: 80.0,
                point: currentLocation!,
                builder: (ctx) => Icon(
                  Icons.my_location,
                  color: Colors.blue,
                  size: 40,
                ),
              ));
            },
            child: Icon(Icons.my_location),
          ),
        ],
      ),
    );
  }
}