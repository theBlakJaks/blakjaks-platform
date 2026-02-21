import Foundation

enum MockTransactions {
    static let wallet = Wallet(
        compBalance: 847.50,
        availableBalance: 1250.75,
        pendingBalance: 85.00,
        currency: "USD",
        linkedBankAccount: DwollaFundingSource(
            id: "fs-001",
            name: "Chase Checking",
            bankName: "Chase",
            lastFour: "4242",
            type: "checking",
            status: "verified"
        ),
        address: nil
    )

    static let list: [Transaction] = [
        Transaction(id: 1, type: "comp_earned", amount: 100.00, currency: "USD", status: "processed", description: "Milestone Comp — $100 tier", createdAt: "2026-02-18T14:30:00Z", processedAt: "2026-02-18T14:30:00Z", txHash: nil),
        Transaction(id: 2, type: "scan_earn", amount: 1.50, currency: "USD", status: "processed", description: "QR Scan Earn — BlakJaks Classic (1.5x VIP)", createdAt: "2026-02-18T13:00:00Z", processedAt: "2026-02-18T13:00:00Z", txHash: nil),
        Transaction(id: 3, type: "bank_withdrawal", amount: -200.00, currency: "USD", status: "processed", description: "ACH Withdrawal to Chase ••4242", createdAt: "2026-02-17T10:00:00Z", processedAt: "2026-02-19T10:00:00Z", txHash: nil),
        Transaction(id: 4, type: "crypto_withdrawal", amount: -50.00, currency: "USDC", status: "pending", description: "USDC Withdrawal to 0xabc…def", createdAt: "2026-02-20T11:00:00Z", processedAt: nil, txHash: "0xabc123def456"),
        Transaction(id: 5, type: "guaranteed_comp", amount: 50.00, currency: "USD", status: "processed", description: "Monthly Guaranteed Comp — February 2026", createdAt: "2026-02-01T02:00:00Z", processedAt: "2026-02-01T02:00:00Z", txHash: nil)
    ]

    static let compVault = CompVault(
        availableBalance: 1250.75,
        lifetimeComps: 4820.50,
        goldChips: 42,
        milestones: [
            CompMilestone(id: "100", threshold: 100, label: "$100 Milestone", achieved: true, achievedAt: "2025-03-01T00:00:00Z"),
            CompMilestone(id: "1000", threshold: 1000, label: "$1,000 Milestone", achieved: true, achievedAt: "2025-08-15T00:00:00Z"),
            CompMilestone(id: "10000", threshold: 10000, label: "$10,000 Milestone", achieved: false, achievedAt: nil),
            CompMilestone(id: "200000", threshold: 200000, label: "$200K Vegas Trip", achieved: false, achievedAt: nil)
        ],
        guaranteedComps: [
            GuaranteedComp(id: 1, amount: 50.00, month: "February 2026", status: "paid", paidAt: "2026-02-01T02:00:00Z"),
            GuaranteedComp(id: 2, amount: 50.00, month: "January 2026", status: "paid", paidAt: "2026-01-01T02:00:00Z")
        ]
    )
}
