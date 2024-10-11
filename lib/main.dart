import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // For parsing JSON

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ESP8266 LED Control via ThingSpeak',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: LightControlPage(),
    );
  }
}

class LightControlPage extends StatefulWidget {
  const LightControlPage({super.key});

  @override
  _LightControlPageState createState() => _LightControlPageState();
}

class _LightControlPageState extends State<LightControlPage> {
  String status = 'Unknown';
  String writeApiKey =
      'KS5A7INGQGQK7LBS'; // Replace with your ThingSpeak Write API Key
  String readApiKey =
      'HJ7T71IUFCY18Q85'; // ThingSpeak Read API Key for checking LED status
  String thingSpeakUrl = 'https://api.thingspeak.com/update';
  String readUrl = 'https://api.thingspeak.com/channels/2689268/fields/1.json';
  bool isLoading = false; // Loading indicator state

  // Function to turn the LED on via ThingSpeak
  Future<void> turnOnLight() async {
    setState(() {
      isLoading = true; // Set loading to true
    });
    try {
      final response = await http
          .get(Uri.parse('$thingSpeakUrl?api_key=$writeApiKey&field1=1'));
      if (response.statusCode == 200) {
        setState(() {
          status = 'LED is ON';
        });
      } else {
        setState(() {
          status = 'Failed to turn on the LED. Response: ${response.body}';
        });
      }
    } catch (e) {
      setState(() {
        status = 'Error: $e';
      });
    } finally {
      setState(() {
        isLoading = false; // Set loading to false
      });
      fetchLEDStatus(); // Fetch the real-time LED status after the command
    }
  }

  // Function to turn the LED off via ThingSpeak
  Future<void> turnOffLight() async {
    setState(() {
      isLoading = true; // Set loading to true
    });
    try {
      final response = await http
          .get(Uri.parse('$thingSpeakUrl?api_key=$writeApiKey&field1=0'));
      if (response.statusCode == 200) {
        setState(() {
          status = 'LED is OFF';
        });
      } else {
        setState(() {
          status = 'Failed to turn off the LED. Response: ${response.body}';
        });
      }
    } catch (e) {
      setState(() {
        status = 'Error: $e';
      });
    } finally {
      setState(() {
        isLoading = false; // Set loading to false
      });
      fetchLEDStatus(); // Fetch the real-time LED status after the command
    }
  }

  // Function to fetch the real-time LED status from ThingSpeak
  Future<void> fetchLEDStatus() async {
    try {
      final response =
          await http.get(Uri.parse('$readUrl?api_key=$readApiKey&results=1'));
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        if (data['feeds'] != null && data['feeds'].isNotEmpty) {
          var fieldValue = data['feeds'][0]['field1'];
          setState(() {
            status = fieldValue == '1' ? 'LED is ON' : 'LED is OFF';
          });
        } else {
          setState(() {
            status = 'No data found';
          });
        }
      } else {
        setState(() {
          status = 'Failed to fetch LED status. Response: ${response.body}';
        });
      }
    } catch (e) {
      setState(() {
        status = 'Error fetching status: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ESP8266 LED Control via ThingSpeak'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              status,
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 20),
            if (isLoading)
              CircularProgressIndicator(), // Show loading indicator
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed:
                  isLoading ? null : turnOnLight, // Disable button if loading
              child: const Text('Turn On Light'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed:
                  isLoading ? null : turnOffLight, // Disable button if loading
              child: const Text('Turn Off Light'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed:
                  fetchLEDStatus, // Refresh button to manually fetch the LED status
              child: const Text('Check LED Status'),
            ),
          ],
        ),
      ),
    );
  }
}
