//
//  V2LegacyMigration.swift
//  MultiDirectionCollectionView
//
//  One-time, idempotent recovery step for users upgrading from the 1.3.6-era file format.
//
//  Old format (1.3.6): each sheet was saved as a loose JSON file directly under Documents/sub/
//  with no file extension - the filename WAS the sheet's title (e.g. Documents/sub/MyBudget).
//
//  Current format: the sheet list/order/ids come from Documents/importedExcel/initialXLSX.xlsx,
//  and per-sheet content is cached at Documents/sub/sheet<id>.xml (id-based, ".xml" forced).
//  Anyone who upgraded straight from 1.3.6 never created initialXLSX.xlsx, so those old bare-title
//  files are still sitting in Documents/sub/ but nothing points at them anymore - they're
//  invisible even though the data is intact on disk.
//
//  This migration does NOT try to reconstruct those sheets into the live/editable workbook (that
//  would require hand-building CoreXLSX-compatible worksheet XML, which is riskier than it's
//  worth). Instead it simply moves the legacy files out of Documents/sub/ - so they stop being
//  mixed in with the current id-based sheet cache - into a clearly separate, clearly labeled
//  Documents/RecoveredFiles/ folder where V2RecoveredFilesViewController can list and export them.
//
import Foundation

enum V2LegacyMigration {

    private static let legacyFileExtension = "xml"

    /// Detects 1.3.6-era legacy sheets (bare-title files with no ".xml" extension) sitting in
    /// Documents/sub/ and moves each one into Documents/RecoveredFiles/, preserving its original
    /// filename (which is the sheet's original title).
    ///
    /// Safe to call on every app launch:
    /// - Once a file has been moved it's no longer in Documents/sub/, so later launches simply
    ///   won't find it there again (no re-processing, no duplicate work).
    /// - A same-named file already present in the destination is never overwritten - it's left in
    ///   place in Documents/sub/ instead, untouched, so no data can be silently clobbered.
    /// - Original legacy files are only ever moved, never deleted or modified in place.
    static func migrateLegacySheetsIfNeeded() {
        let fm = FileManager.default
        guard let documentsURL = fm.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }

        let subDir = documentsURL.appendingPathComponent("sub")
        guard fm.fileExists(atPath: subDir.path) else {
            return
        }

        guard let entries = try? fm.contentsOfDirectory(
            at: subDir,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ) else {
            return
        }

        // Legacy sheets are files with no ".xml" extension - the current format always uses
        // "sheet<id>.xml" / "csv_sheet1.xml" style names.
        let legacyFiles = entries.filter { $0.pathExtension.lowercased() != legacyFileExtension }
        guard !legacyFiles.isEmpty else {
            return
        }

        let recoveredDir = documentsURL.appendingPathComponent("RecoveredFiles")
        if !fm.fileExists(atPath: recoveredDir.path) {
            do {
                try fm.createDirectory(at: recoveredDir, withIntermediateDirectories: true)
            } catch {
                print("V2LegacyMigration: failed to create RecoveredFiles directory: \(error.localizedDescription)")
                return
            }
        }

        var movedCount = 0
        for fileURL in legacyFiles {
            let destinationURL = recoveredDir.appendingPathComponent(fileURL.lastPathComponent)
            if fm.fileExists(atPath: destinationURL.path) {
                // Already recovered previously, or a name collision - never overwrite existing data.
                print("V2LegacyMigration: skipping '\(fileURL.lastPathComponent)', already present in RecoveredFiles")
                continue
            }
            do {
                try fm.moveItem(at: fileURL, to: destinationURL)
                movedCount += 1
                print("V2LegacyMigration: moved legacy sheet '\(fileURL.lastPathComponent)' into Documents/RecoveredFiles/")
            } catch {
                print("V2LegacyMigration: failed to move '\(fileURL.lastPathComponent)': \(error.localizedDescription)")
            }
        }

        if movedCount > 0 {
            print("V2LegacyMigration: recovered \(movedCount) legacy sheet(s) into Documents/RecoveredFiles/")
        }
    }

    /// Whether there's at least one recovered legacy file to show - used to decide whether the
    /// "Recovered Files" entry point should be visible at all. Users who never had legacy data
    /// (or whose legacy data was already fully browsed away) see no UI change.
    static func hasRecoveredFiles() -> Bool {
        let fm = FileManager.default
        guard let documentsURL = fm.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return false
        }
        let recoveredDir = documentsURL.appendingPathComponent("RecoveredFiles")
        guard let entries = try? fm.contentsOfDirectory(
            at: recoveredDir,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ) else {
            return false
        }
        return !entries.isEmpty
    }
}
