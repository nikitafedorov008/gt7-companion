import Cocoa
import FlutterMacOS
// import macos_window_utils

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    // The telemetry HUD is laid out like the game's cluster, which needs more
    // room than the storyboard default of 800x600.
    self.setContentSize(NSSize(width: 1280, height: 820))
    self.center()

    RegisterGeneratedPlugins(registry: flutterViewController)

    // let windowFrame = self.frame
    // let macOSWindowUtilsViewController = MacOSWindowUtilsViewController()
    // self.contentViewController = macOSWindowUtilsViewController
    // self.setFrame(windowFrame, display: true)
    //
    // /* Initialize the macos_window_utils plugin */
    // MainFlutterWindowManipulator.start(mainFlutterWindow: self)
    //
    // RegisterGeneratedPlugins(registry: macOSWindowUtilsViewController.flutterViewController)

    super.awakeFromNib()
  }
}
