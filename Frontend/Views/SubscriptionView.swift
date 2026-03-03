//
//  SubscriptionView.swift
//  SafeMesh
//
//  Created by P Deepanshu on 23/02/26.
//

import SwiftUI

struct SubscriptionView: View {
    @StateObject private var viewModel = SubscriptionViewModel()
    @State private var selectedPlan: SubscriptionPlan?
    @State private var showSuccess = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.yellow)

                    Text("Upgrade Your VPN")
                        .font(.title)
                        .fontWeight(.bold)

                    Text("Get unlimited access to all servers and features")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)

                // Current subscription
                if let current = viewModel.currentSubscription {
                    CurrentSubscriptionCard(subscription: current)
                }

                // Plans
                VStack(spacing: 16) {
                    Text("Choose Your Plan")
                        .font(.headline)
                        .padding(.horizontal)

                    ForEach(viewModel.plans) { plan in
                        PlanCard(
                            plan: plan,
                            isSelected: selectedPlan?.id == plan.id
                        ) {
                            selectedPlan = plan
                        }
                    }
                }

                // Features
                VStack(alignment: .leading, spacing: 12) {
                    Text("What's Included")
                        .font(.headline)
                        .padding(.horizontal)

                    FeatureCheckRow(title: "Unlimited bandwidth")
                    FeatureCheckRow(title: "Access to all 50+ servers")
                    FeatureCheckRow(title: "Up to 5 simultaneous connections")
                    FeatureCheckRow(title: "24/7 priority support")
                    FeatureCheckRow(title: "Advanced privacy features")
                }

                // Subscribe button
                Button {
                    if let plan = selectedPlan {
                        viewModel.subscribe(to: plan)
                        showSuccess = true
                    }
                } label: {
                    Text("Subscribe Now")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            selectedPlan != nil
                                ? LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                                : LinearGradient(
                                    colors: [Color.gray, Color.gray],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(selectedPlan == nil)
                .padding(.horizontal)

                // Terms
                Text("By subscribing, you agree to our Terms of Service. Subscription auto-renews unless cancelled.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding(.bottom, 20)
        }
        .navigationTitle("Subscription")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Subscription Successful!", isPresented: $showSuccess) {
            Button("OK") {}
        } message: {
            Text("You now have access to all premium features.")
        }
    }
}

struct CurrentSubscriptionCard: View {
    let subscription: Subscription

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Current Plan")
                    .font(.headline)
                Spacer()
                Text(subscription.plan.name)
                    .foregroundColor(.blue)
            }

            HStack {
                Text("Renews on \(subscription.endDate ?? Date(), style: .date)")
                Spacer()
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.blue.opacity(0.1))
        )
        .padding(.horizontal)
    }
}

struct PlanCard: View {
    let plan: SubscriptionPlan
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(plan.name)
                            .font(.headline)

                        if plan.isPopular {
                            Text("Most Popular")
                                .font(.caption)
                                .fontWeight(.medium)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.yellow)
                                .cornerRadius(4)
                        }
                    }

                    Spacer()

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.blue)
                            .font(.title2)
                    }
                }

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("$")
                        .font(.title2)
                    Text(plan.price.description)
                        .font(.title)
                        .fontWeight(.bold)
                    Text("/\(plan.billingCycle.displayName)")
                        .foregroundColor(.secondary)
                }

                VStack(alignment: .leading, spacing: 8) {
                    ForEach(plan.features, id: \.self) { feature in
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark")
                                .foregroundColor(.green)
                                .font(.caption)
                            Text(feature)
                                .font(.subheadline)
                        }
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color.blue.opacity(0.1) :
Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? Color.blue : Color.clear,
lineWidth: 2)
                    )
            )
            .shadow(color: Color.black.opacity(0.05), radius: 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct FeatureCheckRow: View {
    let title: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)

            Text(title)
                .font(.subheadline)

            Spacer()
        }
        .padding(.horizontal)
    }
}

#Preview {
    SubscriptionView()
}

