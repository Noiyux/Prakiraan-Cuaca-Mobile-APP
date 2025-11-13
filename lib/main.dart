import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;


// Classes and Data Models
class WeatherData {
  final double currentTemp;
  final int currentCode;
  final double windSpeed;
  final int cloudCover;
  final List<String> dates;
  final List<double> minTemps;
  final List<double> maxTemps;
  final List<int> weatherCodes;

  const WeatherData({
    required this.currentTemp,
    required this.currentCode,
    required this.windSpeed,
    required this.cloudCover,
    required this.dates,
    required this.minTemps,
    required this.maxTemps,
    required this.weatherCodes,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {
        "current": {
          "temperature_2m": num temp,
          "weather_code": int code,
          "wind_speed_10m": num wind,
          "cloud_cover": int cloud
        },
        "daily": {
          "time": List time,
          "temperature_2m_min": List min,
          "temperature_2m_max": List max,
          "weather_code": List wCode
        }
      } =>
        WeatherData(
          currentTemp: temp.toDouble(),
          currentCode: code,
          windSpeed: wind.toDouble(),
          cloudCover: cloud,
          dates: List<String>.from(time.map((x) => x.toString())),
          minTemps: List<double>.from(min.map((x) => (x as num).toDouble())),
          maxTemps: List<double>.from(max.map((x) => (x as num).toDouble())),
          weatherCodes: List<int>.from(wCode.map((x) => x as int)),
        ),
      _ => throw const FormatException('Failed to parse weather data.'),
    };
  }
}

// Fetch weather data from Open-Meteo API
Future<WeatherData> fetchWeather() async {
  const url =
      'https://api.open-meteo.com/v1/forecast?latitude=-8.65&longitude=115.2167&daily=temperature_2m_max,temperature_2m_min,weather_code&current=temperature_2m,weather_code,wind_speed_10m,cloud_cover&timezone=Asia%2FSingapore&forecast_days=7';

  final response = await http.get(Uri.parse(url));

  if (response.statusCode == 200) {
    return WeatherData.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  } else {
    throw Exception('Gagal memuat data cuaca');
  }
}


// HELPER FUNCTIONS
String getEmoji(int code) {
  if ([0, 1].contains(code)) return '☀️';
  if ([2].contains(code)) return '⛅';
  if ([3].contains(code)) return '☁️';
  if ([51, 61, 80].contains(code)) return '🌦️';
  if ([63, 65, 81, 82].contains(code)) return '🌧️';
  if ([95, 96, 99].contains(code)) return '⛈️';
  return '🌫️';
}
String getDescription(int code) {
  if ([0, 1].contains(code)) return 'Cerah';
  if ([2].contains(code)) return 'Sebagian Berawan';
  if ([3].contains(code)) return 'Berawan';
  if ([45, 48].contains(code)) return 'Berkabut';
  if ([51, 61, 80].contains(code)) return 'Gerimis';
  if ([63, 65, 81, 82].contains(code)) return 'Hujan Lebat';
  if ([95, 96, 99].contains(code)) return 'Badai Petir';
  return 'Tidak Diketahui';
}

// UI
void main() => runApp(const WeatherApp());

class WeatherApp extends StatefulWidget {
  const WeatherApp({super.key});

  @override
  State<WeatherApp> createState() => _WeatherAppState();
}

class _WeatherAppState extends State<WeatherApp> {
  late Future<WeatherData> futureWeather;

  @override
  void initState() {
    super.initState();
    futureWeather = fetchWeather();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Perkiraan Cuaca Bali',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightBlue),
      ),
      home: Scaffold(
        //backgroundColor: Colors.blue.shade50,
        appBar: AppBar(
          title: const Text('🌤️ Perkiraan Cuaca Bali',
              style: TextStyle(fontWeight: FontWeight.w600,
                  fontSize: 28)),
          centerTitle: true,
          backgroundColor: Colors.white,
        ),
        body: Center(
          child: FutureBuilder<WeatherData>(
            future: futureWeather,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final data = snapshot.data!;
                return RefreshIndicator(
                  onRefresh: () async => setState(() {
                    futureWeather = fetchWeather();
                  }),
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Header (kota, suhu, kondisi)
                      Column(
                        children: [
                          const Text(
                            'Denpasar',
                            style: TextStyle(
                                fontSize: 26, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 10),
                          Text(getEmoji(data.currentCode),
                              style: const TextStyle(fontSize: 60)),
                          Text(
                            '${data.currentTemp.toStringAsFixed(1)}°C',
                            style: const TextStyle(
                                fontSize: 48, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            getDescription(data.currentCode),
                            style: const TextStyle(fontSize: 18),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.air, color: Colors.blueGrey),
                              Text(
                                  '  Angin: ${data.windSpeed.toStringAsFixed(1)} km/h'),
                              const SizedBox(width: 20),
                              const Icon(Icons.cloud, color: Colors.blueGrey),
                              Text('  Awan: ${data.cloudCover}%'),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Divider(thickness: 3),
                      const SizedBox(height: 10),

                      // Daftar harian
                      ...List.generate(data.dates.length, (index) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 16),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: .05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(data.dates[index],
                                  style: const TextStyle(fontSize: 16)),
                              Row(
                                children: [
                                  Text(getEmoji(data.weatherCodes[index]),
                                      style:
                                          const TextStyle(fontSize: 22)),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${data.minTemps[index].toStringAsFixed(1)}° / ${data.maxTemps[index].toStringAsFixed(1)}°',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                );
              } else if (snapshot.hasError) {
                return Text('${snapshot.error}',
                    style: const TextStyle(color: Colors.red));
              }
              return const CircularProgressIndicator();
            },
          ),
        ),
      ),
    );
  }
}
