import 'package:flutter/material.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import '../services/settings_service.dart';
import '../services/hotkey_service.dart';

class SettingsPage extends StatefulWidget {
  final Function(double) onOpacityChanged;
  final VoidCallback onHotkeyChanged;

  const SettingsPage({
    super.key, 
    required this.onOpacityChanged,
    required this.onHotkeyChanged,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final SettingsService _settings = SettingsService();
  final HotkeyService _hotkeyService = HotkeyService();
  
  late double _currentOpacity;
  late String _currentKey;
  late List<String> _currentModifiers;

  @override
  void initState() {
    super.initState();
    _currentOpacity = _settings.transparency;
    _currentKey = _settings.hotkeyKey;
    _currentModifiers = List.from(_settings.hotkeyModifiers);
  }

  void _saveHotkeys() async {
    _settings.hotkeyKey = _currentKey;
    _settings.hotkeyModifiers = _currentModifiers;
    widget.onHotkeyChanged();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Settings",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 32),
          
          // Transparency
          const Text("Window Transparency", style: TextStyle(color: Colors.white70)),
          Row(
            children: [
              const Icon(Icons.opacity, size: 20, color: Colors.blue),
              Expanded(
                child: Slider(
                  value: _currentOpacity,
                  min: 0.2,
                  max: 1.0,
                  onChanged: (val) {
                    setState(() {
                      _currentOpacity = val;
                    });
                    widget.onOpacityChanged(val);
                  },
                ),
              ),
              Text("${(_currentOpacity * 100).toInt()}%"),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Hotkeys
          const Text("Global Hotkey (Show/Hide)", style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black38,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              children: [
                const Icon(Icons.keyboard, color: Colors.blue),
                const SizedBox(width: 12),
                Text(
                  _currentModifiers.join(' + ').toUpperCase(),
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 16),
                ),
                const Text(" + ", style: TextStyle(fontSize: 16)),
                DropdownButton<String>(
                  value: _currentKey.toLowerCase(),
                  dropdownColor: Colors.grey[900],
                  underline: Container(),
                  items: "abcdefghijklmnopqrstuvwxyz".split("").map((letter) {
                    return DropdownMenuItem(
                      value: letter,
                      child: Text(letter.toUpperCase(), style: const TextStyle(color: Colors.white)),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _currentKey = val;
                      });
                      _saveHotkeys();
                    }
                  },
                ),
                const Spacer(),
                const Text(
                  "Saved automatically",
                  style: TextStyle(fontSize: 12, color: Colors.white38),
                ),
              ],
            ),
          ),
          
          const Spacer(),
          
          const Text(
            "Note: This window stays above other apps including lockdown browsers.",
            style: TextStyle(fontSize: 12, color: Colors.white38, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }
}
