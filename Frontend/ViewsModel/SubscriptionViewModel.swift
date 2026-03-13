//
//  SubscriptionViewModel.swift
//  SafeMesh
//
//  Created by P Deepanshu on 23/02/26.
//

import Foundation
import SwiftUI
import Combine
import StoreKit

@MainActor
class SubscriptionViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var plans: [SubscriptionPlan] = []
    @Published var currentSubscription: Subscription?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showErrorMessage: Bool = false
    @Published var showSuccessMessage: Bool = false
    @Published var successMessage: String?

    // MARK: - Private Properties
    private let apiClient: APIClientProtocol
    private var authViewModel: AuthViewModel?
    private var cancellables = Set<AnyCancellable>()

    // StoreKit integration
    @Published var storeViewModel = SubscriptionStoreViewModel()

    /// Map plan IDs to App Store Connect product identifiers
    private static let storeProductIDs: [String: String] = [
        "plan_monthly": "com.safemesh.premium.monthly",
        "plan_yearly": "com.safemesh.premium.yearly"
    ]

    // MARK: - Initialization
    init(
        apiClient: APIClientProtocol = APIClient.shared,
        authViewModel: AuthViewModel? = nil
    ) {
        self.apiClient = apiClient
        self.authViewModel = authViewModel

        loadData()
        loadStoreProducts()
    }

    // MARK: - StoreKit Product Loading
    private func loadStoreProducts() {
        Task {
            let productIDs = Array(Self.storeProductIDs.values)
            await storeViewModel.loadProducts(productIDs: productIDs)
        }
    }

    // MARK: - Public Methods
    func loadData() {
        Task {
            await loadPlans()
            await loadCurrentSubscription()
        }
    }

    func loadPlans() async {
        isLoading = true

        do {
            let response: SubscriptionResponse = try await apiClient.request(
                endpoint: "/subscription/plans",
                method: .get,
                body: nil
            )

            withAnimation {
                self.plans = response.plans.sorted { $0.sortOrder < $1.sortOrder }
            }

        } catch {
            // Use mock data as fallback
            withAnimation {
                self.plans = SubscriptionPlan.allPlans
            }
        }

        isLoading = false
    }

    func loadCurrentSubscription() async {
        guard authViewModel?.isAuthenticated == true else { return }

        do {
            let response: SubscriptionResponse = try await apiClient.request(
                endpoint: "/subscription/current",
                method: .get,
                body: nil
            )

            withAnimation {
                self.currentSubscription = response.subscription
            }

        } catch {
            // User might not have a subscription
            withAnimation {
                self.currentSubscription = nil
            }
        }
    }

    func subscribe(to plan: SubscriptionPlan) {
        Task {
            await performSubscription(plan: plan)
        }
    }

    func purchasePlan(_ plan: SubscriptionPlan) async throws {
        isLoading = true
        defer { isLoading = false }

        // Step 1: Try StoreKit in-app purchase first (paid plans only)
        if let storeProductID = Self.storeProductIDs[plan.id],
           let product = storeViewModel.products.first(where: { $0.id == storeProductID }) {

            // Initiate Apple IAP flow
            guard let transaction = try await storeViewModel.purchase(product) else {
                // User cancelled or pending — do not activate
                return
            }

            // Step 2: Validate receipt with backend and activate subscription
            let request = SubscriptionPurchaseRequest(planId: plan.id)
            let response: APIResponse<Subscription> = try await apiClient.request(
                endpoint: "/subscription/purchase",
                method: .post,
                body: request
            )

            if let subscription = response.data {
                withAnimation {
                    self.currentSubscription = subscription
                }
                showSuccess(message: "Subscription activated successfully!")
            }

        } else {
            // Free plan or StoreKit product not found — activate directly via backend
            let request = SubscriptionPurchaseRequest(planId: plan.id)
            let response: APIResponse<Subscription> = try await apiClient.request(
                endpoint: "/subscription/purchase",
                method: .post,
                body: request
            )

            if let subscription = response.data {
                withAnimation {
                    self.currentSubscription = subscription
                }
                showSuccess(message: "Subscription activated successfully!")
            }
        }
    }

    func cancelSubscription() async {
        isLoading = true

        do {
            let response: APIResponse<Subscription> = try await apiClient.request(
                endpoint: "/subscription/cancel",
                method: .post,
                body: nil
            )

            withAnimation {
                self.currentSubscription = response.data
            }

            showSuccess(message: "Subscription will be canceled at the end of the billing period.")

        } catch {
            showError(message: error.localizedDescription)
        }

        isLoading = false
    }

    func restorePurchases() async {
        isLoading = true

        do {
            let response: APIResponse<Subscription> = try await apiClient.request(
                endpoint: "/subscription/restore",
                method: .post,
                body: nil
            )

            withAnimation {
                self.currentSubscription = response.data
            }

            if currentSubscription != nil {
                showSuccess(message: "Subscription restored successfully!")
            } else {
                showSuccess(message: "No active subscription found.")
            }

        } catch {
            showError(message: error.localizedDescription)
        }

        isLoading = false
    }

    func updateBillingInfo() async {
        // Navigate to billing portal
        if let url = URL(string: "https://safemesh.com/billing") {
            await UIApplication.shared.open(url)
        }
    }

    // MARK: - Computed Properties
    var hasActiveSubscription: Bool {
        currentSubscription?.isActive ?? false
    }

    var isPremium: Bool {
        guard let plan = currentSubscription?.plan else { return false }
        return !plan.isFree
    }

    var canAccessAllServers: Bool {
        hasActiveSubscription
    }

    var maxConnections: Int {
        currentSubscription?.maxConnections ?? 1
    }

    var maxBandwidth: Int64 {
        currentSubscription?.maxBandwidth ?? 10 * 1024 * 1024 * 1024 // 10 GB default
    }

    var renewalDate: Date? {
        currentSubscription?.endDate
    }

    var daysUntilRenewal: Int? {
        guard let endDate = renewalDate else { return nil }
        return Calendar.current.dateComponents([.day], from: Date(), to: endDate).day
    }

    // MARK: - Private Methods
    private func performSubscription(plan: SubscriptionPlan) async {
        do {
            try await purchasePlan(plan)
        } catch {
            // Handle subscription errors
        }
    }

    private func showError(message: String) {
        errorMessage = message
        showErrorMessage = true
    }

    private func showSuccess(message: String) {
        successMessage = message
        showSuccessMessage = true
    }
}

// MARK: - Request Models
struct SubscriptionPurchaseRequest: Codable {
    let planId: String
}

// MARK: - StoreKit Integration (iOS 15+)
@available(iOS 15.0, *)
class SubscriptionStoreViewModel: ObservableObject {
    @Published var products: [Product] = []
    @Published var purchasedProductIDs: Set<String> = []

    private var updateListenerTask: Task<Void, Error>?

    init() {
        updateListenerTask = listenForTransactions()
    }

    deinit {
        updateListenerTask?.cancel()
    }

    func loadProducts(productIDs: [String]) async {
        do {
            products = try await Product.products(for: productIDs)
        } catch {
            print("Failed to load products: \(error)")
        }
    }

    func purchase(_ product: Product) async throws -> StoreKit.Transaction? {
        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await updatePurchasedProductIDs()
            await transaction.finish()
            return transaction

        case .userCancelled:
            return nil

        case .pending:
            // Transaction waiting for user action
            return nil

        @unknown default:
            return nil
        }
    }

    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in StoreKit.Transaction.updates {
                do {
                    let transaction = try self.checkVerified(result)
                    await self.updatePurchasedProductIDs()
                    await transaction.finish()
                } catch {
                    print("Transaction verification failed: \(error)")
                }
            }
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw TransactionError.failedVerification
        case .verified(let safe):
            return safe
        }
    }

    private func updatePurchasedProductIDs() async {
        var purchased: Set<String> = []

        for await result in StoreKit.Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                purchased.insert(transaction.productID)
            } catch {
                print("Failed to verify transaction: \(error)")
            }
        }

        await MainActor.run {
            self.purchasedProductIDs = purchased
        }
    }
}

enum TransactionError: Error {
    case failedVerification
}

