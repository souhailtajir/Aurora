//
//  ZodiacSign.swift
//  Aurora
//
//  Created by souhail on 12/18/25.
//

import Foundation

enum ZodiacSign: String, CaseIterable, Codable {
    case aries = "Aries"
    case taurus = "Taurus"
    case gemini = "Gemini"
    case cancer = "Cancer"
    case leo = "Leo"
    case virgo = "Virgo"
    case libra = "Libra"
    case scorpio = "Scorpio"
    case sagittarius = "Sagittarius"
    case capricorn = "Capricorn"
    case aquarius = "Aquarius"
    case pisces = "Pisces"
    
    /// The ruling planet for each zodiac sign
    var rulingPlanet: Planet {
        switch self {
        case .aries: return .mars
        case .taurus: return .venus
        case .gemini: return .mercury
        case .cancer: return .moon
        case .leo: return .sun
        case .virgo: return .mercury
        case .libra: return .venus
        case .scorpio: return .mars
        case .sagittarius: return .jupiter
        case .capricorn: return .saturn
        case .aquarius: return .uranus
        case .pisces: return .neptune
        }
    }
    
    /// Calculate zodiac sign from birth date
    nonisolated static func from(birthDate: Date) -> ZodiacSign {
        let calendar = Calendar.current
        let month = calendar.component(.month, from: birthDate)
        let day = calendar.component(.day, from: birthDate)
        
        switch (month, day) {
        case (3, 21...31), (4, 1...19):
            return .aries
        case (4, 20...30), (5, 1...20):
            return .taurus
        case (5, 21...31), (6, 1...20):
            return .gemini
        case (6, 21...30), (7, 1...22):
            return .cancer
        case (7, 23...31), (8, 1...22):
            return .leo
        case (8, 23...31), (9, 1...22):
            return .virgo
        case (9, 23...30), (10, 1...22):
            return .libra
        case (10, 23...31), (11, 1...21):
            return .scorpio
        case (11, 22...30), (12, 1...21):
            return .sagittarius
        case (12, 22...31), (1, 1...19):
            return .capricorn
        case (1, 20...31), (2, 1...18):
            return .aquarius
        case (2, 19...29), (3, 1...20):
            return .pisces
        default:
            return .aries // Default fallback
        }
    }
    
    /// Symbol for the zodiac sign
    var symbol: String {
        switch self {
        case .aries: return "♈"
        case .taurus: return "♉"
        case .gemini: return "♊"
        case .cancer: return "♋"
        case .leo: return "♌"
        case .virgo: return "♍"
        case .libra: return "♎"
        case .scorpio: return "♏"
        case .sagittarius: return "♐"
        case .capricorn: return "♑"
        case .aquarius: return "♒"
        case .pisces: return "♓"
        }
    }
}

nonisolated enum Planet: String, CaseIterable, Codable {
    case sun = "Sun"
    case moon = "Moon"
    case mercury = "Mercury"
    case venus = "Venus"
    case mars = "Mars"
    case jupiter = "Jupiter"
    case saturn = "Saturn"
    case uranus = "Uranus"
    case neptune = "Neptune"
    
    /// Display name
    var displayName: String {
        rawValue
    }
    
    /// Subtitle description
    var subtitle: String {
        switch self {
        case .sun: return "The Center Star"
        case .moon: return "Earth's Satellite"
        case .mercury: return "The Swift Planet"
        case .venus: return "The Morning Star"
        case .mars: return "The Red Planet"
        case .jupiter: return "The Gas Giant"
        case .saturn: return "The Ringed World"
        case .uranus: return "The Ice Giant"
        case .neptune: return "The Blue Giant"
        }
    }
    
    /// Base color for the planet material
    var baseColor: (red: Double, green: Double, blue: Double) {
        switch self {
        case .sun:
            return (1.0, 0.95, 0.6) // Bright yellow
        case .moon:
            return (0.8, 0.8, 0.75) // Light gray
        case .mercury:
            return (0.65, 0.65, 0.65) // Dark gray
        case .venus:
            return (0.95, 0.9, 0.7) // Pale yellow-beige
        case .mars:
            return (0.8, 0.4, 0.3) // Reddish-orange
        case .jupiter:
            return (0.85, 0.75, 0.6) // Tan with bands
        case .saturn:
            return (0.9, 0.85, 0.7) // Pale yellow
        case .uranus:
            return (0.6, 0.8, 0.85) // Light cyan
        case .neptune:
            return (0.4, 0.5, 0.9) // Deep blue
        }
    }
    
    /// Rotation speed (degrees per second)
    var rotationSpeed: Double {
        switch self {
        case .sun: return 10.0
        case .moon: return 8.0
        case .mercury: return 15.0
        case .venus: return 6.0
        case .mars: return 12.0
        case .jupiter: return 20.0
        case .saturn: return 18.0
        case .uranus: return 14.0
        case .neptune: return 16.0
        }
    }
}
