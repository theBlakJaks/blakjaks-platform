import SwiftUI

// MARK: - InsightsMenuView
// Matches #s-home from app-mockup.html exactly.
// Layout: header block + 5 menu rows, each with a SwiftUI Canvas mini-chart on the left.
// NavigationStack with navigationDestination pushes sub-page views.

struct InsightsMenuView: View {
    @StateObject private var vm = InsightsViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.bgPrimary.ignoresSafeArea()

                VStack(spacing: 0) {
                    // MARK: Screen Header — matches #s-home .screen-hdr
                    screenHeader

                    // MARK: Menu List — matches #ins-menu
                    menuList
                }
            }
            .navigationBarHidden(true)
            .navigationDestination(for: InsightsSection.self) { section in
                section.destination(vm: vm)
            }
        }
        .environmentObject(vm)
    }

    // MARK: - Screen Header
    // CSS: #s-home .screen-hdr { background:#0A0A0A; padding:12px 16px 10px; border-bottom:1px solid #111; }
    // eyebrow: Sora 9px, #D4AF37, uppercase, tracking 4, opacity 0.7
    // title: Playfair Display 22px, bold, white

    private var screenHeader: some View {
        VStack(alignment: .leading, spacing: 1) {
            HStack {
                VStack(alignment: .leading, spacing: 1) {
                    Text("BLAKJAKS")
                        .font(BJFont.sora(9, weight: .bold))
                        .foregroundColor(Color.gold)
                        .tracking(4)
                        .opacity(0.7)
                        .textCase(.uppercase)

                    Text("Insights")
                        .font(BJFont.playfair(22, weight: .bold))
                        .foregroundColor(Color.textPrimary)
                }
                Spacer()
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 10)
        .background(Color.bgPrimary)
        .overlay(
            Rectangle()
                .fill(Color(red: 17/255, green: 17/255, blue: 17/255)) // #111
                .frame(height: 1),
            alignment: .bottom
        )
    }

    // MARK: - Menu List
    // CSS: #ins-menu { display:flex; flex-direction:column; gap:2px; padding:8px 0; }

    private var menuList: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 2) {
                ForEach(InsightsSection.allCases, id: \.self) { section in
                    NavigationLink(value: section) {
                        menuRow(for: section)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 8)
        }
    }

    // MARK: - Menu Row
    // CSS: .ins-menu-btn { display:flex; align-items:center; padding:16px 16px; border-bottom:1px solid #0d0d0d; }
    // Canvas: width:52px, height:36px, border-radius:6px, background:#0a0a0a, margin-right:14px
    // Title: Outfit 16px, weight:500, color:#e0e0e0
    // Arrow: color:#333, font-size:20px

    @ViewBuilder
    private func menuRow(for section: InsightsSection) -> some View {
        HStack(spacing: 0) {
            // Mini canvas visualization (52×36, dark bg, rounded 6pt)
            section.miniChart
                .frame(width: 52, height: 36)
                .background(Color(red: 10/255, green: 10/255, blue: 10/255)) // #0a0a0a
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .padding(.trailing, 14)

            // Title
            Text(section.title)
                .font(BJFont.outfit(16, weight: .medium))
                .foregroundColor(Color(red: 224/255, green: 224/255, blue: 224/255)) // #e0e0e0
                .frame(maxWidth: .infinity, alignment: .leading)

            // Arrow chevron ›
            Text("›")
                .font(.system(size: 20, weight: .light))
                .foregroundColor(Color(red: 51/255, green: 51/255, blue: 51/255)) // #333
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(Color.bgPrimary)
        .overlay(
            Rectangle()
                .fill(Color(red: 13/255, green: 13/255, blue: 13/255)) // #0d0d0d
                .frame(height: 1),
            alignment: .bottom
        )
    }
}

// MARK: - InsightsSection

enum InsightsSection: CaseIterable, Hashable {
    case overview, treasury, systems, comps, partners

    var title: String {
        switch self {
        case .overview:  return "Overview"
        case .treasury:  return "Treasury"
        case .systems:   return "Systems"
        case .comps:     return "Comps"
        case .partners:  return "Partners"
        }
    }

    @ViewBuilder
    var miniChart: some View {
        switch self {
        case .overview:  OverviewMiniChart()
        case .treasury:  TreasuryMiniChart()
        case .systems:   SystemsMiniChart()
        case .comps:     CompsMiniChart()
        case .partners:  PartnersMiniChart()
        }
    }

    @ViewBuilder
    func destination(vm: InsightsViewModel) -> some View {
        switch self {
        case .overview:  OverviewView().environmentObject(vm)
        case .treasury:  TreasuryView().environmentObject(vm)
        case .systems:   SystemsView().environmentObject(vm)
        case .comps:     CompsView().environmentObject(vm)
        case .partners:  PartnersView().environmentObject(vm)
        }
    }
}

// MARK: - Gold color shorthand

private let gold = Color(red: 212/255, green: 175/255, blue: 55/255) // #D4AF37

// MARK: - OverviewMiniChart
// ECG/waveform line in gold — mimics the animated radar waveform canvas

struct OverviewMiniChart: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width
            let h = size.height
            let midY = h * 0.5

            // ECG-style waveform path
            var path = Path()
            path.move(to: CGPoint(x: 0, y: midY))
            path.addLine(to: CGPoint(x: w * 0.10, y: midY))
            // Small blip up
            path.addLine(to: CGPoint(x: w * 0.18, y: midY - h * 0.12))
            path.addLine(to: CGPoint(x: w * 0.22, y: midY))
            // Main QRS complex
            path.addLine(to: CGPoint(x: w * 0.30, y: midY + h * 0.10))
            path.addLine(to: CGPoint(x: w * 0.36, y: midY - h * 0.38))
            path.addLine(to: CGPoint(x: w * 0.40, y: midY + h * 0.18))
            path.addLine(to: CGPoint(x: w * 0.46, y: midY))
            // T-wave
            path.addCurve(
                to: CGPoint(x: w * 0.60, y: midY),
                control1: CGPoint(x: w * 0.50, y: midY - h * 0.18),
                control2: CGPoint(x: w * 0.56, y: midY - h * 0.18)
            )
            // Trailing flat
            path.addLine(to: CGPoint(x: w * 0.68, y: midY))
            // Second smaller blip
            path.addLine(to: CGPoint(x: w * 0.74, y: midY - h * 0.10))
            path.addLine(to: CGPoint(x: w * 0.78, y: midY))
            path.addLine(to: CGPoint(x: w, y: midY))

            ctx.stroke(
                path,
                with: .color(gold),
                style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round)
            )
        }
    }
}

// MARK: - TreasuryMiniChart
// Candlestick-style vertical bars in gold

struct TreasuryMiniChart: View {
    // bar (x-fraction, height-fraction, isUp)
    private let bars: [(CGFloat, CGFloat)] = [
        (0.12, 0.45),
        (0.28, 0.65),
        (0.44, 0.35),
        (0.60, 0.75),
        (0.76, 0.55)
    ]

    var body: some View {
        Canvas { ctx, size in
            let w = size.width
            let h = size.height
            let barW: CGFloat = 5
            let baseY = h - 4

            for (xFrac, hFrac) in bars {
                let barH = hFrac * (h - 8)
                let x = xFrac * w - barW / 2
                let rect = CGRect(x: x, y: baseY - barH, width: barW, height: barH)

                // Fill bar
                ctx.fill(
                    Path(roundedRect: rect, cornerRadius: 1),
                    with: .color(gold.opacity(0.6))
                )

                // Top line (wick)
                var wick = Path()
                let cx = x + barW / 2
                wick.move(to: CGPoint(x: cx, y: baseY - barH - 3))
                wick.addLine(to: CGPoint(x: cx, y: baseY - barH))
                ctx.stroke(wick, with: .color(gold), lineWidth: 1)
            }
        }
    }
}

// MARK: - SystemsMiniChart
// Network nodes: 3 dots connected by lines in gold

struct SystemsMiniChart: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width
            let h = size.height

            // Node positions (fractions of canvas size)
            let nodes: [CGPoint] = [
                CGPoint(x: w * 0.15, y: h * 0.50),  // left
                CGPoint(x: w * 0.50, y: h * 0.20),  // top center
                CGPoint(x: w * 0.85, y: h * 0.50),  // right
                CGPoint(x: w * 0.50, y: h * 0.80),  // bottom center
            ]

            // Edges connecting nodes
            let edges: [(Int, Int)] = [(0,1),(1,2),(2,3),(3,0),(0,2),(1,3)]
            for (a, b) in edges {
                var line = Path()
                line.move(to: nodes[a])
                line.addLine(to: nodes[b])
                ctx.stroke(line, with: .color(gold.opacity(0.35)), lineWidth: 1)
            }

            // Draw nodes on top
            let dotRadius: CGFloat = 3
            for node in nodes {
                let dotRect = CGRect(
                    x: node.x - dotRadius,
                    y: node.y - dotRadius,
                    width: dotRadius * 2,
                    height: dotRadius * 2
                )
                ctx.fill(Path(ellipseIn: dotRect), with: .color(gold))
            }
        }
    }
}

// MARK: - CompsMiniChart
// 4 vertical bars (bar chart) in gold

struct CompsMiniChart: View {
    private let heights: [CGFloat] = [0.55, 0.80, 0.40, 0.65]
    private let xFractions: [CGFloat] = [0.14, 0.36, 0.58, 0.80]

    var body: some View {
        Canvas { ctx, size in
            let w = size.width
            let h = size.height
            let barW: CGFloat = 7
            let baseY = h - 3

            for (i, hFrac) in heights.enumerated() {
                let barH = hFrac * (h - 6)
                let x = xFractions[i] * w - barW / 2
                let rect = CGRect(x: x, y: baseY - barH, width: barW, height: barH)
                ctx.fill(
                    Path(roundedRect: rect, cornerRadius: 1.5),
                    with: .color(gold.opacity(0.75))
                )
                // Bright top highlight
                let highlight = CGRect(x: x, y: baseY - barH, width: barW, height: 2)
                ctx.fill(Path(roundedRect: highlight, cornerRadius: 1), with: .color(gold))
            }
        }
    }
}

// MARK: - PartnersMiniChart
// 5-point radar / spider outline in gold

struct PartnersMiniChart: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width
            let h = size.height
            let cx = w / 2
            let cy = h / 2
            let outerR = min(w, h) * 0.40
            let innerR  = outerR * 0.45
            let points  = 5

            // Build outer star polygon points, alternating outer/inner radius
            var outer = Path()
            var inner = Path()

            for ring in 0..<2 {
                let r = ring == 0 ? outerR : innerR
                var p = Path()
                for i in 0..<points {
                    let angle = (CGFloat(i) / CGFloat(points)) * .pi * 2 - .pi / 2
                    let x = cx + r * cos(angle)
                    let y = cy + r * sin(angle)
                    if i == 0 { p.move(to: CGPoint(x: x, y: y)) }
                    else       { p.addLine(to: CGPoint(x: x, y: y)) }
                }
                p.closeSubpath()
                if ring == 0 { outer = p } else { inner = p }
            }

            // Draw inner (web)
            ctx.stroke(inner, with: .color(gold.opacity(0.30)), lineWidth: 1)

            // Draw spokes
            for i in 0..<points {
                let angle = (CGFloat(i) / CGFloat(points)) * .pi * 2 - .pi / 2
                let ox = cx + outerR * cos(angle)
                let oy = cy + outerR * sin(angle)
                var spoke = Path()
                spoke.move(to: CGPoint(x: cx, y: cy))
                spoke.addLine(to: CGPoint(x: ox, y: oy))
                ctx.stroke(spoke, with: .color(gold.opacity(0.25)), lineWidth: 0.8)
            }

            // Draw filled data polygon (random-ish shape inside)
            let dataFractions: [CGFloat] = [0.85, 0.60, 0.75, 0.55, 0.90]
            var data = Path()
            for i in 0..<points {
                let angle = (CGFloat(i) / CGFloat(points)) * .pi * 2 - .pi / 2
                let r = outerR * dataFractions[i]
                let x = cx + r * cos(angle)
                let y = cy + r * sin(angle)
                if i == 0 { data.move(to: CGPoint(x: x, y: y)) }
                else       { data.addLine(to: CGPoint(x: x, y: y)) }
            }
            data.closeSubpath()
            ctx.fill(data, with: .color(gold.opacity(0.12)))
            ctx.stroke(data, with: .color(gold), style: StrokeStyle(lineWidth: 1.2, lineJoin: .round))
        }
    }
}

// MARK: - Preview

#Preview {
    InsightsMenuView()
        .preferredColorScheme(.dark)
}
