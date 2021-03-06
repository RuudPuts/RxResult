//
//  Observable+Result.swift
//
//  Created by Ivan Bruel on 03/05/16.
//  Copyright © 2016 Faber Ventures. All rights reserved.
//

import Foundation
import RxSwift
import Result

public protocol RxResultError: Error {
  static func failure(from error: Error) -> Self
}

public extension ObservableType {

  public func mapResult<U: RxResultError>(_ errorType: U.Type) -> Observable<Result<E, U>> {
    return self.map(Result<E, U>.success)
      .catchError{ error in
        if let error = error as? U {
            return .just(Result.failure(error))
        }
        return .just(Result.failure(U.failure(from: error))) }
    }
}

public extension ObservableType where E: ResultProtocol {

  public func `do`(onSuccess: (@escaping (Self.E.Value) throws -> Void))
    -> Observable<E> {
      return `do`(onNext: {
        guard let successValue = $0.result.value else {
          return
        }
        try onSuccess(successValue)
      })
  }

  public func `do`(onFailure: (@escaping (Self.E.Error) throws -> Void))
    -> Observable<E> {
      return `do`(onNext: {
        guard let failureValue = $0.result.error else {
          return
        }
        try onFailure(failureValue)
      })
  }

  public func `do`(onSuccess: ((Self.E.Value) throws -> Void)?, onFailure: ((Self.E.Error) throws -> Void)?)
    -> Observable<E> {
      return `do`(onNext: {
        if let successValue = $0.result.value {
          try onSuccess?(successValue)
        } else if let errorValue = $0.result.error {
          try onFailure?(errorValue)
      }
      })
  }

  public func subscribeResult(onSuccess: ((Self.E.Value) -> Void)? = nil,
                              onFailure: ((Self.E.Error) -> Void)? = nil) -> Disposable {
    return subscribe(onNext: {
      if let successValue = $0.result.value {
        onSuccess?(successValue)
      } else if let errorValue = $0.result.error {
        onFailure?(errorValue)
      }
    })
  }
}
