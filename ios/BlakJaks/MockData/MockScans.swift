import Foundation

enum MockScans {
    static let scanResult = ScanResult(
        success: true,
        productName: "BlakJaks Classic",
        usdcEarned: 1.50,
        tierMultiplier: 1.5,
        tierProgress: TierProgress(
            quarter: "Q1 2026",
            currentCount: 68,
            nextTier: "High Roller",
            scansRequired: 32
        ),
        compEarned: CompEarned(
            id: "mock-comp-uuid-001",
            amount: 100.00,
            status: "pending_choice",
            requiresPayoutChoice: true
        ),
        milestoneHit: false,
        walletBalance: 1252.25,
        globalScanCount: 1487392
    )

    static let history: [Scan] = [
        Scan(id: 1, qrCode: "ABCD-1234-EFGH", productName: "BlakJaks Classic", productSku: "BJC-001", usdcEarned: 1.50, tierMultiplier: 1.5, tier: "VIP", createdAt: "2026-02-20T11:30:00Z"),
        Scan(id: 2, qrCode: "IJKL-5678-MNOP", productName: "BlakJaks Gold", productSku: "BJG-001", usdcEarned: 2.00, tierMultiplier: 1.5, tier: "VIP", createdAt: "2026-02-19T15:00:00Z"),
        Scan(id: 3, qrCode: "QRST-9012-UVWX", productName: "BlakJaks Frost", productSku: "BJF-001", usdcEarned: 1.50, tierMultiplier: 1.5, tier: "VIP", createdAt: "2026-02-18T09:15:00Z"),
        Scan(id: 4, qrCode: "YZAB-3456-CDEF", productName: "BlakJaks Classic", productSku: "BJC-001", usdcEarned: 1.50, tierMultiplier: 1.5, tier: "VIP", createdAt: "2026-02-17T14:45:00Z")
    ]
}
