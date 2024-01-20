import UIKit
import Flutter
import RxSwift

public func dummyMethodToEnforceBundling() {
    create_context(0)
    set_post_object_ptr(nil)
    notification_handler(nil, nil)

    GA_auth_handler_call(nil)
    GA_auth_handler_get_status(nil, nil)
    GA_connect(nil, nil)
    GA_convert_amount(nil, nil, nil)
    GA_convert_json_to_string(nil, nil)
    GA_convert_string_to_json(nil, nil)
    GA_create_pset(nil, nil, nil)
    GA_create_session(nil)
    GA_create_subaccount(nil, nil, nil)
    GA_create_transaction(nil, nil, nil)
    GA_destroy_auth_handler(nil)
    GA_destroy_json(nil)
    GA_destroy_session(nil)
    GA_destroy_string(nil)
    GA_generate_mnemonic_12(nil)
    GA_get_balance(nil, nil, nil)
    GA_get_fee_estimates(nil, nil)
    GA_get_networks(nil)
    GA_get_receive_address(nil, nil, nil)
    GA_get_subaccount(nil, 0, nil)
    GA_get_transactions(nil, nil, nil)
    GA_get_unspent_outputs(nil, nil, nil)
    GA_init(nil)
    GA_login_user(nil, nil, nil, nil)
    GA_refresh_assets(nil, nil, nil)
    GA_get_assets(nil, nil, nil)
    GA_register_user(nil, nil, nil, nil)
    GA_send_transaction(nil, nil, nil)
    GA_set_notification_handler(nil, nil, nil)
    GA_sign_pset(nil, nil, nil)
    GA_psbt_sign(nil, nil, nil)
    GA_sign_transaction(nil, nil, nil)
    GA_validate_mnemonic(nil, nil)

    reconstruct_swap_script(nil, nil, nil, 0)
    extract_claim_public_key(nil)
    rust_cstr_free(nil)
}

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    
  var utilsChannel: FlutterMethodChannel!

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    
    utilsChannel = FlutterMethodChannel(name: "com.example.aqua/utils", binaryMessenger: controller.binaryMessenger)

    utilsChannel.setMethodCallHandler({
      [weak self] (call: FlutterMethodCall, result: FlutterResult) -> Void in
        guard let self = self else {
            result(true)
            return;
        }
        switch call.method {
        case "addScreenshotNotificationObserver":
            NotificationCenter.default.addObserver(self, selector: #selector(self.screenshotTaken), name: UIApplication.userDidTakeScreenshotNotification, object: nil)
        case "removeScreenshotNotificationObserver":
            NotificationCenter.default.removeObserver(self)
        default: result(FlutterMethodNotImplemented)
        }
    })
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
    
    @objc
    func screenshotTaken() {
        self.utilsChannel.invokeMethod("screenshotTaken", arguments: nil)
    }
    
    struct NotImplementedError : Error { }
    struct FlutterBadArgumentsError : Error { }
}
