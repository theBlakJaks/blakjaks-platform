import SwiftUI
import SceneKit

// MARK: - ChipParticleView (SceneKit)
// Faithful SceneKit port of chip_canvas.html (Three.js).
//
// Geometry exactly matches the original:
//   • SCNCylinder(r=1, h=0.15, 64 segs) — dark PBR body
//   • SCNTorus(ring=0.97, pipe=0.04)  ×2 — gold outer rings at y=±0.075
//   • SCNTorus(ring=0.50, pipe=0.025) ×2 — gold inner rings at y=±0.078
//   • SCNBox(0.08 × 0.16 × 0.12)     ×16 — gold edge inlays around rim
//
// Lighting matches the original:
//   • Ambient white 0.4
//   • Key directional gold #ffd700 ×1.2 from (5,10,7)
//   • Fill directional blue  #4488ff ×0.3 from (-5,5,-5)
//   • Rim omni gold #ffd700 ×0.6 at (0,-10,10)
//
// Physics matches the original (velocity, gravity, wobble, spring collisions).
// All geometry is instanced — 48 chip nodes share the same geometry buffers.

struct ChipParticleView: UIViewRepresentable {

    /// When true, chips float upward instead of falling — used for the
    /// "declaration" beat in the About page where value rises back to the user.
    var risingMode: Bool = false

    func makeCoordinator() -> Coordinator { Coordinator(risingMode: risingMode) }

    func makeUIView(context: Context) -> SCNView {
        let v = SCNView()
        v.scene            = context.coordinator.scene
        v.backgroundColor  = .clear
        v.isPlaying        = true
        v.delegate         = context.coordinator
        v.antialiasingMode = .multisampling4X
        v.isUserInteractionEnabled = false
        v.showsStatistics  = false
        return v
    }

    func updateUIView(_ uiView: SCNView, context: Context) {
        context.coordinator.risingMode = risingMode
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject, SCNSceneRendererDelegate {

        let scene = SCNScene()
        var risingMode: Bool
        private var chips: [ChipState] = []
        private var lastTime: TimeInterval = -1
        private var elapsed: Double = 0

        private let TOP_Y:    Float = 18
        private let BOTTOM_Y: Float = -18

        // Per-chip mutable physics state (kept in Swift, applied to node each frame)
        struct ChipState {
            var node:      SCNNode
            var vel:       SIMD3<Float>   // world velocity (pts/s)
            var rotVel:    SIMD3<Float>   // current rotation velocity (rad/s) x,y,z
            var rotBase:   SIMD3<Float>   // target rotation velocity (drifts toward this)
            var wobbleSpd: Float
            var wobbleAmt: Float
            var wobbleOff: Float
            var radius:    Float          // collision radius = scale * 1.6
        }

        // MARK: Init

        init(risingMode: Bool) {
            self.risingMode = risingMode
            super.init()
            buildScene()
        }

        // MARK: Scene construction

        private func buildScene() {
            scene.background.contents = UIColor.clear

            // ── Perspective camera — exactly matches Three.js PerspectiveCamera(60, …) ──
            let camNode = SCNNode()
            let cam     = SCNCamera()
            cam.fieldOfView = 60
            cam.zNear = 0.1
            cam.zFar  = 1000
            camNode.camera   = cam
            camNode.position = SCNVector3(0, 0, 14)
            scene.rootNode.addChildNode(camNode)

            // ── Ambient white 0.4 ────────────────────────────────────────────
            let ambNode = SCNNode()
            let amb     = SCNLight()
            amb.type    = .ambient
            amb.color   = UIColor(white: 1, alpha: 0.4)
            ambNode.light = amb
            scene.rootNode.addChildNode(ambNode)

            // ── Key directional — warm white (not yellow) so the material's own
            //    gold colour reads true without a yellow-on-yellow double-cast ──
            let keyNode = SCNNode()
            let key     = SCNLight()
            key.type      = .directional
            key.color     = UIColor(red: 1.0, green: 0.96, blue: 0.88, alpha: 1)
            key.intensity = 1400
            keyNode.light    = key
            keyNode.position = SCNVector3(5, 10, 7)
            keyNode.look(at: SCNVector3(0,0,0), up: SCNVector3(0,1,0),
                         localFront: SCNVector3(0,0,-1))
            scene.rootNode.addChildNode(keyNode)

            // ── Fill directional — blue #4488ff intensity 0.3, from (-5,5,-5) ──
            let fillNode = SCNNode()
            let fill     = SCNLight()
            fill.type      = .directional
            fill.color     = UIColor(red: 0.267, green: 0.533, blue: 1.0, alpha: 1)
            fill.intensity = 300
            fillNode.light    = fill
            fillNode.position = SCNVector3(-5, 5, -5)
            fillNode.look(at: SCNVector3(0,0,0), up: SCNVector3(0,1,0),
                          localFront: SCNVector3(0,0,-1))
            scene.rootNode.addChildNode(fillNode)

            // ── Rim omni — gold #ffd700 intensity 0.6, at (0,-10,10) ────────
            let rimNode = SCNNode()
            let rim     = SCNLight()
            rim.type       = .omni
            rim.color      = UIColor(red: 1.0, green: 0.92, blue: 0.75, alpha: 1)
            rim.intensity  = 600
            rim.attenuationStartDistance = 0
            rim.attenuationEndDistance   = 50
            rimNode.light    = rim
            rimNode.position = SCNVector3(0, -10, 10)
            scene.rootNode.addChildNode(rimNode)

            // ── Build shared geometry template (clone shares geometry, not nodes) ──
            let template = makeChipTemplate()

            for _ in 0..<48 {
                let node = template.clone()   // independent node tree, shared geometry

                let s = Float.random(in: 0.25...0.50)
                node.scale = SCNVector3(s, s, s)
                node.eulerAngles = SCNVector3(
                    Float.random(in: 0 ... .pi * 2),
                    Float.random(in: 0 ... .pi * 2),
                    Float.random(in: 0 ... .pi * 2)
                )
                node.position = SCNVector3(
                    Float.random(in: -5...5),
                    Float.random(in: -TOP_Y...TOP_Y),
                    Float.random(in: -2...2)
                )

                // Rotation velocity — bias toward spin (large |ry|)
                let ryBase = Float.random(in: -2.5...2.5) + (Bool.random() ? 3 : -3)
                let rzBase = Float.random(in: -2...2)
                let rxBase = Float.random(in: -2...2)

                let state = ChipState(
                    node:      node,
                    vel:       SIMD3(
                        Float.random(in: -0.15...0.15),
                        -(1.5 + Float.random(in: 0...2)),
                        Float.random(in: -0.15...0.15)
                    ),
                    rotVel:    SIMD3(rxBase, ryBase, rzBase),
                    rotBase:   SIMD3(rxBase, ryBase, rzBase),
                    wobbleSpd: 0.8 + Float.random(in: 0...1.2),
                    wobbleAmt: 0.3 + Float.random(in: 0...0.5),
                    wobbleOff: Float.random(in: 0 ... .pi * 2),
                    radius:    s * 1.6
                )
                scene.rootNode.addChildNode(node)
                chips.append(state)
            }
        }

        // MARK: Chip geometry template
        // Exactly matches makeChipGeo() from chip_canvas.html.
        // All chips clone this node, sharing the geometry buffers.

        private func makeChipTemplate() -> SCNNode {
            let g = SCNNode()

            // ── PBR gold material ─────────────────────────────────────────
            // #C8991A (200,153,26) = the logo's amber gold — richer, darker, more
            // red/orange than the #D4AF37 brand gold. This is the exact colour used
            // in the logo gradient (app-mockup.html lines 729/737).
            // metalness 0.92 + roughness 0.18 = deep metallic sheen without looking plastic.
            let gold = SCNMaterial()
            gold.lightingModel    = .physicallyBased
            gold.diffuse.contents = UIColor(red: 204/255, green: 143/255, blue: 23/255, alpha: 1)
            gold.metalness.contents = NSNumber(value: 0.92)
            gold.roughness.contents = NSNumber(value: 0.18)
            // Emissive: very dark amber so chips glow faintly even in shadow areas
            gold.emission.contents  = UIColor(red: 0.05, green: 0.028, blue: 0.002, alpha: 1)

            // ── Dark body material ────────────────────────────────────────
            let dark = SCNMaterial()
            dark.lightingModel    = .physicallyBased
            dark.diffuse.contents = UIColor(white: 0.10, alpha: 1)
            dark.metalness.contents = NSNumber(value: 0.3)
            dark.roughness.contents = NSNumber(value: 0.7)

            // ── CylinderGeometry(1, 1, 0.15, 64) — dark body ─────────────
            let cyl = SCNCylinder(radius: 1.0, height: 0.15)
            cyl.radialSegmentCount = 64
            cyl.materials = [dark, dark, dark]
            g.addChildNode(SCNNode(geometry: cyl))

            // ── TorusGeometry(0.97, 0.04, 16, 64) ×2 at y=±0.075 ────────
            // SCNTorus lies in XZ plane by default — chip face is XZ → correct, no rotation needed
            let outerTorus = SCNTorus()
            outerTorus.ringRadius       = 0.97
            outerTorus.pipeRadius       = 0.04
            outerTorus.ringSegmentCount = 64
            outerTorus.pipeSegmentCount = 16
            outerTorus.materials = [gold]

            for yOff: Float in [0.075, -0.075] {
                let n = SCNNode(geometry: outerTorus)
                n.position = SCNVector3(0, yOff, 0)
                g.addChildNode(n)
            }

            // ── TorusGeometry(0.5, 0.025, 16, 64) ×2 at y=±0.078 ─────────
            let innerTorus = SCNTorus()
            innerTorus.ringRadius       = 0.5
            innerTorus.pipeRadius       = 0.025
            innerTorus.ringSegmentCount = 64
            innerTorus.pipeSegmentCount = 16
            innerTorus.materials = [gold]

            for yOff: Float in [0.078, -0.078] {
                let n = SCNNode(geometry: innerTorus)
                n.position = SCNVector3(0, yOff, 0)
                g.addChildNode(n)
            }

            // ── 16 BoxGeometry(0.08, 0.16, 0.12) edge inlays at r=0.95 ──
            let box = SCNBox(width: 0.08, height: 0.16, length: 0.12, chamferRadius: 0.005)
            box.materials = [gold]

            for i in 0..<16 {
                let a = Float(i) / 16 * .pi * 2
                let n = SCNNode(geometry: box)
                n.position     = SCNVector3(cos(a) * 0.95, 0, sin(a) * 0.95)
                n.eulerAngles  = SCNVector3(0, -a + .pi / 2, 0)
                g.addChildNode(n)
            }

            return g
        }

        // MARK: Reset a chip to the top

        private func resetChip(_ i: Int) {
            chips[i].vel = SIMD3(
                Float.random(in: -0.15...0.15),
                -(1.5 + Float.random(in: 0...2)),
                Float.random(in: -0.15...0.15)
            )
            chips[i].node.position = SCNVector3(
                Float.random(in: -5...5),
                TOP_Y + Float.random(in: 0...8),
                Float.random(in: -2...2)
            )
        }

        // MARK: Reset a chip to the bottom (rising mode)

        private func resetChipRising(_ i: Int) {
            chips[i].vel = SIMD3(
                Float.random(in: -0.10...0.10),
                0.8 + Float.random(in: 0...1.2),
                Float.random(in: -0.10...0.10)
            )
            chips[i].node.position = SCNVector3(
                Float.random(in: -5...5),
                BOTTOM_Y - Float.random(in: 0...8),
                Float.random(in: -2...2)
            )
        }

        // MARK: Per-frame physics update

        func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
            // Compute dt; cap to 50ms to avoid huge jumps after backgrounding
            let dt: Float
            if lastTime < 0 {
                dt = 1.0 / 60.0
            } else {
                dt = min(Float(time - lastTime), 0.05)
            }
            lastTime  = time
            elapsed  += Double(dt)
            let t     = Float(elapsed)

            // Per-frame damping factor — normalised to 60 fps like the original
            let drag = pow(Float(0.94), dt * 60)

            // ── Update positions and rotations ────────────────────────────
            for i in chips.indices {
                var c = chips[i]
                let node = c.node

                // Position
                var p = SIMD3<Float>(node.position.x, node.position.y, node.position.z)
                p += c.vel * dt
                node.position = SCNVector3(p.x, p.y, p.z)

                // Rotation (wobble modulates x and z axes)
                let wobble = sin(t * c.wobbleSpd + c.wobbleOff) * c.wobbleAmt
                var e = SIMD3<Float>(node.eulerAngles.x, node.eulerAngles.y, node.eulerAngles.z)
                e.x += (c.rotVel.x + wobble)       * dt
                e.y +=  c.rotVel.y                  * dt
                e.z += (c.rotVel.z + wobble * 0.5)  * dt
                node.eulerAngles = SCNVector3(e.x, e.y, e.z)

                // Horizontal drag
                c.vel.x *= drag
                c.vel.z *= drag

                // Rotation velocity drifts back toward base values
                let springK: Float = 0.015
                c.rotVel += (c.rotBase - c.rotVel) * springK

                if risingMode {
                    // Rising mode: chips float upward, no gravity
                    if c.vel.y < 0.8 { c.vel.y += 1.0 * dt }
                    if c.vel.y > 2.0 { c.vel.y = 2.0 }
                    // Reset if risen above top
                    if p.y > TOP_Y { resetChipRising(i) }
                    else           { chips[i] = c }
                } else {
                    // Gravity accelerates vy toward –4
                    if c.vel.y > -1.5 { c.vel.y -= 1.2 * dt }
                    if c.vel.y < -4   { c.vel.y  = -4 }
                    // Reset if fallen below bottom
                    if p.y < BOTTOM_Y { resetChip(i) }
                    else              { chips[i] = c }
                }
            }

            // ── Spring collision resolution ───────────────────────────────
            for i in chips.indices {
                let pa = SIMD3<Float>(chips[i].node.position.x,
                                     chips[i].node.position.y,
                                     chips[i].node.position.z)
                for j in (i + 1)..<chips.count {
                    let pb  = SIMD3<Float>(chips[j].node.position.x,
                                          chips[j].node.position.y,
                                          chips[j].node.position.z)
                    let d    = pb - pa
                    let dist = sqrt(d.x*d.x + d.y*d.y + d.z*d.z)
                    let minD = chips[i].radius + chips[j].radius
                    guard dist < minD, dist > 0.001 else { continue }

                    let nx  = d.x / dist
                    let nz  = d.z / dist
                    let ov  = minD - dist
                    let sp  = ov * 0.18
                    chips[i].vel.x -= sp * nx;  chips[i].vel.z -= sp * nz
                    chips[j].vel.x += sp * nx;  chips[j].vel.z += sp * nz
                    let kick = ov * 2.5
                    chips[i].rotVel.y += kick * nz;  chips[i].rotVel.z -= kick * nx
                    chips[j].rotVel.y -= kick * nz;  chips[j].rotVel.z += kick * nx
                }
            }
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        ChipParticleView()
            .ignoresSafeArea()
            .allowsHitTesting(false)
    }
}
