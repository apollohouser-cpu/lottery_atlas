import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  private var magicMouseChannel: FlutterMethodChannel!
  private var scrollEventMonitor: Any?
  private var isMapActive = false

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = frame

    contentViewController = flutterViewController
    setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    magicMouseChannel = FlutterMethodChannel(
      name: "lottery_atlas/magic_mouse",
      binaryMessenger: flutterViewController.engine.binaryMessenger
    )

    magicMouseChannel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "setMapActive" else {
        result(FlutterMethodNotImplemented)
        return
      }

      self?.isMapActive = call.arguments as? Bool ?? false
      result(nil)
    }

    scrollEventMonitor = NSEvent.addLocalMonitorForEvents(
      matching: .scrollWheel
    ) { [weak self] event in
      guard let self = self, self.isMapActive else {
        return event
      }

      let deltaY = event.hasPreciseScrollingDeltas
        ? event.scrollingDeltaY
        : event.deltaY

      if deltaY != 0 {
        self.magicMouseChannel.invokeMethod(
          "scroll",
          arguments: ["deltaY": deltaY]
        )
      }

      // The map consumes scrolling while it is active.
      return nil
    }

    super.awakeFromNib()
  }

  deinit {
    if let scrollEventMonitor = scrollEventMonitor {
      NSEvent.removeMonitor(scrollEventMonitor)
    }
  }
}