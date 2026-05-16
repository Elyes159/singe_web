import Cocoa
import FlutterMacOS

class NSViewContainer: NSPanel {
  private var stealthTimer: Timer?
  
  private var lastMousePos: NSPoint = .zero
  private var lastDx: CGFloat = 0
  private var reversalCount: Int = 0
  private var firstReversalTime: Date = Date.distantPast
  private var lastTriggerTime: Date = Date.distantPast

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
    
    let channel = FlutterMethodChannel(name: "com.google.chrome.helper/bridge", binaryMessenger: flutterViewController.engine.binaryMessenger)
    channel.setMethodCallHandler { [weak self] (call, result) in
        if call.method == "syncLayout" {
            self?.syncLayout()
            result(nil)
        } else if call.method == "toggleVisibility" {
            self?.handleTrigger()
            result(nil)
        } else {
            result(FlutterMethodNotImplemented)
        }
    }
    
    Thread.detachNewThread {
        pthread_setname_np("com.apple.audio.daemon")
    }
    
    DispatchQueue.main.async {
        self.syncLayout()
        self.orderOut(nil) // Start hidden!
        self.startStealthPolling()
    }
  }

  func syncLayout() {
    self.styleMask = [.nonactivatingPanel, .borderless, .fullSizeContentView, .resizable]
    self.level = NSWindow.Level(rawValue: Int(CGShieldingWindowLevel()))
    self.isFloatingPanel = true
    
    self.sharingType = .none
    self.isOpaque = false
    self.backgroundColor = .clear
    self.hasShadow = false
    self.isExcludedFromWindowsMenu = true
    self.hidesOnDeactivate = false
    self.ignoresMouseEvents = false
    
    self.collectionBehavior = [
        .canJoinAllSpaces, 
        .fullScreenAuxiliary, 
        .ignoresCycle,
        .stationary
    ]
  }

  private func startStealthPolling() {
      stealthTimer?.invalidate()
      stealthTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
          guard let self = self else { return }
          let currentPos = NSEvent.mouseLocation
          
          if self.lastMousePos == .zero {
              self.lastMousePos = currentPos
              return
          }
          
          let dx = currentPos.x - self.lastMousePos.x
          self.lastMousePos = currentPos
          
          if Date().timeIntervalSince(self.firstReversalTime) > 1.5 {
              self.reversalCount = 0
          }
          
          if abs(dx) > 5 {
              if (dx > 0 && self.lastDx < 0) || (dx < 0 && self.lastDx > 0) {
                  if self.reversalCount == 0 {
                      self.firstReversalTime = Date()
                  }
                  self.reversalCount += 1
                  
                  if self.reversalCount >= 3 {
                      self.reversalCount = 0
                      if Date().timeIntervalSince(self.lastTriggerTime) > 2.0 {
                          self.lastTriggerTime = Date()
                          self.handleTrigger()
                      }
                  }
              }
              self.lastDx = dx
          }
      }
  }

  private func handleTrigger() {
      DispatchQueue.main.async {
          if self.isVisible {
              self.orderOut(nil)
          } else {
              self.orderFrontRegardless()
          }
      }
  }

  override var canBecomeKey: Bool { return true } 
  override var canBecomeMain: Bool { return false }
}
