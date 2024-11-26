//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension ServerUserPermissionsView {

    struct SessionsSection: View {

        @Binding
        var policy: UserPolicy

        // MARK: - State Variables

        @State
        private var tempLoginAttempts: Int?
        @State
        private var tempMaxSessions: Int?

        // MARK: - Failed Login Validation

        private var filteredLoginFailurePolicies: [LoginFailurePolicy] {
            LoginFailurePolicy.allCases.filter {
                if policy.isAdministrator ?? false {
                    return $0 != .userDefault
                } else {
                    return $0 != .adminDefault
                }
            }
        }

        private var isCustomLoginFailurePolicy: Bool {
            ![
                LoginFailurePolicy.unlimited.rawValue,
                LoginFailurePolicy.adminDefault.rawValue,
                LoginFailurePolicy.userDefault.rawValue
            ]
                .contains(policy.loginAttemptsBeforeLockout)
        }

        var body: some View {
            FailedLoginsView
            MaxSessionsView
        }

        // MARK: - Failed Login Selection View

        @ViewBuilder
        private var FailedLoginsView: some View {
            Section {
                Picker(
                    L10n.maximumFailedLoginPolicy,
                    selection: $policy.loginAttemptsBeforeLockout.map(
                        getter: { LoginFailurePolicy.from(
                            rawValue: $0 ?? 0,
                            isAdministrator: policy.isAdministrator ?? false
                        ) },
                        setter: { $0.rawValue }
                    )
                ) {
                    ForEach(filteredLoginFailurePolicies, id: \.self) { policy in
                        Text(policy.displayTitle).tag(policy)
                    }
                }

                if isCustomLoginFailurePolicy {
                    MaxFailedLoginsButton()
                }

            } header: {
                Text(L10n.sessions)
            } footer: {
                VStack(alignment: .leading) {
                    Text(L10n.maximumFailedLoginPolicyDescription)
                    LearnMoreButton(L10n.maximumFailedLoginPolicy) {
                        TextPair(
                            title: L10n.unlimited,
                            subtitle: L10n.unlimitedFailedLoginDescription
                        )
                        TextPair(
                            title: L10n.default,
                            subtitle: L10n.defaultFailedLoginDescription
                        )
                        TextPair(
                            title: L10n.custom,
                            subtitle: L10n.customFailedLoginDescription
                        )
                    }
                }
            }
        }

        // MARK: - Failed Login Selection Button

        @ViewBuilder
        private func MaxFailedLoginsButton() -> some View {
            ChevronAlertButton(
                L10n.customFailedLogins,
                subtitle: Text(tempLoginAttempts ?? policy.loginAttemptsBeforeLockout ?? 0, format: .number),
                description: L10n.enterCustomFailedLogins
            ) {
                let loginAttemptsBinding = Binding<Int>(
                    get: { tempLoginAttempts ?? policy.loginAttemptsBeforeLockout ?? 0 },
                    set: { newValue in tempLoginAttempts = newValue }
                )

                TextField(L10n.failedLogins, value: loginAttemptsBinding, format: .number)
                    .keyboardType(.numberPad)
            } onSave: {
                if let tempValue = tempLoginAttempts {
                    policy.loginAttemptsBeforeLockout = tempValue
                }
            } onCancel: {
                tempLoginAttempts = policy.loginAttemptsBeforeLockout
            }
        }

        // MARK: - Failed Login Validation

        @ViewBuilder
        private var MaxSessionsView: some View {
            Section {
                CaseIterablePicker(
                    L10n.maximumSessionsPolicy,
                    selection: $policy.maxActiveSessions.map(
                        getter: { ActiveSessionsPolicy(rawValue: $0) ?? .custom },
                        setter: { $0.rawValue }
                    )
                )
                if policy.maxActiveSessions != ActiveSessionsPolicy.unlimited.rawValue {
                    MaxSessionsButton()
                }
            } footer: {
                VStack(alignment: .leading) {
                    Text(L10n.maximumConnectionsDescription)
                    LearnMoreButton(L10n.maximumSessionsPolicy) {
                        TextPair(
                            title: L10n.lockedUsers,
                            subtitle: L10n.maximumFailedLoginPolicyReenable
                        )
                        TextPair(
                            title: L10n.unlimited,
                            subtitle: L10n.unlimitedConnectionsDescription
                        )
                        TextPair(
                            title: L10n.custom,
                            subtitle: L10n.customConnectionsDescription
                        )
                    }
                }
            }
        }

        @ViewBuilder
        private func MaxSessionsButton() -> some View {
            ChevronAlertButton(
                L10n.customSessions,
                subtitle: Text(tempMaxSessions ?? policy.maxActiveSessions ?? 0, format: .number),
                description: L10n.enterCustomMaxSessions
            ) {
                let maxSessionsBinding = Binding<Int>(
                    get: { tempMaxSessions ?? policy.maxActiveSessions ?? 0 },
                    set: { newValue in tempMaxSessions = newValue }
                )

                TextField(L10n.maximumSessions, value: maxSessionsBinding, format: .number)
                    .keyboardType(.numberPad)
            } onSave: {
                if let tempValue = tempMaxSessions {
                    policy.maxActiveSessions = tempValue
                }
            } onCancel: {
                tempMaxSessions = policy.maxActiveSessions
            }
        }
    }
}
