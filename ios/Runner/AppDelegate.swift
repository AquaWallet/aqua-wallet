import UIKit
import Flutter
import RxSwift

public func dummyMethodToEnforceBundling() {
    create_context(0)
    set_post_object_ptr(nil)
    notification_handler(nil, nil)

    GA_auth_handler_call(nil)
    GA_auth_handler_get_status(nil, nil)
    GA_blind_transaction(nil, nil, nil)    
    GA_change_settings(nil, nil, nil)
    GA_connect(nil, nil)
    GA_reconnect_hint(nil, nil)
    GA_convert_amount(nil, nil, nil)
    GA_convert_json_to_string(nil, nil)
    GA_convert_string_to_json(nil, nil)
    GA_create_session(nil)
    GA_create_subaccount(nil, nil, nil)
    GA_create_transaction(nil, nil, nil)
    GA_destroy_auth_handler(nil)
    GA_destroy_json(nil)
    GA_destroy_session(nil)
    GA_destroy_string(nil)
    GA_generate_mnemonic_12(nil)
    GA_get_available_currencies(nil, nil)
    GA_get_balance(nil, nil, nil)
    GA_get_fee_estimates(nil, nil)
    GA_get_networks(nil)
    GA_get_previous_addresses(nil, nil, nil)
    GA_get_receive_address(nil, nil, nil)
    GA_get_settings(nil, nil)
    GA_get_subaccount(nil, 0, nil)
    GA_get_subaccounts(nil, nil, nil)
    GA_get_transactions(nil, nil, nil)
    GA_get_unspent_outputs(nil, nil, nil)
    GA_init(nil)
    GA_login_user(nil, nil, nil, nil)
    GA_refresh_assets(nil, nil)
    GA_get_assets(nil, nil, nil)
    GA_register_network(nil, nil)
    GA_register_user(nil, nil, nil, nil)
    GA_send_transaction(nil, nil, nil)
    GA_set_notification_handler(nil, nil, nil)
    GA_set_transaction_memo(nil, nil, nil, 0)
    GA_psbt_get_details(nil, nil, nil)
    GA_psbt_sign(nil, nil, nil)
    GA_sign_transaction(nil, nil, nil)
    GA_update_subaccount(nil, nil, nil)
    GA_validate_mnemonic(nil, nil)
    GA_encrypt_with_pin(nil, nil, nil)
    GA_decrypt_with_pin(nil, nil, nil)

    validate_submarine(nil, nil, nil, 0, nil, nil, nil)
    extract_claim_public_key(nil)
    create_and_sign_claim_transaction(nil, nil, nil, nil, nil, nil, 0)
    create_and_sign_refund_transaction(nil, nil, nil, nil, nil, 0)
    get_key_pair()
    sign_message_schnorr(nil, nil)
    verify_signature_schnorr(nil, nil, nil)
    rust_cstr_free(nil)

    create_taxi_transaction(0, nil, nil, nil, 0, nil, nil, false, false, false)
    create_final_taxi_pset(nil, nil)

    // this routes to boltz-dart's interface
    dummy_method_to_enforce_bundling()
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
    
    // call `getMainBundlePath` to assure linking
    if let path = String(cString: getMainBundlePath(), encoding: .utf8) {
        print("Main bundle path: \(path)")
    }
      
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
    
    @objc
    func screenshotTaken() {
        self.utilsChannel.invokeMethod("screenshotTaken", arguments: nil)
    }
    
    struct NotImplementedError : Error { }
    struct FlutterBadArgumentsError : Error { }
}
