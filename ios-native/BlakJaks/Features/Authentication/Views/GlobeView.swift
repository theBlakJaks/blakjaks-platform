import SwiftUI
import SceneKit

// MARK: - GlobeView
// SceneKit-based 3D globe with country outlines, pulsing beacons,
// and animated arcs between cities. Translated from the Three.js prototype.

struct GlobeSceneView: UIViewRepresentable {

    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.backgroundColor = .clear
        scnView.antialiasingMode = .multisampling4X
        scnView.isUserInteractionEnabled = false
        scnView.autoenablesDefaultLighting = false

        let scene = SCNScene()
        scnView.scene = scene

        // Camera
        let camNode = SCNNode()
        camNode.camera = SCNCamera()
        camNode.camera?.fieldOfView = 42
        camNode.camera?.zNear = 0.1
        camNode.camera?.zFar = 200
        camNode.position = SCNVector3(0, 0, 3.2)
        scene.rootNode.addChildNode(camNode)

        // Ambient light
        let ambient = SCNNode()
        ambient.light = SCNLight()
        ambient.light?.type = .ambient
        ambient.light?.color = UIColor(white: 0.35, alpha: 1)
        scene.rootNode.addChildNode(ambient)

        // Directional light (subtle)
        let dirLight = SCNNode()
        dirLight.light = SCNLight()
        dirLight.light?.type = .directional
        dirLight.light?.color = UIColor(red: 0.83, green: 0.69, blue: 0.22, alpha: 0.3)
        dirLight.light?.intensity = 200
        dirLight.position = SCNVector3(5, 5, 5)
        dirLight.look(at: SCNVector3Zero)
        scene.rootNode.addChildNode(dirLight)

        // Build globe hierarchy: scene -> tiltNode -> spinNode -> globe contents
        let coordinator = context.coordinator
        coordinator.buildGlobe(scene: scene)

        // Start animation loop
        scnView.delegate = coordinator
        scnView.isPlaying = true
        scnView.preferredFramesPerSecond = 60

        return scnView
    }

    func updateUIView(_ uiView: SCNView, context: Context) {}

    func makeCoordinator() -> GlobeCoordinator {
        GlobeCoordinator()
    }
}

// MARK: - City Data

private struct CityData {
    let name: String
    let lat: Float
    let lng: Float
}

private let cities: [CityData] = [
    CityData(name: "New York",    lat: 40.7,  lng: -74.0),
    CityData(name: "London",      lat: 51.5,  lng: -0.12),
    CityData(name: "Dubai",       lat: 25.2,  lng: 55.3),
    CityData(name: "Mumbai",      lat: 19.1,  lng: 72.9),
    CityData(name: "Tokyo",       lat: 35.7,  lng: 139.7),
    CityData(name: "Sydney",      lat: -33.9, lng: 151.2),
    CityData(name: "Sao Paulo",   lat: -23.5, lng: -46.6),
    CityData(name: "Lagos",       lat: 6.5,   lng: 3.4),
    CityData(name: "Seoul",       lat: 37.6,  lng: 127.0),
    CityData(name: "Mexico City", lat: 19.4,  lng: -99.1),
]

// Primary arc route order (indices into cities array)
private let arcOrder = [0, 5, 1, 4, 6, 8, 7, 9, 3, 2, 0]

// MARK: - Helpers

private let deg2rad: Float = .pi / 180

private func ll2v(_ lat: Float, _ lng: Float, _ r: Float) -> SCNVector3 {
    let la = lat * deg2rad
    let lo = lng * deg2rad
    return SCNVector3(
        r * cos(la) * cos(lo),
        r * cos(la) * sin(lo),
        r * sin(la)
    )
}

private func targetSpin(for city: CityData) -> Float {
    return -.pi / 2 - city.lng * deg2rad
}

private func targetTilt(for city: CityData) -> Float {
    return -.pi / 2 + city.lat * deg2rad
}

private func shortAngle(from: Float, to: Float) -> Float {
    var d = to - from
    while d > .pi { d -= 2 * .pi }
    while d < -.pi { d += 2 * .pi }
    return d
}

private func smoothstep(_ t: Float) -> Float {
    let c = min(max(t, 0), 1)
    return c * c * (3 - 2 * c)
}

// MARK: - Globe Coordinator

final class GlobeCoordinator: NSObject, SCNSceneRendererDelegate {

    private var tiltNode = SCNNode()
    private var spinNode = SCNNode()
    private var beaconNodes: [SCNNode] = []
    private var startTime: TimeInterval = -1

    // Arc data — line node geometry is rebuilt each frame to show a dissolving trail
    private struct ArcData {
        let lineNode: SCNNode      // holds the trail (geometry rebuilt per-frame)
        let chipNode: SCNNode      // 3D casino chip traveling along the arc
        let points: [SCNVector3]   // 81 points along the arc path
        let srcIdx: Int
        let dstIdx: Int
        let duration: Float        // computed from path length for constant speed
        let startOffset: Float     // cumulative start time within the cycle
    }
    private var primaryArcs: [ArcData] = []

    // Sporadic arcs
    private struct SporadicArc {
        var lineNode: SCNNode?
        var chipNode: SCNNode?
        var points: [SCNVector3]
        var startTime: Float
        var duration: Float
        var srcIdx: Int
        var dstIdx: Int
    }
    private var sporadicArcs: [SporadicArc] = []
    private let sporadicCount = 10

    // Rotation tracking
    private var currentSpin: Float = 0
    private var currentTilt: Float = 0

    // Trail index caching — only rebuild geometry when indices change
    private var primaryTrailCache: [(head: Int, tail: Int)] = []
    private var sporadicTrailCache: [(head: Int, tail: Int)] = []

    // Constants
    private let arcPause: Float = 0.3
    private let chipSpeed: Float = 0.25   // units per second — constant for all chips
    private var cycleTime: Float = 0

    func buildGlobe(scene: SCNScene) {
        // Hierarchy: scene -> tiltNode -> spinNode
        let firstCity = cities[arcOrder[0]]
        currentSpin = targetSpin(for: firstCity)
        currentTilt = targetTilt(for: firstCity)

        tiltNode = SCNNode()
        tiltNode.eulerAngles.x = currentTilt
        scene.rootNode.addChildNode(tiltNode)

        spinNode = SCNNode()
        spinNode.eulerAngles.z = currentSpin
        tiltNode.addChildNode(spinNode)

        buildOceanSphere()
        buildWireframeGrid()
        buildCountryOutlines()
        buildCountryFill()
        buildBeacons()
        buildPrimaryArcs()
        buildSporadicArcs()
        buildStars(scene: scene)

        // Cycle time is the sum of all per-arc durations + pauses
        cycleTime = primaryArcs.reduce(0) { $0 + $1.duration + arcPause }

        // Init trail caches
        primaryTrailCache = Array(repeating: (head: -1, tail: -1), count: primaryArcs.count)
        sporadicTrailCache = Array(repeating: (head: -1, tail: -1), count: sporadicCount)
    }

    /// Total path length of an arc's point array.
    private func arcLength(_ points: [SCNVector3]) -> Float {
        var total: Float = 0
        for i in 1..<points.count {
            let dx = points[i].x - points[i-1].x
            let dy = points[i].y - points[i-1].y
            let dz = points[i].z - points[i-1].z
            total += sqrt(dx*dx + dy*dy + dz*dz)
        }
        return total
    }

    // MARK: - Ocean

    private func buildOceanSphere() {
        let sphere = SCNSphere(radius: 0.997)
        sphere.segmentCount = 96
        let mat = SCNMaterial()
        // Navy blue ocean with warm amber undertone
        mat.diffuse.contents = UIColor(red: 0.04, green: 0.06, blue: 0.16, alpha: 1)
        mat.emission.contents = UIColor(red: 0.03, green: 0.04, blue: 0.10, alpha: 1)
        mat.emission.intensity = 0.7
        mat.roughness.contents = 0.7
        mat.metalness.contents = 0.2
        sphere.materials = [mat]
        let node = SCNNode(geometry: sphere)
        spinNode.addChildNode(node)
    }

    // MARK: - Wireframe Grid

    private func buildWireframeGrid() {
        let sphere = SCNSphere(radius: 0.999)
        sphere.segmentCount = 36
        let mat = SCNMaterial()
        mat.fillMode = .lines
        mat.diffuse.contents = UIColor(red: 0.83, green: 0.69, blue: 0.22, alpha: 0.03)
        mat.isDoubleSided = true
        mat.writesToDepthBuffer = false
        sphere.materials = [mat]
        let node = SCNNode(geometry: sphere)
        spinNode.addChildNode(node)
    }

    // MARK: - Country Outlines

    private func buildCountryOutlines() {
        guard let vertData = loadBundleData("globe_vert"),
              let edgeData = loadBundleData("globe_edge") else { return }

        let vertices = vertData.withUnsafeBytes { Array($0.bindMemory(to: Float.self)) }
        let edges = edgeData.withUnsafeBytes { Array($0.bindMemory(to: UInt16.self)) }

        let vertCount = vertices.count / 3
        var scnVerts: [SCNVector3] = []
        scnVerts.reserveCapacity(vertCount)
        for i in 0..<vertCount {
            scnVerts.append(SCNVector3(vertices[i*3], vertices[i*3+1], vertices[i*3+2]))
        }

        let vertSource = SCNGeometrySource(vertices: scnVerts)

        // Build line segments: each edge pair = 2 indices
        let indexData = Data(bytes: edges, count: edges.count * MemoryLayout<UInt16>.size)
        let element = SCNGeometryElement(
            data: indexData,
            primitiveType: .line,
            primitiveCount: edges.count / 2,
            bytesPerIndex: MemoryLayout<UInt16>.size
        )

        let amber = Self.uiGoldAmber

        // Soft additive glow layers — just above the country fill (1.003)
        let glowLayers: [(scale: Float, opacity: CGFloat)] = [
            (1.0031, 0.15),
            (1.0032, 0.25),
            (1.0033, 0.35),
        ]
        for layer in glowLayers {
            let geo = SCNGeometry(sources: [vertSource], elements: [element])
            let mat = SCNMaterial()
            mat.emission.contents = amber
            mat.emission.intensity = 1.0
            mat.diffuse.contents = UIColor.clear
            mat.transparency = layer.opacity
            mat.writesToDepthBuffer = false
            mat.readsFromDepthBuffer = true
            mat.blendMode = .add
            mat.isDoubleSided = true
            geo.materials = [mat]

            let node = SCNNode(geometry: geo)
            node.scale = SCNVector3(layer.scale, layer.scale, layer.scale)
            spinNode.addChildNode(node)
        }

        // Solid bright goldAmber outline on top — the main visible border
        let outlineGeo = SCNGeometry(sources: [vertSource], elements: [element])
        let outlineMat = SCNMaterial()
        outlineMat.diffuse.contents = amber
        outlineMat.emission.contents = amber
        outlineMat.emission.intensity = 1.2
        outlineMat.transparency = 1.0
        outlineMat.writesToDepthBuffer = false
        outlineMat.readsFromDepthBuffer = true
        outlineMat.lightingModel = .constant
        outlineMat.isDoubleSided = true
        outlineGeo.materials = [outlineMat]

        let outlineNode = SCNNode(geometry: outlineGeo)
        outlineNode.scale = SCNVector3(1.0034, 1.0034, 1.0034)
        spinNode.addChildNode(outlineNode)
    }

    // MARK: - Country Fill (black polygons behind outlines)

    private func buildCountryFill() {
        guard let normVertData = loadBundleData("globe_norm_vert"),
              let idxData = loadBundleData("globe_idx") else { return }

        let verts = normVertData.withUnsafeBytes { Array($0.bindMemory(to: Float.self)) }
        let indices = idxData.withUnsafeBytes { Array($0.bindMemory(to: UInt16.self)) }

        let vertCount = verts.count / 3
        var scnVerts: [SCNVector3] = []
        scnVerts.reserveCapacity(vertCount)
        for i in 0..<vertCount {
            scnVerts.append(SCNVector3(verts[i*3], verts[i*3+1], verts[i*3+2]))
        }

        let vertSource = SCNGeometrySource(vertices: scnVerts)
        let indexData = Data(bytes: indices, count: indices.count * MemoryLayout<UInt16>.size)
        let element = SCNGeometryElement(
            data: indexData,
            primitiveType: .triangles,
            primitiveCount: indices.count / 3,
            bytesPerIndex: MemoryLayout<UInt16>.size
        )

        let geo = SCNGeometry(sources: [vertSource], elements: [element])
        let mat = SCNMaterial()
        mat.diffuse.contents = UIColor.black
        mat.isDoubleSided = true
        geo.materials = [mat]

        let node = SCNNode(geometry: geo)
        node.scale = SCNVector3(1.003, 1.003, 1.003)
        spinNode.addChildNode(node)
    }

    // MARK: - Beacons

    // #CC8F17 as UIColor
    private static let uiGoldAmber = UIColor(red: 204/255, green: 143/255, blue: 23/255, alpha: 1)

    private func buildBeacons() {
        beaconNodes = []
        for city in cities {
            let pos = ll2v(city.lat, city.lng, 1.012)

            // Glowing amber/gold dot
            let sphere = SCNSphere(radius: 0.014)
            sphere.segmentCount = 12
            let mat = SCNMaterial()
            mat.diffuse.contents = Self.uiGoldAmber
            mat.emission.contents = Self.uiGoldAmber
            mat.emission.intensity = 0.8
            mat.transparency = 1.0
            mat.writesToDepthBuffer = false
            mat.blendMode = .alpha
            mat.lightingModel = .constant
            sphere.materials = [mat]

            let node = SCNNode(geometry: sphere)
            node.position = pos
            spinNode.addChildNode(node)

            beaconNodes.append(node)
        }
    }

    // MARK: - Stars

    private func buildStars(scene: SCNScene) {
        var positions: [SCNVector3] = []
        for _ in 0..<1500 {
            let r: Float = 40 + Float.random(in: 0...100)
            let theta = Float.random(in: 0...(2 * .pi))
            let phi = acos(2 * Float.random(in: 0...1) - 1)
            positions.append(SCNVector3(
                r * sin(phi) * cos(theta),
                r * sin(phi) * sin(theta),
                r * cos(phi)
            ))
        }

        let source = SCNGeometrySource(vertices: positions)
        let indices: [UInt32] = Array(0..<UInt32(positions.count))
        let indexData = Data(bytes: indices, count: indices.count * MemoryLayout<UInt32>.size)
        let element = SCNGeometryElement(
            data: indexData,
            primitiveType: .point,
            primitiveCount: positions.count,
            bytesPerIndex: MemoryLayout<UInt32>.size
        )
        element.pointSize = 1.5
        element.minimumPointScreenSpaceRadius = 0.5
        element.maximumPointScreenSpaceRadius = 2.0

        let geo = SCNGeometry(sources: [source], elements: [element])
        let mat = SCNMaterial()
        mat.emission.contents = UIColor(red: 0.83, green: 0.69, blue: 0.22, alpha: 0.2)
        mat.diffuse.contents = UIColor.clear
        mat.writesToDepthBuffer = false
        mat.blendMode = .add
        geo.materials = [mat]

        let node = SCNNode(geometry: geo)
        scene.rootNode.addChildNode(node)
    }

    // MARK: - Arc Building

    private func createArcPoints(srcIdx: Int, dstIdx: Int) -> [SCNVector3] {
        let src = ll2v(cities[srcIdx].lat, cities[srcIdx].lng, 1.01)
        let dst = ll2v(cities[dstIdx].lat, cities[dstIdx].lng, 1.01)
        let dist = length(SIMD3<Float>(dst.x - src.x, dst.y - src.y, dst.z - src.z))

        var pts: [SCNVector3] = []
        let segments = 80
        for s in 0...segments {
            let t = Float(s) / Float(segments)
            // Lerp then normalize to sphere surface
            let lx = src.x + (dst.x - src.x) * t
            let ly = src.y + (dst.y - src.y) * t
            let lz = src.z + (dst.z - src.z) * t
            let len = sqrt(lx*lx + ly*ly + lz*lz)
            let altitude: Float = 1.0 + dist * 0.06 * sin(t * .pi)
            let nx = lx / len * altitude
            let ny = ly / len * altitude
            let nz = lz / len * altitude
            pts.append(SCNVector3(nx, ny, nz))
        }
        return pts
    }

    // Cached flattened chip template — built once, cloned for each arc.
    // flattenedClone() merges all sub-nodes into a single draw call.
    private lazy var chipTemplate: SCNNode = {
        let assembly = SCNNode()

        // PBR gold — #CC8F17 logo amber gold
        let gold = SCNMaterial()
        gold.lightingModel = .physicallyBased
        gold.diffuse.contents = Self.uiGoldAmber
        gold.metalness.contents = NSNumber(value: 0.92)
        gold.roughness.contents = NSNumber(value: 0.18)
        gold.emission.contents = UIColor(red: 0.05, green: 0.028, blue: 0.002, alpha: 1)

        // Dark body
        let dark = SCNMaterial()
        dark.lightingModel = .physicallyBased
        dark.diffuse.contents = UIColor(white: 0.10, alpha: 1)
        dark.metalness.contents = NSNumber(value: 0.3)
        dark.roughness.contents = NSNumber(value: 0.7)

        // Cylinder body
        let cyl = SCNCylinder(radius: 1.0, height: 0.15)
        cyl.radialSegmentCount = 24
        cyl.materials = [dark, dark, dark]
        assembly.addChildNode(SCNNode(geometry: cyl))

        // Outer torus rings
        let outerTorus = SCNTorus()
        outerTorus.ringRadius = 0.97
        outerTorus.pipeRadius = 0.04
        outerTorus.ringSegmentCount = 24
        outerTorus.pipeSegmentCount = 8
        outerTorus.materials = [gold]
        for yOff: Float in [0.075, -0.075] {
            let n = SCNNode(geometry: outerTorus)
            n.position = SCNVector3(0, yOff, 0)
            assembly.addChildNode(n)
        }

        // Inner torus rings
        let innerTorus = SCNTorus()
        innerTorus.ringRadius = 0.5
        innerTorus.pipeRadius = 0.025
        innerTorus.ringSegmentCount = 24
        innerTorus.pipeSegmentCount = 8
        innerTorus.materials = [gold]
        for yOff: Float in [0.078, -0.078] {
            let n = SCNNode(geometry: innerTorus)
            n.position = SCNVector3(0, yOff, 0)
            assembly.addChildNode(n)
        }

        // 16 edge inlays
        let box = SCNBox(width: 0.08, height: 0.16, length: 0.12, chamferRadius: 0)
        box.materials = [gold]
        for i in 0..<16 {
            let a = Float(i) / 16 * .pi * 2
            let n = SCNNode(geometry: box)
            n.position = SCNVector3(cos(a) * 0.95, 0, sin(a) * 0.95)
            n.eulerAngles = SCNVector3(0, -a + .pi / 2, 0)
            assembly.addChildNode(n)
        }

        // Flatten all sub-geometry into a single draw call
        return assembly.flattenedClone()
    }()

    /// Stamp out a chip clone from the cached flattened template.
    private func makeChipNode() -> SCNNode {
        let wrapper = SCNNode()
        wrapper.isHidden = true

        let chip = chipTemplate.clone()
        let s: Float = 0.018
        chip.scale = SCNVector3(s, s, s)
        chip.eulerAngles.x = .pi / 2

        // Smooth spin via SCNAction — runs on the GPU render thread
        let spin = SCNAction.rotateBy(x: 0, y: .pi * 2, z: 0, duration: 2.0)
        spin.timingMode = .linear
        chip.runAction(.repeatForever(spin))

        wrapper.addChildNode(chip)
        return wrapper
    }

    /// Build solid line trail geometry for a sub-range of arc points [tailIdx...headIdx].
    private func makeTrailGeometry(points: [SCNVector3], tailIdx: Int, headIdx: Int, opacity: CGFloat) -> SCNGeometry? {
        guard headIdx > tailIdx else { return nil }
        let segCount = headIdx - tailIdx
        var verts: [SCNVector3] = []
        verts.reserveCapacity(segCount * 2)
        for s in tailIdx..<headIdx {
            verts.append(points[s])
            verts.append(points[s + 1])
        }
        let source = SCNGeometrySource(vertices: verts)
        let indices: [UInt32] = Array(0..<UInt32(verts.count))
        let idxData = Data(bytes: indices, count: indices.count * MemoryLayout<UInt32>.size)
        let element = SCNGeometryElement(
            data: idxData, primitiveType: .line,
            primitiveCount: segCount, bytesPerIndex: MemoryLayout<UInt32>.size
        )
        let geo = SCNGeometry(sources: [source], elements: [element])
        let mat = SCNMaterial()
        mat.diffuse.contents = Self.uiGoldAmber
        mat.emission.contents = Self.uiGoldAmber
        mat.emission.intensity = 0.8
        mat.transparency = opacity
        mat.writesToDepthBuffer = false
        mat.blendMode = .alpha
        mat.lightingModel = .constant
        geo.materials = [mat]
        return geo
    }

    private func buildPrimaryArcs() {
        primaryArcs = []
        var cumulative: Float = 0
        for i in 0..<(arcOrder.count - 1) {
            let srcIdx = arcOrder[i]
            let dstIdx = arcOrder[i + 1]
            let points = createArcPoints(srcIdx: srcIdx, dstIdx: dstIdx)
            let dur = arcLength(points) / chipSpeed

            let lineNode = SCNNode()
            lineNode.isHidden = true
            spinNode.addChildNode(lineNode)

            let chipNode = makeChipNode()
            spinNode.addChildNode(chipNode)

            primaryArcs.append(ArcData(
                lineNode: lineNode, chipNode: chipNode, points: points,
                srcIdx: srcIdx, dstIdx: dstIdx,
                duration: dur, startOffset: cumulative
            ))
            cumulative += dur + arcPause
        }
    }

    private func buildSporadicArcs() {
        sporadicArcs = []
        for i in 0..<sporadicCount {
            var arc = SporadicArc(lineNode: nil, chipNode: nil, points: [],
                                  startTime: Float(i) * 0.7 + Float.random(in: 0...2),
                                  duration: 2.5 + Float.random(in: 0...4),
                                  srcIdx: 0, dstIdx: 1)
            spawnSporadicArc(&arc)
            sporadicArcs.append(arc)
        }
    }

    private func spawnSporadicArc(_ arc: inout SporadicArc) {
        arc.lineNode?.removeFromParentNode()
        arc.chipNode?.removeFromParentNode()

        let n = cities.count
        var s = Int.random(in: 0..<n)
        var d = Int.random(in: 0..<n)
        if d == s { d = (d + 1) % n }
        arc.srcIdx = s
        arc.dstIdx = d

        let points = createArcPoints(srcIdx: s, dstIdx: d)
        arc.points = points

        let lineNode = SCNNode()
        lineNode.isHidden = true
        spinNode.addChildNode(lineNode)

        let chipNode = makeChipNode()
        spinNode.addChildNode(chipNode)

        arc.lineNode = lineNode
        arc.chipNode = chipNode
        arc.duration = arcLength(points) / chipSpeed
    }

    // MARK: - Animation Loop

    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        if startTime < 0 { startTime = time }
        let now = Float(time - startTime)

        animateBeacons(now: now)
        animatePrimaryArcs(now: now)
        animateSporadicArcs(now: now)
        animateGlobeRotation(now: now)
    }

    private func animateBeacons(now: Float) {
        for (i, node) in beaconNodes.enumerated() {
            let pulse = sin(now * 2.5 + Float(i) * 0.9) * 0.5 + 0.5
            let s: Float = 0.9 + pulse * 0.3
            node.scale = SCNVector3(s, s, s)
            node.geometry?.firstMaterial?.transparency = CGFloat(0.75 + pulse * 0.25)
        }
    }

    /// Interpolate smoothly between arc points for sub-frame chip positioning.
    private func interpolatedPoint(_ points: [SCNVector3], progress: Float) -> SCNVector3 {
        let segs = points.count - 1
        let exact = progress * Float(segs)
        let lo = min(Int(exact), segs)
        let hi = min(lo + 1, segs)
        let f = exact - Float(lo)
        return SCNVector3(
            points[lo].x + (points[hi].x - points[lo].x) * f,
            points[lo].y + (points[hi].y - points[lo].y) * f,
            points[lo].z + (points[hi].z - points[lo].z) * f
        )
    }

    /// Compute head and tail indices for the dissolving trail effect.
    /// Head moves at constant speed (linear). Tail stays anchored at the
    /// source for the first 75%, then dissolves smoothly over the final 25%.
    private func trailIndices(progress: Float, segCount: Int) -> (headIdx: Int, tailIdx: Int) {
        // Linear head — constant speed, no acceleration/deceleration
        let headIdx = min(Int(progress * Float(segCount)), segCount)

        // Tail stays at 0 until 75%, then smoothly ramps to segCount over the final 25%
        let tailRaw = max(0, (progress - 0.75) / 0.25)
        let tailP = smoothstep(min(tailRaw, 1.0))
        let tailIdx = min(Int(tailP * Float(segCount)), segCount)

        return (headIdx, tailIdx)
    }

    private func animatePrimaryArcs(now: Float) {
        let cycleT = now.truncatingRemainder(dividingBy: cycleTime)

        // Find which arc is active based on cumulative start offsets
        var activeIdx = primaryArcs.count - 1
        for (i, arc) in primaryArcs.enumerated() {
            if cycleT < arc.startOffset + arc.duration + arcPause {
                activeIdx = i
                break
            }
        }

        for (i, arc) in primaryArcs.enumerated() {
            let arcT = cycleT - arc.startOffset

            if i == activeIdx && arcT >= 0 && arcT < arc.duration {
                let progress = arcT / arc.duration
                let segs = arc.points.count - 1
                let (headIdx, tailIdx) = trailIndices(progress: progress, segCount: segs)

                // Only rebuild trail geometry when indices change
                let cached = primaryTrailCache[i]
                if headIdx != cached.head || tailIdx != cached.tail {
                    primaryTrailCache[i] = (head: headIdx, tail: tailIdx)
                    if let geo = makeTrailGeometry(points: arc.points, tailIdx: tailIdx, headIdx: headIdx, opacity: 0.85) {
                        arc.lineNode.geometry = geo
                        arc.lineNode.isHidden = false
                    } else {
                        arc.lineNode.isHidden = true
                    }
                }

                // Sub-frame interpolated chip position with GPU-smoothed movement
                let chipPos = interpolatedPoint(arc.points, progress: progress)
                SCNTransaction.begin()
                SCNTransaction.animationDuration = 1.0 / 60.0
                SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .linear)
                arc.chipNode.position = chipPos
                SCNTransaction.commit()
                arc.chipNode.isHidden = false

            } else {
                if !arc.lineNode.isHidden {
                    arc.lineNode.isHidden = true
                    arc.lineNode.geometry = nil
                    primaryTrailCache[i] = (head: -1, tail: -1)
                }
                arc.chipNode.isHidden = true
            }
        }
    }

    private func animateSporadicArcs(now: Float) {
        for i in 0..<sporadicArcs.count {
            let elapsed = now - sporadicArcs[i].startTime
            let dur = sporadicArcs[i].duration
            let pauseAfter: Float = 0.5

            if elapsed > dur + pauseAfter {
                spawnSporadicArc(&sporadicArcs[i])
                sporadicArcs[i].startTime = now + Float.random(in: 0...2.5)
                sporadicArcs[i].lineNode?.isHidden = true
                sporadicArcs[i].chipNode?.isHidden = true
                if i < sporadicTrailCache.count { sporadicTrailCache[i] = (head: -1, tail: -1) }
                continue
            }

            if elapsed < 0 {
                sporadicArcs[i].lineNode?.isHidden = true
                sporadicArcs[i].chipNode?.isHidden = true
                continue
            }

            if elapsed < dur {
                let progress = elapsed / dur
                let pts = sporadicArcs[i].points
                let segs = pts.count - 1
                let (headIdx, tailIdx) = trailIndices(progress: progress, segCount: segs)

                // Only rebuild when indices change
                if i < sporadicTrailCache.count {
                    let cached = sporadicTrailCache[i]
                    if headIdx != cached.head || tailIdx != cached.tail {
                        sporadicTrailCache[i] = (head: headIdx, tail: tailIdx)
                        if let geo = makeTrailGeometry(points: pts, tailIdx: tailIdx, headIdx: headIdx, opacity: 0.5) {
                            sporadicArcs[i].lineNode?.geometry = geo
                            sporadicArcs[i].lineNode?.isHidden = false
                        } else {
                            sporadicArcs[i].lineNode?.isHidden = true
                        }
                    }
                }

                let chipPos = interpolatedPoint(pts, progress: progress)
                SCNTransaction.begin()
                SCNTransaction.animationDuration = 1.0 / 60.0
                SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .linear)
                sporadicArcs[i].chipNode?.position = chipPos
                SCNTransaction.commit()
                sporadicArcs[i].chipNode?.isHidden = false
            } else {
                if sporadicArcs[i].lineNode?.isHidden == false {
                    sporadicArcs[i].lineNode?.isHidden = true
                    sporadicArcs[i].lineNode?.geometry = nil
                    if i < sporadicTrailCache.count { sporadicTrailCache[i] = (head: -1, tail: -1) }
                }
                sporadicArcs[i].chipNode?.isHidden = true
            }
        }
    }

    private func animateGlobeRotation(now: Float) {
        let cycleT = now.truncatingRemainder(dividingBy: cycleTime)

        // Find active arc using cumulative offsets
        var activeIdx = primaryArcs.count - 1
        for (i, arc) in primaryArcs.enumerated() {
            if cycleT < arc.startOffset + arc.duration + arcPause {
                activeIdx = i
                break
            }
        }

        let arc = primaryArcs[activeIdx]
        let arcT = cycleT - arc.startOffset
        let progress = min(max(arcT / arc.duration, 0), 1.0)

        // Interpolate between arc points for sub-frame smoothness
        let segs = arc.points.count - 1
        let exactIdx = progress * Float(segs)
        let lo = min(Int(exactIdx), segs)
        let hi = min(lo + 1, segs)
        let frac = exactIdx - Float(lo)
        let pt = SCNVector3(
            arc.points[lo].x + (arc.points[hi].x - arc.points[lo].x) * frac,
            arc.points[lo].y + (arc.points[hi].y - arc.points[lo].y) * frac,
            arc.points[lo].z + (arc.points[hi].z - arc.points[lo].z) * frac
        )

        // Derive lat/lng from the chip's interpolated position
        let r = sqrt(pt.x * pt.x + pt.y * pt.y + pt.z * pt.z)
        let chipLat = asin(pt.z / r)
        let chipLng = atan2(pt.y, pt.x)

        currentSpin = -.pi / 2 - chipLng
        currentTilt = -.pi / 2 + chipLat

        // SCNTransaction lets SceneKit interpolate rotation on the GPU
        // between render callback invocations for smooth 60fps movement
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 1.0 / 60.0
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .linear)
        spinNode.eulerAngles.z = currentSpin
        tiltNode.eulerAngles.x = currentTilt
        SCNTransaction.commit()
    }

    // MARK: - Data Loading

    private func loadBundleData(_ name: String) -> Data? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "bin") else {
            print("GlobeView: Missing resource \(name).bin")
            return nil
        }
        return try? Data(contentsOf: url)
    }
}
