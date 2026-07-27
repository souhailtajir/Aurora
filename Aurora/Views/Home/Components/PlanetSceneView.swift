//
//  PlanetSceneView.swift
//  Aurora
//
//  Created by souhail on 12/18/25.
//

import SceneKit
import SwiftUI

struct PlanetSceneView: View {
  let planet: Planet
  @State private var rotationX: Float = 0
  @State private var rotationY: Float = 0
  @State private var lastDragValue: CGSize = .zero
  @State private var isVisible = false

  var body: some View {
    SceneKitView(
      planet: planet,
      rotationX: $rotationX,
      rotationY: $rotationY,
      isVisible: isVisible
    )
    .frame(width: 320, height: 320)
    .gesture(
      DragGesture()
        .onChanged { value in
          // Calculate delta from last position
          let deltaX = value.translation.height - lastDragValue.height
          let deltaY = value.translation.width - lastDragValue.width

          // Apply rotation (sensitivity factor)
          let sensitivity: Float = 0.01
          rotationX += Float(deltaX) * sensitivity
          rotationY += Float(deltaY) * sensitivity

          lastDragValue = value.translation
        }
        .onEnded { _ in
          lastDragValue = .zero
        }
    )
    .onAppear {
      isVisible = true
    }
    .onDisappear {
      isVisible = false
    }
  }
}

private struct SceneKitView: UIViewRepresentable {
  let planet: Planet
  @Binding var rotationX: Float
  @Binding var rotationY: Float
  let isVisible: Bool

  // Static scene cache to avoid recreating scenes
  private static var sceneCache: [Planet: SCNScene] = [:]
  private static let cacheLock = NSLock()

  func makeUIView(context: Context) -> SCNView {
    let scnView = SCNView()

    // Configure view settings - optimized for performance
    scnView.autoenablesDefaultLighting = false
    scnView.allowsCameraControl = false
    scnView.backgroundColor = .clear

    // Performance optimizations
    scnView.antialiasingMode = .multisampling2X  // Reduced from 4X
    scnView.rendersContinuously = false  // Only render when needed
    scnView.preferredFramesPerSecond = 30  // Cap at 30fps for battery

    // Get or create cached scene
    scnView.scene = getOrCreateScene()

    return scnView
  }

  func updateUIView(_ scnView: SCNView, context: Context) {
    // Update planet rotation based on gesture
    if let planetNode = scnView.scene?.rootNode.childNode(withName: "planet", recursively: false) {
      planetNode.eulerAngles = SCNVector3(rotationX, rotationY, 0)
    }

    // Pause/resume rendering based on visibility
    scnView.scene?.isPaused = !isVisible

    // Request a render update when rotation changes
    if isVisible {
      scnView.setNeedsDisplay()
    }
  }

  private func getOrCreateScene() -> SCNScene {
    Self.cacheLock.lock()
    defer { Self.cacheLock.unlock() }

    if let cached = Self.sceneCache[planet] {
      return cached
    }

    let scene = createScene()
    Self.sceneCache[planet] = scene
    return scene
  }

  private func createScene() -> SCNScene {
    let scene = SCNScene()

    // Create planet node with name for gesture control
    // Scale down Saturn specifically since rings make it much larger
    let radius: CGFloat = planet == .saturn ? 0.7 : 1.2
    let planetNode = PlanetNode(planet: planet, radius: radius)
    planetNode.name = "planet"
    scene.rootNode.addChildNode(planetNode)

    // Add camera
    let cameraNode = SCNNode()
    cameraNode.camera = SCNCamera()
    cameraNode.position = SCNVector3(x: 0, y: 0, z: 5)
    cameraNode.camera?.fieldOfView = 40
    cameraNode.camera?.wantsHDR = false
    scene.rootNode.addChildNode(cameraNode)

    // Ambient light - provides base illumination everywhere
    let ambientLight = SCNNode()
    ambientLight.light = SCNLight()
    ambientLight.light?.type = .ambient
    ambientLight.light?.intensity = 400
    ambientLight.light?.color = UIColor(white: 0.6, alpha: 1.0)
    scene.rootNode.addChildNode(ambientLight)

    // Main directional light - simulates sun
    let sunLight = SCNNode()
    sunLight.light = SCNLight()
    sunLight.light?.type = .directional
    sunLight.light?.intensity = 800
    sunLight.light?.color = UIColor(white: 1.0, alpha: 1.0)
    sunLight.light?.castsShadow = false
    // Position light at 45 degrees from upper right
    sunLight.eulerAngles = SCNVector3(x: -Float.pi / 4, y: Float.pi / 4, z: 0)
    scene.rootNode.addChildNode(sunLight)

    return scene
  }
}

#Preview {
  ZStack {
    Color.black.ignoresSafeArea()
    PlanetSceneView(planet: .jupiter)
  }
}

