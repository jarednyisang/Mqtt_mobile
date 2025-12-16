import 'package:flutter/material.dart';
import 'package:surveyhub/utils/AppColors.dart';
import 'package:surveyhub/utils/CustomBottomNavBar.dart';
import 'package:surveyhub/utils/BaseUrl.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class HomeScreen extends StatefulWidget {
  final int pid;
  final String fullname;
  final String code;
  final String emailaddress;

  const HomeScreen({
    super.key,
    required this.pid,
    required this.fullname,
    required this.code, 
    required this.emailaddress,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late MqttServerClient _mqttClient;
  bool _isConnected = false;
  bool _isLoading = true;
  
  // Real-time data from MQTT
  Map<String, dynamic> _batteryData = {
    'voltage': '12.6V',
    'status': 'Optimal',
    'temperature': '25°C',
  };
  
  Map<String, dynamic> _solarData = {
    'power': '0kW',
    'efficiency': '0%',
    'status': 'Offline',
  };
  
  List<String> _notifications = [];

  @override
  void initState() {
    super.initState();
    _connectToMqtt();
  }

  Future<void> _connectToMqtt() async {
    // Configure MQTT client
    _mqttClient = MqttServerClient('broker.hivemq.com', 'chloride_${widget.pid}');
    _mqttClient.port = 8884;
    _mqttClient.keepAlivePeriod = 60;
    _mqttClient.autoReconnect = true;
    _mqttClient.logging(on: false);

    final connMessage = MqttConnectMessage()
        .withClientIdentifier('chloride_${widget.pid}')
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);

    _mqttClient.connectionMessage = connMessage;

    try {
      await _mqttClient.connect();
      
      if (_mqttClient.connectionStatus!.state == MqttConnectionState.connected) {
        setState(() {
          _isConnected = true;
          _isLoading = false;
        });

        // Subscribe to Chloride Exide topics
        _mqttClient.subscribe('chloride/batteries/status', MqttQos.atLeastOnce);
        _mqttClient.subscribe('chloride/solar/data', MqttQos.atLeastOnce);
        _mqttClient.subscribe('chloride/notifications', MqttQos.atLeastOnce);
        _mqttClient.subscribe('chloride/user/${widget.pid}/alerts', MqttQos.atLeastOnce);

        // Listen to incoming messages
        _mqttClient.updates!.listen((List<MqttReceivedMessage<MqttMessage>> messages) {
          final message = messages[0].payload as MqttPublishMessage;
          final topic = messages[0].topic;
          final payload = MqttPublishPayload.bytesToStringAsString(message.payload.message);
          
          _handleMessage(topic, payload);
        });

        print('✅ Connected to MQTT Broker');
      }
    } catch (e) {
      print('❌ MQTT Connection Error: $e');
      setState(() {
        _isLoading = false;
        _isConnected = false;
      });
    }
  }

  void _handleMessage(String topic, String payload) {
    try {
      final data = jsonDecode(payload);
      
      setState(() {
        if (topic.contains('batteries/status')) {
          _batteryData = {
            'voltage': data['voltage'] ?? '12.6V',
            'status': data['status'] ?? 'Optimal',
            'temperature': data['temperature'] ?? '25°C',
          };
        } else if (topic.contains('solar/data')) {
          _solarData = {
            'power': data['power'] ?? '0kW',
            'efficiency': data['efficiency'] ?? '0%',
            'status': data['status'] ?? 'Offline',
          };
        } else if (topic.contains('notifications') || topic.contains('alerts')) {
          String notification = data['message'] ?? data['alert'] ?? payload;
          _notifications.insert(0, notification);
          if (_notifications.length > 10) _notifications.removeLast();
          
          _showSnackBar(notification);
        }
      });
    } catch (e) {
      print('Error parsing message: $e');
    }
  }

  // Fetch data from Laravel backend and publish to MQTT
  Future<void> _fetchAndPublishData() async {
    if (!_isConnected) {
      _showSnackBar('Not connected to MQTT', isError: true);
      return;
    }

    try {
      // Call Laravel API to simulate/fetch data
      final url = Uri.parse('${BaseUrl.SIMULATE}');
      
      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success']) {
          _showSnackBar('Data fetched from Laravel backend');
          
          // The backend already published to MQTT, 
          // but we can also update UI immediately
          if (data['battery'] != null) {
            setState(() {
              _batteryData = {
                'voltage': data['battery']['voltage'] ?? '12.6V',
                'status': data['battery']['status'] ?? 'Optimal',
                'temperature': data['battery']['temperature'] ?? '25°C',
              };
            });
          }
          
          if (data['solar'] != null) {
            setState(() {
              _solarData = {
                'power': data['solar']['power'] ?? '0kW',
                'efficiency': data['solar']['efficiency'] ?? '0%',
                'status': data['solar']['status'] ?? 'Offline',
              };
            });
          }
        } else {
          _showSnackBar('Failed to fetch data', isError: true);
        }
      } else {
        _showSnackBar('Server error: ${response.statusCode}', isError: true);
      }
    } catch (e) {
      print('Error fetching data: $e');
      _showSnackBar('Error: ${e.toString()}', isError: true);
    }
  }

  // Update battery status via Laravel backend
  Future<void> _updateBatteryStatus(String voltage, String status, String temperature) async {
    try {
      final url = Uri.parse('${BaseUrl.BATTERY_UPDATE}');
      
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'voltage': voltage,
          'status': status,
          'temperature': temperature,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          _showSnackBar('Battery status updated');
        }
      }
    } catch (e) {
      print('Error updating battery: $e');
      _showSnackBar('Error updating battery', isError: true);
    }
  }

  // Update solar data via Laravel backend
  Future<void> _updateSolarData(String power, String efficiency, String status) async {
    try {
      final url = Uri.parse('${BaseUrl.SOLAR_UPDATE}');
      
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'power': power,
          'efficiency': efficiency,
          'status': status,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          _showSnackBar('Solar data updated');
        }
      }
    } catch (e) {
      print('Error updating solar: $e');
      _showSnackBar('Error updating solar', isError: true);
    }
  }

  // Send notification via Laravel backend
  Future<void> _sendNotification(String message) async {
    try {
      final url = Uri.parse('${BaseUrl.NOTIFICATIONS}');
      
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'message': message,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          _showSnackBar('Notification sent to all users');
        }
      }
    } catch (e) {
      print('Error sending notification: $e');
      _showSnackBar('Error sending notification', isError: true);
    }
  }

  @override
  void dispose() {
    _mqttClient.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SafeArea(
              child: CustomScrollView(
                slivers: [
                  _buildAppBar(),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildConnectionStatus(),
                          const SizedBox(height: 16),
                          _buildLiveDataSection(),
                          const SizedBox(height: 16),
                          _buildCategoryGrid(),
                          const SizedBox(height: 16),
                          _buildNotificationsSection(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: 0,
        fullname: widget.fullname,
        code: widget.code,
        userpid: widget.pid,
        emailaddress: widget.emailaddress,
      ),
      floatingActionButton: _isConnected
          ? FloatingActionButton(
              onPressed: _fetchAndPublishData,
              backgroundColor: AppColors.primary,
              tooltip: 'Fetch data from Laravel',
              child: Icon(Icons.cloud_sync, color: AppColors.white),
            )
          : null,
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.primary,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.secondary],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome back,',
                              style: TextStyle(
                                color: AppColors.white.withOpacity(0.9),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.fullname,
                              style: TextStyle(
                                color: AppColors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        _isConnected ? Icons.cloud_done : Icons.cloud_off,
                        color: AppColors.white,
                        size: 28,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConnectionStatus() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isConnected ? AppColors.green600 : AppColors.red600,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            _isConnected ? Icons.wifi : Icons.wifi_off,
            color: AppColors.white,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isConnected ? 'Connected to MQTT Broker' : 'Disconnected from MQTT',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (_isConnected)
                  Text(
                    'Receiving live data from Laravel backend',
                    style: TextStyle(
                      color: AppColors.white.withOpacity(0.9),
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveDataSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Live Monitoring',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.grey700,
              ),
            ),
            TextButton.icon(
              onPressed: _fetchAndPublishData,
              icon: Icon(Icons.refresh, size: 16, color: AppColors.primary),
              label: Text(
                'Refresh',
                style: TextStyle(color: AppColors.primary, fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildLiveDataCard(
                'Battery Status',
                Icons.battery_charging_full,
                _batteryData['voltage'],
                _batteryData['status'],
                AppColors.green600,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildLiveDataCard(
                'Solar Power',
                Icons.wb_sunny,
                _solarData['power'],
                _solarData['status'],
                Colors.orange.shade600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLiveDataCard(String title, IconData icon, String value, String status, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.grey700,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryGrid() {
    final categories = [
      {
        'icon': Icons.directions_car,
        'label': 'Automotive Batteries',
        'value': 'See more',
        'color': AppColors.primary,
      },
      {
        'icon': Icons.battery_charging_full,
        'label': 'Energy Storage',
        'value': 'See more',
        'color': AppColors.green600,
      },
      {
        'icon': Icons.wb_sunny,
        'label': 'Solar Energy',
        'value': 'See more',
        'color': Colors.orange.shade600,
      },
      {
        'icon': Icons.water_drop,
        'label': 'Water Heating',
        'value': 'See more',
        'color': Colors.blue.shade600,
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.4,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return _buildCategoryCard(
          icon: category['icon'] as IconData,
          label: category['label'] as String,
          value: category['value'] as String,
          color: category['color'] as Color,
        );
      },
    );
  }

  Widget _buildCategoryCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return InkWell(
      onTap: () {
        _showSnackBar('Opening $label section...');
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: AppColors.grey700,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        value,
                        style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_forward, color: color, size: 14),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationsSection() {
    if (_notifications.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Notifications',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.grey700,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          constraints: const BoxConstraints(maxHeight: 200),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _notifications.length,
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.notifications, color: AppColors.primary, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _notifications[index],
                        style: TextStyle(
                          color: AppColors.grey700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.red600 : AppColors.green600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}