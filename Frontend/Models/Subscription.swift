//
//  Subscription.swift
//  SafeMesh
//
//  Created by P Deepanshu on 23/02/26.
//

import Foundation
import SwiftUI

  // MARK: - Subscription Model
  struct Subscription: Identifiable, Codable {
      let id: String
      let userId: String
      let plan: SubscriptionPlan
      let status: SubscriptionStatus
      let startDate: Date
      let endDate: Date?
      let autoRenew: Bool
      let maxBandwidth: Int64
      let maxConnections: Int
      let features: [String]

      // Computed properties
      var isActive: Bool {
          status == .active && (endDate ?? Date()) > Date()
      }

      var willExpireSoon: Bool {
          guard let endDate = endDate else { return false }
          let daysRemaining = Calendar.current.dateComponents([.day], from: Date(),
  to: endDate).day ?? 0
          return daysRemaining <= 7 && daysRemaining > 0
      }

      var isExpired: Bool {
          guard let endDate = endDate else { return false }
          return endDate < Date()
      }

      var daysRemaining: Int? {
          guard let endDate = endDate else { return nil }
          return Calendar.current.dateComponents([.day], from: Date(), to:
  endDate).day
      }

      var bandwidthRemaining: Int64 {
          // In a real app, this would be calculated from usage
          return maxBandwidth
      }
  }

  // MARK: - Subscription Plan
  struct SubscriptionPlan: Identifiable, Codable, Hashable {
      let id: String
      let name: String
      let description: String
      let price: Double
      let currency: String
      let billingCycle: BillingCycle
      let maxBandwidth: Int64
      let maxConnections: Int
      let features: [String]
      let isPopular: Bool
      let sortOrder: Int

      // Computed properties
      var formattedPrice: String {
          let formatter = NumberFormatter()
          formatter.numberStyle = .currency
          formatter.currencyCode = currency
          return formatter.string(from: NSNumber(value: price)) ?? "$\(price)"
      }

      var pricePerMonth: Double {
          switch billingCycle {
          case .monthly: return price
          case .quarterly: return price / 3
          case .yearly: return price / 12
          case .lifetime: return 0
          }
      }

      var isFree: Bool {
          price == 0
      }

      // Hashable conformance
      func hash(into hasher: inout Hasher) {
          hasher.combine(id)
      }

      static func == (lhs: SubscriptionPlan, rhs: SubscriptionPlan) -> Bool {
          lhs.id == rhs.id
      }
  }

  // MARK: - Subscription Status
  enum SubscriptionStatus: String, Codable, CaseIterable {
      case active = "active"
      case pastDue = "past_due"
      case canceled = "canceled"
      case expired = "expired"
      case pending = "pending"
      case trial = "trial"

      var displayName: String {
          switch self {
          case .active: return "Active"
          case .pastDue: return "Past Due"
          case .canceled: return "Canceled"
          case .expired: return "Expired"
          case .pending: return "Pending"
          case .trial: return "Trial"
          }
      }

      var color: Color {
          switch self {
          case .active, .trial: return .green
          case .pastDue: return .orange
          case .canceled, .expired: return .red
          case .pending: return .yellow
          }
      }

      var isActive: Bool {
          switch self {
          case .active, .trial: return true
          default: return false
          }
      }
  }

  // MARK: - Billing Cycle
  enum BillingCycle: String, Codable, CaseIterable {
      case monthly = "monthly"
      case quarterly = "quarterly"
      case yearly = "yearly"
      case lifetime = "lifetime"

      var displayName: String {
          switch self {
          case .monthly: return "Monthly"
          case .quarterly: return "Quarterly"
          case .yearly: return "Yearly"
          case .lifetime: return "Lifetime"
          }
      }
  }

  // MARK: - Mock Data
  extension SubscriptionPlan {
      static let free = SubscriptionPlan(
          id: "plan_free",
          name: "Free",
          description: "Basic VPN protection",
          price: 0,
          currency: "USD",
          billingCycle: .monthly,
          maxBandwidth: 10 * 1024 * 1024 * 1024, // 10 GB
          maxConnections: 1,
          features: [
              "10 GB data per month",
              "1 device connection",
              "5 server locations",
              "Basic speed"
          ],
          isPopular: false,
          sortOrder: 0
      )

      static let monthly = SubscriptionPlan(
          id: "plan_monthly",
          name: "Premium Monthly",
          description: "Full access with monthly billing",
          price: 9.99,
          currency: "USD",
          billingCycle: .monthly,
          maxBandwidth: .max,
          maxConnections: 5,
          features: [
              "Unlimited data",
              "5 device connections",
              "50+ server locations",
              "Maximum speed",
              "24/7 support",
              "No ads"
          ],
          isPopular: false,
          sortOrder: 1
      )

      static let yearly = SubscriptionPlan(
          id: "plan_yearly",
          name: "Premium Yearly",
          description: "Best value with yearly billing",
          price: 79.99,
          currency: "USD",
          billingCycle: .yearly,
          maxBandwidth: .max,
          maxConnections: 5,
          features: [
              "Unlimited data",
              "5 device connections",
              "50+ server locations",
              "Maximum speed",
              "24/7 support",
              "No ads",
              "Save 33%"
          ],
          isPopular: true,
          sortOrder: 2
      )

      static let allPlans: [SubscriptionPlan] = [.free, .monthly, .yearly]
  }

  extension Subscription {
      static let mockActive = Subscription(
          id: "sub_123",
          userId: "user_123",
          plan: .yearly,
          status: .active,
          startDate: Date().addingTimeInterval(-86400 * 30),
          endDate: Date().addingTimeInterval(86400 * 335),
          autoRenew: true,
          maxBandwidth: .max,
          maxConnections: 5,
          features: ["unlimited", "max-speed", "5-devices"]
      )
  }
