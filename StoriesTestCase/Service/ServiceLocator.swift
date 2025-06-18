//
//  ServiceLocator.swift
//  StoriesTestCase
//
//  Created by Mikhail Yurov on 18.06.2025.
//

import Foundation

final class ServiceLocator {
    static let shared = ServiceLocator()
    private init() {}

    private var services: [ObjectIdentifier: Any] = [:]

    func register<T>(_ service: T) {
        let key = ObjectIdentifier(T.self)
        services[key] = service
    }

    func resolve<T>() -> T {
        let key = ObjectIdentifier(T.self)
        guard let service = services[key] as? T else {
            fatalError("Service for type \(T.self) not found")
        }
        return service
    }

    func reset() {
        services.removeAll()
    }
}
