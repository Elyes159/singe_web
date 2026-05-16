import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../services/settings_service.dart';
import '../services/hotkey_service.dart';
import '../main.dart';
import 'settings_page.dart';

class TabData {
  String url;
  String title;
  InAppWebViewController? controller;
  final TextEditingController urlController;

  TabData({required this.url, this.title = "New Tab"}) 
    : urlController = TextEditingController(text: url);
}

class MainWindow extends StatefulWidget {
  const MainWindow({super.key});

  @override
  State<MainWindow> createState() => _MainWindowState();
}

class _MainWindowState extends State<MainWindow> {
  bool _isSettingsOpen = false;
  double _opacity = 0.8;
  final SettingsService _settings = SettingsService();
  
  final List<TabData> _tabs = [
    TabData(url: "https://www.google.com", title: "Google")
  ];
  int _activeTabIndex = 0;
  
  bool _isLoading = false;
  String? _errorMessage;

  TabData get _activeTab => _tabs[_activeTabIndex];
  InAppWebViewController? get _activeController => _activeTab.controller;

  @override
  void initState() {
    super.initState();
    _opacity = _settings.transparency;
    _updateWindowOpacity();

    const channel = MethodChannel('com.google.chrome.helper/bridge');
    channel.setMethodCallHandler((call) async {
      if (call.method == 'onKeyEvent') {
        String key = call.arguments;
        _handleStealthKey(key);
      }
    });
  }

  void _handleStealthKey(String key) {
    setState(() {
      if (key == "\b" || key == "\u007F") { // Backspace
        if (_activeTab.urlController.text.isNotEmpty) {
          _activeTab.urlController.text = _activeTab.urlController.text.substring(0, _activeTab.urlController.text.length - 1);
        }
      } else if (key == "\r" || key == "\n") { // Enter
        _loadUrl(_activeTab.urlController.text);
      } else {
        _activeTab.urlController.text += key;
      }
    });
  }

  void _updateWindowOpacity() {
    // Window opacity is managed by the Container decoration and transparency slider
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.1), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 20,
                  spreadRadius: 5,
                )
              ],
            ),
            margin: const EdgeInsets.all(4),
            child: Column(
              children: [
                _buildModernTitleBar(),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _isSettingsOpen 
                      ? SettingsPage(
                          onOpacityChanged: (val) {
                            setState(() {
                              _opacity = val;
                              _settings.transparency = val;
                              _updateWindowOpacity();
                            });
                          },
                          onHotkeyChanged: () {
                            HotkeyService().registerHotkey(() {
                              toggleWindow();
                            });
                          },
                        )
                      : Column(
                          children: [
                            _buildTabBar(),
                            Expanded(child: _buildMainContent()),
                          ],
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: Row(
        children: [
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _tabs.length,
              itemBuilder: (context, index) {
                final isSelected = index == _activeTabIndex;
                return GestureDetector(
                  onTap: () => setState(() => _activeTabIndex = index),
                  child: Container(
                    margin: const EdgeInsets.only(right: 4, top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white.withOpacity(0.1) : Colors.transparent,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                    ),
                    constraints: const BoxConstraints(maxWidth: 150),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _tabs[index].title,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: isSelected ? Colors.white : Colors.white.withOpacity(0.5),
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (_tabs.length > 1)
                          GestureDetector(
                            onTap: () => _closeTab(index),
                            child: Icon(
                              Icons.close_rounded,
                              size: 14,
                              color: isSelected ? Colors.white54 : Colors.white24,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded, size: 18),
            onPressed: _addNewTab,
            color: Colors.white70,
          ),
        ],
      ),
    );
  }

  void _addNewTab() {
    setState(() {
      _tabs.add(TabData(url: "https://www.google.com", title: "New Tab"));
      _activeTabIndex = _tabs.length - 1;
    });
  }

  void _closeTab(int index) {
    setState(() {
      _tabs.removeAt(index);
      if (_activeTabIndex >= _tabs.length) {
        _activeTabIndex = _tabs.length - 1;
      }
    });
  }

  Widget _buildModernTitleBar() {
    return GestureDetector(
      onPanStart: (details) {}, // Window dragging handled natively
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Row(
          children: [
            Expanded(
              child: ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Colors.blueAccent, Colors.purpleAccent],
                ).createShader(bounds),
                child: const Text(
                  "Singe WEB",
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
            
            // Quick Transparency Slider
            Flexible(
              child: SizedBox(
                width: 100,
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 2,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                  ),
                  child: Slider(
                    value: _opacity,
                    min: 0.1,
                    max: 1.0,
                    onChanged: (val) {
                      setState(() {
                        _opacity = val;
                        _settings.transparency = val;
                        _updateWindowOpacity();
                      });
                    },
                  ),
                ),
              ),
            ),
            
            const SizedBox(width: 8),
            _buildIconButton(
              icon: _isSettingsOpen ? Icons.home_rounded : Icons.settings_rounded,
              onPressed: () => setState(() => _isSettingsOpen = !_isSettingsOpen),
            ),
            const SizedBox(width: 12),
            _buildIconButton(
              icon: Icons.close_rounded,
              color: Colors.redAccent.withOpacity(0.8),
              onPressed: () => toggleWindow(), // Call toggleWindow to hide natively
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconButton({required IconData icon, required VoidCallback onPressed, Color? color}) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color?.withOpacity(0.1) ?? Colors.white.withOpacity(0.05),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: color ?? Colors.white.withOpacity(0.8)),
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return Column(
      children: [
        // Modern URL Bar
        Container(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _buildNavButton(
                icon: Icons.arrow_back_ios_new_rounded,
                onPressed: () => _activeController?.goBack(),
              ),
              const SizedBox(width: 8),
              _buildNavButton(
                icon: Icons.arrow_forward_ios_rounded,
                onPressed: () => _activeController?.goForward(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(21),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: TextField(
                    controller: _activeTab.urlController,
                    style: const TextStyle(fontSize: 13, color: Colors.white70),
                    decoration: InputDecoration(
                      hintText: "Search or enter URL...",
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                      border: InputBorder.none,
                      prefixIcon: Icon(Icons.search_rounded, size: 18, color: Colors.white.withOpacity(0.3)),
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      suffixIcon: _isLoading 
                        ? Container(
                            padding: const EdgeInsets.all(12),
                            child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.blueAccent),
                          )
                        : IconButton(
                            icon: const Icon(Icons.refresh_rounded, size: 18),
                            onPressed: () => _activeController?.reload(),
                          ),
                    ),
                    onSubmitted: _loadUrl,
                  ),
                ),
              ),
            ],
          ),
        ),
        // WebView
        Expanded(
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                )
              ],
            ),
            child: IndexedStack(
              index: _activeTabIndex,
              children: _tabs.map((tab) => _buildWebViewForTab(tab)).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWebViewForTab(TabData tab) {
    return Stack(
      children: [
        InAppWebView(
          initialUrlRequest: URLRequest(url: WebUri(tab.url)),
          initialSettings: InAppWebViewSettings(
            javaScriptEnabled: true,
            isInspectable: true,
            transparentBackground: true,
            allowsInlineMediaPlayback: true,
            iframeAllowFullscreen: true,
            userAgent: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15",
          ),
          onWebViewCreated: (controller) {
            tab.controller = controller;
          },
          onLoadStart: (controller, url) {
            if (tab == _activeTab) {
              setState(() {
                _isLoading = true;
                _errorMessage = null;
              });
            }
            if (url != null) tab.urlController.text = url.toString();
          },
          onLoadStop: (controller, url) {
            if (tab == _activeTab) {
              setState(() {
                _isLoading = false;
              });
            }
            if (url != null) {
              tab.urlController.text = url.toString();
              controller.getTitle().then((title) {
                if (title != null && title.isNotEmpty) {
                  setState(() => tab.title = title);
                }
              });
            }
          },
          onReceivedError: (controller, request, error) {
            if (tab == _activeTab) {
              setState(() {
                _isLoading = false;
                _errorMessage = "Unable to load page: ${error.description}";
              });
            }
          },
        ),
        if (tab == _activeTab && _errorMessage != null)
          _buildErrorView(),
      ],
    );
  }

  Widget _buildNavButton({required IconData icon, required VoidCallback onPressed}) {
    return IconButton(
      icon: Icon(icon, size: 16, color: Colors.white.withOpacity(0.6)),
      onPressed: onPressed,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
    );
  }

  Widget _buildErrorView() {
    return Container(
      color: Colors.black.withOpacity(0.9),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, color: Colors.white24, size: 64),
            const SizedBox(height: 24),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _activeController?.reload(),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text("Retry Connection"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
            ),
          ],
        ),
      ),
    );
  }
  void _loadUrl(String val) {
    if (val.isEmpty) return;

    String url = val.trim();
    if (!url.startsWith("http://") && !url.startsWith("https://")) {
      // Check if it looks like a domain (e.g., "google.com")
      final domainRegExp = RegExp(r'^([a-z0-9]+(-[a-z0-9]+)*\.)+[a-z]{2,}$', caseSensitive: false);
      if (domainRegExp.hasMatch(url)) {
        url = "https://$url";
      } else {
        // Otherwise, treat as a search query
        url = "https://www.google.com/search?q=${Uri.encodeComponent(url)}";
      }
    }

    _activeController?.loadUrl(
      urlRequest: URLRequest(url: WebUri(url))
    );
    _activeTab.urlController.text = url;
  }
}
