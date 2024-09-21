import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:developer' as developer;
import 'dart:convert' show ascii;
import 'dart:async';
import 'my_device_screen.dart';
import 'my_profile_screen.dart';
import 'settings_screen.dart';

class TreatmentScreen extends StatefulWidget {
  final BluetoothDevice device;

  const TreatmentScreen({super.key, required this.device});

  @override
  _TreatmentScreenState createState() => _TreatmentScreenState();
}

class _TreatmentScreenState extends State<TreatmentScreen> {
  static const String _targetCharacteristicUuid =
      '4C51F3C6-BBBB-11EE-BE56-0242AC120002';

  final Map<String, double> _outputPower = {
    'Front': 0,
    'Left': 0,
    'Top': 0,
    'Right': 0,
    'Back': 0,
    'All': 0,
  };

  final List<String> _sections = ['Front', 'Left', 'Top', 'Right', 'Back'];

  final Map<String, int> _sectionMapping = {
    'Front': 0,
    'Left': 1,
    'Top': 2,
    'Right': 3,
    'Back': 4,
    'All': 9,
  };

  double _frequency = 0;
  BluetoothCharacteristic? _targetCharacteristic;
  bool _isConnecting = true;
  String _connectionStatus = 'Connecting...';
  Timer? _debounceTimer;
  Timer? _softAdjustmentTimer;

  int _selectedTime = 5; // Default 5 minutes
  bool _isRunning = false;
  int _remainingTime = 0;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _connectAndDiscoverServices();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _softAdjustmentTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _connectAndDiscoverServices() async {
    try {
      await widget.device.connect();
      setState(() => _connectionStatus = 'Connected. Discovering services...');
      developer.log('Connected to ${widget.device.platformName}');

      final services = await widget.device.discoverServices();
      developer.log('Discovered ${services.length} services');

      for (var service in services) {
        for (var characteristic in service.characteristics) {
          if (characteristic.uuid.toString().toUpperCase() ==
              _targetCharacteristicUuid.toUpperCase()) {
            _targetCharacteristic = characteristic;
            developer.log('Target characteristic found');
            setState(() => _connectionStatus = 'Connected and ready');
            return;
          }
        }
      }

      developer.log('Target characteristic not found',
          error: 'Characteristic $_targetCharacteristicUuid not found');
      setState(
          () => _connectionStatus = 'Error: Required characteristic not found');
    } catch (e) {
      developer.log('Error connecting to device', error: e.toString());
      setState(() => _connectionStatus = 'Error: ${e.toString()}');
    } finally {
      setState(() => _isConnecting = false);
    }
  }

  int _percentageToHex(double percentage) {
    return (percentage * 2.55).round();
  }

  void _debouncedUpdateOutputPower(String section, double targetPercentage) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _startSoftAdjustment(section, targetPercentage);
    });

    setState(() {
      if (section == 'All') {
        for (var sec in _sections) {
          _outputPower[sec] = targetPercentage;
        }
      }
      _outputPower[section] = targetPercentage;

      if (section != 'All') {
        if (_sections.every((sec) => _outputPower[sec] == targetPercentage)) {
          _outputPower['All'] = targetPercentage;
        } else {
          _outputPower['All'] = 0;
        }
      }
    });
  }

  void _startSoftAdjustment(String section, double targetPercentage) {
    final startPercentage = _outputPower[section]!;
    final difference = targetPercentage - startPercentage;
    const steps = 10;
    var currentStep = 0;

    _softAdjustmentTimer?.cancel();
    _softAdjustmentTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (currentStep < steps) {
        currentStep++;
        final intermediatePercentage =
            startPercentage + (difference * currentStep / steps);
        _updateOutputPower(section, intermediatePercentage);
      } else {
        _updateOutputPower(section, targetPercentage);
        timer.cancel();
      }
    });
  }

  Future<void> _updateOutputPower(String section, double percentage) async {
    final hexValue = _percentageToHex(percentage);
    final hexPower = hexValue.toRadixString(16).padLeft(2, '0').toUpperCase();
    final hexFrequency =
        _frequency.round().toRadixString(16).padLeft(2, '0').toUpperCase();

    if (section == 'All') {
      for (var sec in _sections) {
        final sectionCode = _sectionMapping[sec]!;
        final command = '[$sectionCode,FFF,FF,1,$hexPower,$hexFrequency]';
        await _sendCommand(command);
      }
    } else {
      final sectionCode = _sectionMapping[section]!;
      final command = '[$sectionCode,FFF,FF,1,$hexPower,$hexFrequency]';
      await _sendCommand(command);
    }
  }

  Future<void> _updateFrequency(double value) async {
    setState(() => _frequency = value);

    final frequencyByte = value.round();
    final hexFrequency =
        frequencyByte.toRadixString(16).padLeft(2, '0').toUpperCase();

    for (var section in _sections) {
      final hexPower = _percentageToHex(_outputPower[section]!)
          .toRadixString(16)
          .padLeft(2, '0')
          .toUpperCase();
      final sectionCode = _sectionMapping[section]!;
      final command = '[$sectionCode,FFF,FF,1,$hexPower,$hexFrequency]';
      await _sendCommand(command);
    }
  }

  Future<void> _sendCommand(String command) async {
    if (_targetCharacteristic == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Device not ready. Please try reconnecting.')),
      );
      return;
    }

    try {
      final asciiBytes = ascii.encode(command);
      await _targetCharacteristic!.write(asciiBytes, withoutResponse: true);
      developer.log('Command sent: $command');
    } catch (e) {
      developer.log('Error sending command', error: e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending command: ${e.toString()}')),
      );
    }
  }

  void _startStopTreatment() {
    if (_isRunning) {
      _countdownTimer?.cancel();
      setState(() {
        _isRunning = false;
        _remainingTime = 0;
      });
      _resetDevice();
    } else {
      setState(() {
        _isRunning = true;
        _remainingTime = _selectedTime * 60;
      });
      _startCountdown();
    }
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingTime > 0) {
          _remainingTime--;
        } else {
          _isRunning = false;
          timer.cancel();
          _resetDevice(showDialog: true);
        }
      });
    });
  }

  Future<void> _resetDevice({bool showDialog = false}) async {
    // Send the specific command to turn off the device
    await _sendCommand('[9,FFF,FF,1,00,00]');

    // Update the UI
    setState(() {
      for (var section in _sections) {
        _outputPower[section] = 0;
      }
      _outputPower['All'] = 0;
      _frequency = 0;
    });

    if (showDialog) {
      _showTreatmentFinishedDialog();
    }
  }

  void _showTreatmentFinishedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Treatment Finished'),
          content: const Text(
              'Your treatment session has completed and ready for new treatment.'),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Widget _buildOutputPowerSlider(String section) {
    return Column(
      children: [
        Text('$section:'),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: _outputPower[section]!,
                min: 0,
                max: 100,
                divisions: 100,
                label: '${_outputPower[section]!.round()}%',
                onChanged: (value) =>
                    _debouncedUpdateOutputPower(section, value),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 60,
              child: FadingText(
                text: '${_outputPower[section]!.round()}%',
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Treatment - ${widget.device.platformName}'),
      ),
      body: _isConnecting
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildStatusCard(),
                  const SizedBox(height: 16),
                  _buildTimerCard(),
                  const SizedBox(height: 16),
                  _buildFrequencyCard(),
                  const SizedBox(height: 16),
                  _buildOutputPowerCard(),
                ],
              ),
            ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Text('Status', style: Theme.of(context).textTheme.titleLarge),
            Text(_connectionStatus,
                style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }

  Widget _buildTimerCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Text('Treatment Timer',
                style: Theme.of(context).textTheme.titleLarge),
            DropdownButton<int>(
              value: _selectedTime,
              onChanged: _isRunning
                  ? null
                  : (int? newValue) {
                      setState(() {
                        _selectedTime = newValue!;
                      });
                    },
              items: <int>[1, 5, 10, 15, 20, 25, 30, 60]
                  .map<DropdownMenuItem<int>>((int value) {
                return DropdownMenuItem<int>(
                  value: value,
                  child: Text('$value minutes'),
                );
              }).toList(),
            ),
            const SizedBox(height: 10),
            Text(
              _isRunning
                  ? 'Time Remaining: ${_formatTime(_remainingTime)}'
                  : 'Ready to Start',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _startStopTreatment,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isRunning ? Colors.red : Colors.green,
                foregroundColor: Colors.white,
              ),
              child: Text(_isRunning ? 'Stop' : 'Start'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFrequencyCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Text('Frequency', style: Theme.of(context).textTheme.titleLarge),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _frequency,
                    min: 0,
                    max: 250,
                    divisions: 25,
                    label: '${_frequency.round()} Hz',
                    onChanged: (value) {
                      double roundedValue = (value / 10).round() * 10;
                      _updateFrequency(roundedValue);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 70,
                  child: FadingText(text: '${_frequency.round()} Hz'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOutputPowerCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Text('Output Power', style: Theme.of(context).textTheme.titleLarge),
            _buildOutputPowerSlider('All'),
            const Divider(),
            ..._sections.map(_buildOutputPowerSlider),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(icon: Icon(Icons.devices), label: 'My Devices'),
        BottomNavigationBarItem(icon: Icon(Icons.healing), label: 'Treatments'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
      ],
      currentIndex: 1,
      selectedItemColor: Theme.of(context).primaryColor,
      unselectedItemColor: Colors.grey,
      onTap: _onBottomNavItemTapped,
      type: BottomNavigationBarType.fixed,
    );
  }

  void _onBottomNavItemTapped(int index) {
    if (index != 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => index == 0
              ? const MyDeviceScreen()
              : index == 2
                  ? MyProfileScreen(device: widget.device)
                  : SettingsScreen(device: widget.device),
        ),
      );
    }
  }
}

class FadingText extends StatefulWidget {
  final String text;

  const FadingText({super.key, required this.text});

  @override
  _FadingTextState createState() => _FadingTextState();
}

class _FadingTextState extends State<FadingText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
  }

  @override
  void didUpdateWidget(FadingText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Text(widget.text, style: Theme.of(context).textTheme.bodyLarge),
    );
  }
}
