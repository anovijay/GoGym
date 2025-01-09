//
//  ErrorHandling.swift
//  GoGym
//
//  Created by Anoop Vijayan on 08.01.25.
// ErrorHandling.swift

import Foundation
import Combine

protocol ErrorHandling {
    var currentError: String? { get set }
    func handle(_ error: Error)
    func handle(_ message: String)
}

class AppErrorHandler: ObservableObject, ErrorHandling {
    static let shared = AppErrorHandler()
    
    @Published var currentError: String?
    @Published var showError: Bool = false
    
    private var errorPublisher = PassthroughSubject<String, Never>()
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupErrorHandling()
    }
    
    private func setupErrorHandling() {
        errorPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                self?.currentError = message
                self?.showError = true
            }
            .store(in: &cancellables)
    }
    
    func handle(_ error: Error) {
        let errorMessage = error.localizedDescription
        errorPublisher.send(errorMessage)
    }
    
    func handle(_ message: String) {
        errorPublisher.send(message)
    }
    
    func clearError() {
        currentError = nil
        showError = false
    }
}
