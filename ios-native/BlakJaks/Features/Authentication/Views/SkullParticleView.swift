import SwiftUI
import SceneKit

// MARK: - FallingSkullsView (USDZ)
// 20 large realistic skulls falling straight down with slow spin.
// No collisions. Clear background for ZStack overlay on Beat 1.

struct FallingSkullsView: UIViewRepresentable {

    func makeCoordinator() -> Coordinator { Coordinator() }

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

    func updateUIView(_ uiView: SCNView, context: Context) {}

    // MARK: - Coordinator

    final class Coordinator: NSObject, SCNSceneRendererDelegate {

        let scene = SCNScene()
        private var skulls: [SkullState] = []
        private var lastTime: TimeInterval = -1

        private let SKULL_COUNT = 10
        private let SKULL_SCALE: Float = 0.12

        private let TOP_Y:    Float =  18
        private let BOTTOM_Y: Float = -18
        private let X_RANGE:  ClosedRange<Float> = -4...4
        private let Z_RANGE:  ClosedRange<Float> = -2...2

        struct SkullState {
            var node:    SCNNode
            var fallSpd: Float
            var rotVel:  SIMD3<Float>
        }

        override init() {
            super.init()
            buildScene()
        }

        private func buildScene() {
            scene.background.contents = UIColor.clear

            let camNode = SCNNode()
            let cam     = SCNCamera()
            cam.fieldOfView = 60
            cam.zNear = 0.1
            cam.zFar  = 1000
            camNode.camera   = cam
            camNode.position = SCNVector3(0, 0, 14)
            scene.rootNode.addChildNode(camNode)

            addLighting()

            guard let template = loadSkullTemplate() else { return }

            for _ in 0..<SKULL_COUNT {
                let skull = template.clone()
                skull.scale = SCNVector3(SKULL_SCALE, SKULL_SCALE, SKULL_SCALE)

                skull.eulerAngles = SCNVector3(
                    Float.random(in: 0 ... .pi * 2),
                    Float.random(in: 0 ... .pi * 2),
                    Float.random(in: 0 ... .pi * 2)
                )

                skull.position = SCNVector3(
                    Float.random(in: X_RANGE),
                    Float.random(in: BOTTOM_Y...TOP_Y),
                    Float.random(in: Z_RANGE)
                )

                let state = SkullState(
                    node:    skull,
                    fallSpd: 3.0 + Float.random(in: 0...2.0),
                    rotVel:  SIMD3(
                        Float.random(in: -0.3...0.3),
                        Float.random(in: -0.5...0.5),
                        Float.random(in: -0.2...0.2)
                    )
                )

                scene.rootNode.addChildNode(skull)
                skulls.append(state)
            }
        }

        // MARK: - Per-frame update

        func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
            let dt: Float
            if lastTime < 0 {
                dt = 1.0 / 60.0
            } else {
                dt = min(Float(time - lastTime), 0.05)
            }
            lastTime = time

            for i in skulls.indices {
                let node = skulls[i].node

                // Fall
                var p = node.position
                p.y -= skulls[i].fallSpd * dt
                node.position = p

                // Spin
                var e = node.eulerAngles
                e.x += skulls[i].rotVel.x * dt
                e.y += skulls[i].rotVel.y * dt
                e.z += skulls[i].rotVel.z * dt
                node.eulerAngles = e

                // Reset at bottom
                if p.y < BOTTOM_Y {
                    node.position = SCNVector3(
                        Float.random(in: X_RANGE),
                        TOP_Y + Float.random(in: 2...8),
                        Float.random(in: Z_RANGE)
                    )
                    skulls[i].fallSpd = 3.0 + Float.random(in: 0...2.0)
                }
            }
        }

        // MARK: - Load USDZ

        private func loadSkullTemplate() -> SCNNode? {
            if let s = SCNScene(named: "art.scnassets/skull.usdz") {
                let c = SCNNode()
                for child in s.rootNode.childNodes { c.addChildNode(child.clone()) }
                return c
            }
            if let url = Bundle.main.url(forResource: "skull", withExtension: "usdz"),
               let s = try? SCNScene(url: url, options: nil) {
                let c = SCNNode()
                for child in s.rootNode.childNodes { c.addChildNode(child.clone()) }
                return c
            }
            return nil
        }

        // MARK: - Lighting

        private func addLighting() {
            let ambNode = SCNNode()
            let amb     = SCNLight()
            amb.type    = .ambient
            amb.color   = UIColor(white: 0.25, alpha: 1.0)
            ambNode.light = amb
            scene.rootNode.addChildNode(ambNode)

            let keyNode = SCNNode()
            let key     = SCNLight()
            key.type      = .directional
            key.color     = UIColor(red: 1.0, green: 0.95, blue: 0.88, alpha: 1)
            key.intensity = 2000
            key.castsShadow = true
            keyNode.light    = key
            keyNode.position = SCNVector3(4, 8, 7)
            keyNode.look(at: SCNVector3(0,0,0), up: SCNVector3(0,1,0),
                         localFront: SCNVector3(0,0,-1))
            scene.rootNode.addChildNode(keyNode)

            let fillNode = SCNNode()
            let fill     = SCNLight()
            fill.type      = .directional
            fill.color     = UIColor(red: 0.75, green: 0.82, blue: 1.0, alpha: 1)
            fill.intensity = 800
            fillNode.light    = fill
            fillNode.position = SCNVector3(-5, -3, 5)
            fillNode.look(at: SCNVector3(0,0,0), up: SCNVector3(0,1,0),
                          localFront: SCNVector3(0,0,-1))
            scene.rootNode.addChildNode(fillNode)

            let rimNode = SCNNode()
            let rim     = SCNLight()
            rim.type      = .directional
            rim.color     = UIColor(white: 0.9, alpha: 1.0)
            rim.intensity = 500
            rimNode.light    = rim
            rimNode.position = SCNVector3(0, 3, -8)
            rimNode.look(at: SCNVector3(0,0,0), up: SCNVector3(0,1,0),
                          localFront: SCNVector3(0,0,-1))
            scene.rootNode.addChildNode(rimNode)
        }
    }
}

typealias SkullParticleView = FallingSkullsView

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        FallingSkullsView()
            .ignoresSafeArea()
            .allowsHitTesting(false)
    }
}
