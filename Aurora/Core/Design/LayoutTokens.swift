//
//  LayoutTokens.swift
//  Aurora
//
//  Centralized adaptive layout token system.
//  All spacing, padding, sizing, and typography values are defined here
//  so that views never use hardcoded magic numbers.
//

import SwiftUI

// MARK: - Layout Tokens

@MainActor
enum LayoutTokens {

  // MARK: - Platform Detection

  /// Whether we are running on macOS.
  static var isMacOS: Bool {
    #if os(macOS)
    return true
    #else
    return false
    #endif
  }

  // MARK: - Size Class Multiplier

  /// Returns a scaling multiplier for the current horizontal size class.
  /// Compact (iPhone): 1.0, Regular (iPad / large iPhone landscape): 1.25
  static func sizeClassMultiplier(
    for sizeClass: UserInterfaceSizeClass?
  ) -> CGFloat {
    sizeClass == .regular ? 1.25 : 1.0
  }

  // MARK: - Spacing

  /// Inter-element gap tokens.
  enum Spacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 24

    /// Scaled spacing for the given size class.
    static func scaled(_ base: CGFloat, for sizeClass: UserInterfaceSizeClass?) -> CGFloat {
      base * sizeClassMultiplier(for: sizeClass)
    }
  }

  // MARK: - Padding

  /// Screen-level and container-level padding tokens.
  enum Padding {
    /// Horizontal inset for full-width scroll content.
    /// macOS gets extra breathing room (32pt) vs iPad (24pt) vs iPhone (16pt).
    static func screenHorizontal(for sizeClass: UserInterfaceSizeClass?) -> CGFloat {
      #if os(macOS)
      return 32
      #else
      return sizeClass == .regular ? 24 : 16
      #endif
    }

    /// Inner padding for cards and glass containers.
    /// macOS: 24pt, iPad: 20pt, iPhone: 16pt.
    static func cardInner(for sizeClass: UserInterfaceSizeClass?) -> CGFloat {
      #if os(macOS)
      return 24
      #else
      return sizeClass == .regular ? 20 : 16
      #endif
    }

    /// Inner padding for hero / featured cards.
    /// macOS: 32pt, iPad: 28pt, iPhone: 24pt.
    static func cardHero(for sizeClass: UserInterfaceSizeClass?) -> CGFloat {
      #if os(macOS)
      return 32
      #else
      return sizeClass == .regular ? 28 : 24
      #endif
    }

    /// Vertical padding for individual row items.
    static var rowVertical: CGFloat {
      #if os(macOS)
      return 10
      #else
      return 14
      #endif
    }

    /// Bottom padding for scroll views to clear tab bar (iOS) or add breathing room (macOS).
    static var scrollBottom: CGFloat {
      #if os(macOS)
      return 24
      #else
      return 100
      #endif
    }

    /// Vertical padding for section headers.
    static let sectionTop: CGFloat = 20

    /// Padding for section header text from left edge.
    static let sectionHeaderLeading: CGFloat = 8

    /// Horizontal padding inside row subheaders (e.g. collapsible section titles).
    static let sectionTitleInset: CGFloat = 4
  }

  // MARK: - Icon Sizes

  /// Standardized icon frame sizes.
  enum IconSize {
    /// Small inline icons (clock, calendar badges) — 10–11pt font.
    static let xs: CGFloat = 11

    /// Decorative / secondary icons — 14pt font.
    static let sm: CGFloat = 14

    /// Standard row icon font size — 18pt.
    static let md: CGFloat = 18

    /// Larger standalone icons — 22pt.
    static let lg: CGFloat = 22

    /// Hero/feature icons — 24pt.
    static let xl: CGFloat = 24

    /// Fixed frame width for row icons to enforce text alignment.
    static let rowFrame: CGFloat = 28

    /// Circular icon background size (e.g. streak card, upcoming card).
    static let circleBackground: CGFloat = 48
  }

  // MARK: - Card Heights

  /// Fixed heights for specific card types.
  enum CardHeight {
    /// Smart list cards in the 2-column grid.
    static let smartList: CGFloat = 90

    /// Category cards in the grid.
    static let category: CGFloat = 110

    /// Celestial visualization (planet / moon).
    static var celestial: CGFloat {
      #if os(macOS)
      return 300
      #else
      return 190
      #endif
    }

    /// Calendar day cell.
    static let calendarDay: CGFloat = 44

    /// Calendar nav button.
    static let calendarNavButton: CGFloat = 36

    /// Completion toggle circle.
    static let taskCheckbox: CGFloat = 24

    /// Progress bar track height.
    static let progressBar: CGFloat = 8

    /// FAB (Floating Action Button) size.
    static let fab: CGFloat = 56

    /// Suggested list icon circle.
    static let suggestedIcon: CGFloat = 36
  }

  // MARK: - Corner Radius

  /// Corner radius tokens.
  enum Radius {
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 20
    static let xl: CGFloat = 24
  }

  // MARK: - Typography

  /// Standardized font sizes by semantic role.
  enum Typography {
    /// Tiny metadata (clock icons, task indicator dots) — 10pt
    static let micro: CGFloat = 10

    /// Secondary metadata (dates, times, badge text) — 12pt
    static let caption: CGFloat = 12

    /// Tertiary labels, hints, section headers — 13pt
    static let footnote: CGFloat = 13

    /// Supporting text (streak labels, card subtitles) — 14pt
    static let subheadline: CGFloat = 14

    /// Standard UI text (dates, secondary values) — 15pt
    static let callout: CGFloat = 15

    /// Primary body text (row titles, field text) — 16pt
    static let body: CGFloat = 16

    /// Prominent UI text (search field, picker labels) — 17pt
    static let headline: CGFloat = 17

    /// Card titles, navigation bar-adjacent — 18pt
    static let title3: CGFloat = 18

    /// Section headers ("Today's Agenda", "My Lists") — 22pt
    static let title2: CGFloat = 22

    /// Hero name, large card titles — 24pt
    static let title1: CGFloat = 24

    /// Stat numbers (large count displays) — 28pt
    static let largeNumber: CGFloat = 28

    /// Large greeting text — 28pt
    static let largeTitle: CGFloat = 28

    /// Avatar initial letter — 34pt
    static let avatar: CGFloat = 34

    /// Search empty-state icons, large decorative — 36pt
    static let emptyStateIcon: CGFloat = 36

    /// Insight card large stat number — 48pt
    static let heroStat: CGFloat = 48
  }

  // MARK: - List Row Insets

  /// Standard list row insets used across Journal and Task lists.
  static func listRowInsets(
    vertical: CGFloat = Spacing.xs,
    for sizeClass: UserInterfaceSizeClass?
  ) -> EdgeInsets {
    EdgeInsets(
      top: vertical,
      leading: Padding.screenHorizontal(for: sizeClass),
      bottom: vertical,
      trailing: Padding.screenHorizontal(for: sizeClass)
    )
  }

  /// Divider leading padding — aligns with text start past icon.
  static let dividerLeading: CGFloat = Padding.screenHorizontal(for: nil)
    + IconSize.rowFrame + Spacing.md
}
