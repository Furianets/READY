import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'READY',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: MainScreen(),
    );
  }
}

class TimerSettings {
  int minTime;
  int maxTime;

  TimerSettings({this.minTime = 10, this.maxTime = 20});
}

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin {
  bool _isRunning = false;
  bool _soundEnabled = false;
  Timer? _timer;
  final AudioPlayer _audioPlayer = AudioPlayer();
  TimerSettings _settings = TimerSettings();

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  String _currentText = 'СТАРТ';
  Color _currentColor = Colors.blue;
  double _currentSize = 200.0;
  BorderRadius _currentBorderRadius = BorderRadius.circular(15);

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: Duration(milliseconds: 500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.8,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _loadSoundSettings();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioPlayer.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadSoundSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _soundEnabled = prefs.getBool('soundEnabled') ?? false;
      });

      if (_soundEnabled) {
        _preloadAudio();
      }
    } catch (e) {
      print('Ошибка загрузки настроек: $e');
    }
  }

  Future<void> _saveSoundSettings(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('soundEnabled', enabled);
    } catch (e) {
      print('Ошибка сохранения настроек: $e');
    }
  }

  Future<void> _preloadAudio() async {
    try {
      await _audioPlayer.setSource(AssetSource('whistle.mp3'));
      print('Аудио предзагружено');
    } catch (e) {
      print('Ошибка предзагрузки аудио: $e');
    }
  }

  void _toggleSound() async {
    setState(() {
      _soundEnabled = !_soundEnabled;
    });

    await _saveSoundSettings(_soundEnabled);

    if (_soundEnabled) {
      await _preloadAudio();
      //_playActivationSound();
    } else {
      await _audioPlayer.stop();
    }
  }

  Future<void> _playActivationSound() async {
    try {
      await _audioPlayer.play(AssetSource('whistle.mp3'));
      await Future.delayed(Duration(milliseconds: 100));
      await _audioPlayer.stop();
    } catch (e) {
      print('Ошибка активации звука: $e');
    }
  }

  int _generateRandomTime() {
    final random = Random();
    return _settings.minTime + random.nextInt(_settings.maxTime - _settings.minTime + 1);
  }

  // УПРОЩЕННЫЙ МЕТОД - только звук, без вибрации
  Future<void> _whistle() async {
    // Если звук выключен - просто выходим
    if (!_soundEnabled) {
      print('Звук выключен');
      return;
    }

    try {
      await _audioPlayer.stop();
      await Future.delayed(Duration(milliseconds: 50));
      await _audioPlayer.play(AssetSource('whistle.mp3'));
      print('Свисток проигран!');
    } catch (e) {
      print('Ошибка воспроизведения звука: $e');
    }
  }

  void _startTimer() {
    if (_isRunning) return;

    int randomTime = _generateRandomTime();
    print('Сгенерировано время: $randomTime секунд');

    setState(() {
      _isRunning = true;
      _currentText = '?';
      _currentColor = Colors.orange;
      _currentSize = 150.0;
      _currentBorderRadius = BorderRadius.circular(75);
    });

    _animationController.repeat(reverse: true);

    _timer = Timer(Duration(seconds: randomTime), () {
      _animationController.stop();

      _whistle().then((_) {
        setState(() {
          _currentText = 'GO!';
          _currentColor = Colors.green;
        });

        Timer(Duration(seconds: 2), () {
          setState(() {
            _isRunning = false;
            _currentText = 'СТАРТ';
            _currentColor = Colors.blue;
            _currentSize = 200.0;
            _currentBorderRadius = BorderRadius.circular(15);
          });
          _animationController.reverse();
        });
      });
    });
  }

  void _openSettings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SettingsScreen(
          initialSettings: _settings,
          onSettingsSaved: (newSettings) {
            setState(() {
              _settings = newSettings;
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _isRunning ? _scaleAnimation.value : 1.0,
                  child: child,
                );
              },
              child: GestureDetector(
                onTap: _isRunning ? null : _startTimer,
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 400),
                  width: _currentSize,
                  height: _currentSize,
                  decoration: BoxDecoration(
                    color: _currentColor,
                    borderRadius: _currentBorderRadius,
                    boxShadow: [
                      BoxShadow(
                        color: _currentColor.withOpacity(0.5),
                        blurRadius: 15,
                        spreadRadius: 5,
                      )
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _currentText,
                      style: TextStyle(
                        fontSize: _isRunning ? 50 : 28,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(height: 30),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'ЗВУК',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: 10),
                GestureDetector(
                  onTap: _toggleSound,
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    width: 60,
                    height: 30,
                    decoration: BoxDecoration(
                      color: _soundEnabled ? Colors.green : Colors.grey,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Stack(
                      children: [
                        AnimatedPositioned(
                          duration: Duration(milliseconds: 300),
                          left: _soundEnabled ? 32 : 2,
                          top: 2,
                          child: Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 20),

            Text(
              _soundEnabled ? 'Звук включен' : 'Звук выключен',
              style: TextStyle(
                color: _soundEnabled ? Colors.green : Colors.orange,
                fontSize: 14,
              ),
            ),

            SizedBox(height: 30),

            if (!_isRunning)
              IconButton(
                onPressed: () => _openSettings(context),
                icon: Icon(Icons.settings, color: Colors.grey, size: 30),
                tooltip: 'Настройки',
              ),
          ],
        ),
      ),
    );
  }
}

class SettingsScreen extends StatefulWidget {
  final TimerSettings initialSettings;
  final Function(TimerSettings) onSettingsSaved;

  const SettingsScreen({
    Key? key,
    required this.initialSettings,
    required this.onSettingsSaved,
  }) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TimerSettings _currentSettings;

  @override
  void initState() {
    super.initState();
    _currentSettings = TimerSettings(
      minTime: widget.initialSettings.minTime,
      maxTime: widget.initialSettings.maxTime,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        title: Text('Настройки', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            _buildTimeSetting(
              'Минимальное время (сек)',
              _currentSettings.minTime,
                  (value) {
                setState(() {
                  _currentSettings.minTime = value;
                });
              },
              5,
              _currentSettings.maxTime - 1,
            ),

            SizedBox(height: 30),

            _buildTimeSetting(
              'Максимальное время (сек)',
              _currentSettings.maxTime,
                  (value) {
                setState(() {
                  _currentSettings.maxTime = value;
                });
              },
              _currentSettings.minTime + 1,
              60,
            ),

            SizedBox(height: 40),

            ElevatedButton(
              onPressed: () {
                if (_currentSettings.minTime < _currentSettings.maxTime) {
                  widget.onSettingsSaved(_currentSettings);
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Минимальное время должно быть меньше максимального'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: Text('Сохранить', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSetting(String label, int value, Function(int) onChanged, int min, int max) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.white, fontSize: 16)),
        SizedBox(height: 10),
        Row(
          children: [
            IconButton(
              onPressed: value > min ? () => onChanged(value - 1) : null,
              icon: Icon(Icons.remove, color: Colors.white),
              style: IconButton.styleFrom(
                backgroundColor: Colors.grey[800],
              ),
            ),

            SizedBox(width: 20),

            Text('$value сек',
                style: TextStyle(color: Colors.white, fontSize: 18)),

            SizedBox(width: 20),

            IconButton(
              onPressed: value < max ? () => onChanged(value + 1) : null,
              icon: Icon(Icons.add, color: Colors.white),
              style: IconButton.styleFrom(
                backgroundColor: Colors.grey[800],
              ),
            ),
          ],
        ),
      ],
    );
  }
}