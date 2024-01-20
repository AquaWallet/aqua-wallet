//
//  FlutterMethodChannel+Extensions.swift
//  Runner
//
//  Created by Eugene Brusov on 11/3/21.
//

import Foundation
import RxSwift

extension FlutterMethodChannel {
    
    func callHandlerObservable() -> Observable<(FlutterMethodCall, FlutterResult)> {
        return Observable<(FlutterMethodCall, FlutterResult)>.create { observer in
            let handler = {(call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
                let value = (call, result)
                observer.on(.next(value))
            }
            self.setMethodCallHandler(handler)
            return Disposables.create {
                self.setMethodCallHandler(nil)
            }
        }
    }
}
