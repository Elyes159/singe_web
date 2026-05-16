import 'dart:io';
import 'package:flutter/services.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'settings_service.dart';

class HotkeyService {
  static final HotkeyService _instance = HotkeyService._internal();
  factory HotkeyService() => _instance;
  HotkeyService._internal();

  final SettingsService _settings = SettingsService();

  Future<void> registerHotkey(VoidCallback onTrigger) async {
    await hotKeyManager.unregisterAll();

    // Convert string key to PhysicalKeyboardKey or LogicalKeyboardKey
    // For simplicity, we'll map common ones.
    // In a production app, we'd use a more robust mapping.

    LogicalKeyboardKey key = _getLogicalKey(_settings.hotkeyKey);
    List<HotKeyModifier> modifiers = _getModifiers(_settings.hotkeyModifiers);

    HotKey hotKey = HotKey(
      key: key,
      modifiers: modifiers,
      scope: HotKeyScope.system,
    );

    await hotKeyManager.register(
      hotKey,
      keyDownHandler: (hotKey) {
        onTrigger();
      },
    );
  }

  Future<void> registerQuitHotkey() async {
    HotKey quitKey = HotKey(
      key: LogicalKeyboardKey.keyQ,
      modifiers: [HotKeyModifier.meta],
      scope: HotKeyScope.system,
    );

    await hotKeyManager.register(
      quitKey,
      keyDownHandler: (hotKey) {
        exit(0);
      },
    );
  }

  LogicalKeyboardKey _getLogicalKey(String key) {
    String lowerKey = key.toLowerCase();
    
    // Map a-z
    if (lowerKey.length == 1 && lowerKey.contains(RegExp(r'[a-z]'))) {
      int charCode = lowerKey.codeUnitAt(0);
      // 'a' is 97 in ASCII
      switch (lowerKey) {
        case 'a': return LogicalKeyboardKey.keyA;
        case 'b': return LogicalKeyboardKey.keyB;
        case 'c': return LogicalKeyboardKey.keyC;
        case 'd': return LogicalKeyboardKey.keyD;
        case 'e': return LogicalKeyboardKey.keyE;
        case 'f': return LogicalKeyboardKey.keyF;
        case 'g': return LogicalKeyboardKey.keyG;
        case 'h': return LogicalKeyboardKey.keyH;
        case 'i': return LogicalKeyboardKey.keyI;
        case 'j': return LogicalKeyboardKey.keyJ;
        case 'k': return LogicalKeyboardKey.keyK;
        case 'l': return LogicalKeyboardKey.keyL;
        case 'm': return LogicalKeyboardKey.keyM;
        case 'n': return LogicalKeyboardKey.keyN;
        case 'o': return LogicalKeyboardKey.keyO;
        case 'p': return LogicalKeyboardKey.keyP;
        case 'q': return LogicalKeyboardKey.keyQ;
        case 'r': return LogicalKeyboardKey.keyR;
        case 's': return LogicalKeyboardKey.keyS;
        case 't': return LogicalKeyboardKey.keyT;
        case 'u': return LogicalKeyboardKey.keyU;
        case 'v': return LogicalKeyboardKey.keyV;
        case 'w': return LogicalKeyboardKey.keyW;
        case 'x': return LogicalKeyboardKey.keyX;
        case 'y': return LogicalKeyboardKey.keyY;
        case 'z': return LogicalKeyboardKey.keyZ;
      }
    }

    switch (lowerKey) {
      case 'space':
        return LogicalKeyboardKey.space;
      case 'enter':
        return LogicalKeyboardKey.enter;
      default:
        return LogicalKeyboardKey.keyX;
    }
  }

  List<HotKeyModifier> _getModifiers(List<String> mods) {
    List<HotKeyModifier> result = [];
    for (var mod in mods) {
      switch (mod.toLowerCase()) {
        case 'command':
          result.add(HotKeyModifier.meta);
          break;
        case 'option':
          result.add(HotKeyModifier.alt);
          break;
        case 'control':
          result.add(HotKeyModifier.control);
          break;
        case 'shift':
          result.add(HotKeyModifier.shift);
          break;
      }
    }
    return result;
  }
}
