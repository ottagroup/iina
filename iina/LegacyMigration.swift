//
//  LegacyMigration.swift
//  iina
//
//  Created by Matt Svoboda on 11/27/23.
//  Copyright © 2023 lhc. All rights reserved.
//

import Foundation

class LegacyMigration {

  // Map of [modern pref key → legacy key]. Do not reference legacy keys outside this file.
  fileprivate static let legacyColorPrefKeyMap: [Preference.Key: Preference.Key] = [
    Preference.Key.subTextColorString: Preference.Key("subTextColor"),
    Preference.Key.subBgColorString: Preference.Key("subBgColor"),
    Preference.Key.subBorderColorString: Preference.Key("subBorderColor"),
    Preference.Key.subShadowColorString: Preference.Key("subShadowColor"),
  ]

  /**
   Loops over the set of legacy preference keys. If a value is found for a given legacy key, but no value is found for its modern equivalent key,
   the legacy value is migrated & stored under the modern key.

   Older versions of IINA serialized mpv color data into NSObject binary using the now-deprecated `NSUnarchiver` class.
   This method will transition to the new format which consists of the color components written to a `String`.
   To do this in a way which does not corrupt the values for older versions of IINA, we'll store the new format under a new `Preference.Key`,
   and leave the legacy pref entry as-is.

   This method will be executed on each of the affected prefs when IINA starts up. It will first check if there is already an entry for the new
   pref key. If it finds one, then it will assume that the migration has already occurred, and will just return that.
   Otherwise it will look for an entry for the legacy pref key. If it finds that, if will convert its value into the new format and store it under
   the new pref key, and then return that.

   This will have the effect of automatically migrating older versions of IINA into the new format with no loss of data.
   However, it is worth noting that this migration will only happen once, and afterwards newer versions of IINA will not look at the old pref entry.
   And since older versions of IINA will only use the old pref entry, users who mix old and new versions of IINA may experience different values
   for these keys.
   */
  static func migrateLegacyPreferences() {
    for (modernKey, legacyKey) in legacyColorPrefKeyMap {
      // If modern pref entry already exists, then user has already upgraded and no action is needed for this key
      guard UserDefaults.standard.object(forKey: modernKey.rawValue) == nil else { continue }

      // Look for legacy pref:
      guard let data = UserDefaults.standard.data(forKey: legacyKey.rawValue) else { continue }
      guard let color = NSUnarchiver.unarchiveObject(with: data) as? NSColor else { continue }
      guard let mpvColorString = color.usingColorSpace(.deviceRGB)?.mpvColorString else { continue }
      // Store migrated value in modern string format under modern pref key:
      UserDefaults.standard.set(mpvColorString, forKey: modernKey.rawValue)
    }
  }

}
