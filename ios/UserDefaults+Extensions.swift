//
//  UserDefaults+Extensions.swift
//  Runner
//
//  Created by Eugene Brusov on 11/3/21.
//

import Foundation
import RxSwift

extension UserDefaults {
    
    func stringSingle(forKey defaultName: String) -> Single<String> {
        return Single<String>.create { single in
            let value = self.string(forKey: defaultName)
            if let unwrapped = value {
                single(.success(unwrapped))
            } else {
                single(.failure(UserDefaultsError.nonExistingValue))
            }
            return Disposables.create()
        }
    }
    
    func booleanSingle(forKey defaultName: String) -> Single<Bool> {
        return Single<Bool>.create { single in
            let value = self.bool(forKey: defaultName)
            single(.success(value))
            return Disposables.create()
        }
    }
}

enum UserDefaultsError: Error {
  case nonExistingValue
  case unableToSynchronize
}
