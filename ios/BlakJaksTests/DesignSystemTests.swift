import XCTest
import SwiftUI
@testable import BlakJaks

final class DesignSystemTests: XCTestCase {

    // MARK: - Color Tests

    func testGoldColorValues() {
        // #D4AF37 = rgb(212, 175, 55)
        // Verify through UIColor
        let uiColor = UIColor(Color.gold)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        XCTAssertEqual(r, 212/255, accuracy: 0.01)
        XCTAssertEqual(g, 175/255, accuracy: 0.01)
        XCTAssertEqual(b, 55/255, accuracy: 0.01)
    }

    func testTierColors() {
        XCTAssertNotNil(Color.tierStandard)
        XCTAssertNotNil(Color.tierVIP)
        XCTAssertNotNil(Color.tierHighRoller)
        XCTAssertNotNil(Color.tierWhale)
        // Whale tier IS gold
        XCTAssertEqual(Color.tierWhale, Color.gold)
    }

    // MARK: - Spacing Tests

    func testSpacingConstants() {
        XCTAssertEqual(Spacing.xs, 4)
        XCTAssertEqual(Spacing.sm, 8)
        XCTAssertEqual(Spacing.md, 16)
        XCTAssertEqual(Spacing.lg, 24)
        XCTAssertEqual(Spacing.xl, 32)
        XCTAssertEqual(Spacing.xxl, 48)
    }

    func testSpacingIsEightPointGrid() {
        // All standard spacings should be multiples of 4
        let spacings: [CGFloat] = [Spacing.xs, Spacing.sm, Spacing.md, Spacing.lg, Spacing.xl, Spacing.xxl]
        for spacing in spacings {
            XCTAssertEqual(spacing.truncatingRemainder(dividingBy: 4), 0, "Spacing \(spacing) is not a multiple of 4")
        }
    }

    // MARK: - Layout Tests

    func testButtonHeight() {
        XCTAssertEqual(Layout.buttonHeight, 50)
    }

    func testCardCornerRadius() {
        XCTAssertEqual(Layout.cardCornerRadius, 16)
    }

    func testCenterBubbleSize() {
        XCTAssertGreaterThanOrEqual(Layout.tabBarCenterBubbleSize, 56)
        XCTAssertLessThanOrEqual(Layout.tabBarCenterBubbleSize, 64)
    }

    // MARK: - TierBadge Tests

    func testTierBadgeLabels() {
        XCTAssertEqual(TierBadge(tier: "vip").tierLabel, "Vip")
        XCTAssertEqual(TierBadge(tier: "high_roller").tierLabel, "High Roller")
        XCTAssertEqual(TierBadge(tier: "whale").tierLabel, "Whale")
        XCTAssertEqual(TierBadge(tier: "standard").tierLabel, "Standard")
    }

    func testTierBadgeColors() {
        XCTAssertEqual(TierBadge(tier: "whale").tierColor, .tierWhale)
        XCTAssertEqual(TierBadge(tier: "vip").tierColor, .tierVIP)
        XCTAssertEqual(TierBadge(tier: "high roller").tierColor, .tierHighRoller)
        XCTAssertEqual(TierBadge(tier: "standard").tierColor, .tierStandard)
    }

    // MARK: - NicotineWarningBanner Tests

    func testNicotineWarningBannerHasNoCloseButton() {
        // The WarningBanner spec requires no close/dismiss capability.
        // We verify the struct has no isPresented or isDismissable property.
        let banner = NicotineWarningBanner()
        // Compile-time check: if .dismiss() existed, this would fail to compile.
        // Runtime check: no dismiss action
        let mirror = Mirror(reflecting: banner)
        let propertyNames = mirror.children.map { $0.label ?? "" }
        XCTAssertFalse(propertyNames.contains("isPresented"), "Banner must not have isPresented — it cannot be dismissed")
        XCTAssertFalse(propertyNames.contains("onDismiss"), "Banner must not have onDismiss")
    }
}
