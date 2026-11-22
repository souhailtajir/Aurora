//
//  PlanetNode.swift
//  Aurora
//
//  Created by souhail on 12/18/25.
//

import SceneKit

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

nonisolated final class PlanetNode: SCNNode {
    private let planet: Planet
    
    nonisolated init(planet: Planet, radius: CGFloat = 1.0) {
        self.planet = planet
        super.init()
        
        setupPlanet(radius: radius)
        
        // Add ring for Saturn
        if planet == .saturn {
            setupRing(planetRadius: radius)
        }
        
        setupLighting()
        startRotation()
    }
    
    @available(*, unavailable)
    nonisolated required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupPlanet(radius: CGFloat) {
        // Create sphere geometry
        let sphere = SCNSphere(radius: radius)
        sphere.segmentCount = 200 // High detail for smooth surface
        
        // Create and configure material
        let material = SCNMaterial()
        
        // Load texture image from Assets
        let textureName = getTextureName(for: planet)
        if let textureImage = PlatformImage(named: textureName) {
            material.diffuse.contents = textureImage
        } else {
            // Fallback to solid color if texture not found
            let color = planet.baseColor
            material.diffuse.contents = PlatformColor(
                red: color.red,
                green: color.green,
                blue: color.blue,
                alpha: 1.0
            )
        }
        
        // Physically-based rendering
        material.lightingModel = .physicallyBased
        
        // Enable better diffuse wrapping for softer lighting transitions
        material.diffuse.wrapS = .repeat
        material.diffuse.wrapT = .repeat
        
        // Planet-specific material properties
        switch planet {
        case .sun:
            // Sun: warm glow, more subtle emission for realism
            material.metalness.contents = 0.0
            material.roughness.contents = 0.4
            material.emission.contents = PlatformColor(red: 1.0, green: 0.9, blue: 0.7, alpha: 1.0)
            material.emission.intensity = 0.15
            
        case .mars:
            // Mars: rocky, moderate roughness for texture visibility
            material.metalness.contents = 0.0
            material.roughness.contents = 0.7
            material.specular.contents = PlatformColor(white: 0.2, alpha: 1.0)
            
        case .venus:
            // Venus: smooth atmosphere
            material.metalness.contents = 0.0
            material.roughness.contents = 0.3
            material.specular.contents = PlatformColor(white: 0.4, alpha: 1.0)
            
        case .jupiter, .saturn:
            // Gas giants: banded, moderate roughness
            material.metalness.contents = 0.0
            material.roughness.contents = 0.5
            material.specular.contents = PlatformColor(white: 0.3, alpha: 1.0)
            
        case .neptune, .uranus:
            // Ice giants: smooth, slightly glossy
            material.metalness.contents = 0.0
            material.roughness.contents = 0.4
            material.specular.contents = PlatformColor(white: 0.45, alpha: 1.0)
            
        case .moon:
            // Moon: moderate roughness to show craters
            material.metalness.contents = 0.0
            material.roughness.contents = 0.75
            material.specular.contents = PlatformColor(white: 0.15, alpha: 1.0)
            
        case .mercury:
            // Mercury: rocky but smoother than moon
            material.metalness.contents = 0.0
            material.roughness.contents = 0.65
            material.specular.contents = PlatformColor(white: 0.2, alpha: 1.0)
        }
        
        sphere.materials = [material]
        self.geometry = sphere
    }
    
    private func getTextureName(for planet: Planet) -> String {
        switch planet {
        case .sun: return "8k_sun"
        case .moon: return "8k_moon"
        case .mercury: return "8k_mercury"
        case .venus: return "8k_venus"
        case .mars: return "8k_mars"
        case .jupiter: return "8k_jupiter"
        case .saturn: return "8k_saturn"
        case .uranus: return "2k_uranus"
        case .neptune: return "2k_neptune"
        }
    }
    
    private func setupRing(planetRadius: CGFloat) {
        // Create ring using SCNPlane with Shader Modifier for radial mapping
        let ringOuterRadius = planetRadius * 2.5
        let ringGeometry = SCNPlane(width: ringOuterRadius * 2, height: ringOuterRadius * 2)
        
        // Shader to map texture radially and create ring hole
        let shaderModifier = """
        // Calculate distance from center (0.5, 0.5) in UV space
        vec2 center = vec2(0.5, 0.5);
        float dist = length(_surface.diffuseTexcoord - center) * 2.0;
        
        // Define ring boundaries (inner and outer radius)
        float innerRadius = 0.6;  // 1.5 / 2.5 = 0.6
        float outerRadius = 1.0;
        
        // Discard fragments outside the ring
        if (dist < innerRadius || dist > outerRadius) {
            discard_fragment();
        }
        
        // Map distance to texture coordinate (0 to 1 across ring width)
        float normalizedDist = (dist - innerRadius) / (outerRadius - innerRadius);
        
        // Use normalized distance as U coordinate for radial gradient
        _surface.diffuseTexcoord = vec2(normalizedDist, 0.5);
        """
        
        let ringMaterial = SCNMaterial()
        
        // Load ring texture
        if let ringTexture = PlatformImage(named: "8k_saturn_ring") {
            ringMaterial.diffuse.contents = ringTexture
            ringMaterial.diffuse.wrapS = .clamp
            ringMaterial.diffuse.wrapT = .clamp
        } else {
            ringMaterial.diffuse.contents = PlatformColor(red: 0.9, green: 0.8, blue: 0.6, alpha: 0.7)
        }
        
        // Configure material
        ringMaterial.shaderModifiers = [.fragment: shaderModifier]
        ringMaterial.lightingModel = .constant
        ringMaterial.isDoubleSided = true
        ringMaterial.writesToDepthBuffer = false
        ringMaterial.transparency = 0.75
        
        ringGeometry.materials = [ringMaterial]
        
        let ringNode = SCNNode(geometry: ringGeometry)
        
        // Rotate and tilt the ring
        ringNode.eulerAngles = SCNVector3(x: SCNFloat(Float.pi / 2 + 0.47), y: 0, z: 0)
        
        self.addChildNode(ringNode)
    }
    
    private func setupLighting() {
        // Planets are self-lit in this design, lighting handled by scene
    }
    
    private func startRotation() {
        // Don't rotate Saturn - it has rings that need to stay oriented
        if planet == .saturn {
            return
        }
        
        // Create continuous rotation animation for other planets
        let rotation = SCNAction.rotateBy(
            x: 0,
            y: CGFloat.pi * 2,
            z: 0,
            duration: 360.0 / planet.rotationSpeed
        )
        let repeatRotation = SCNAction.repeatForever(rotation)
        self.runAction(repeatRotation)
    }
}
