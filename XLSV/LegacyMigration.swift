//
//  LegacyMigration.swift
//  XLSV
//
//  One-time, idempotent recovery step for users upgrading from the 1.3.6-era file format --
//  ported from the xlsv-205 (com.yumiya.blueframe) codebase 2026-08-24, now that this app has
//  taken over that bundle ID and is the one that will actually receive upgrading users'
//  Documents containers. Verified this repo's own ReadWriteJSON.saveJsonFile uses the exact
//  same Documents/sub/ + forced-".xml"-extension convention as the code this was ported from,
//  so the detection heuristic below carries over unchanged.
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
//  This migration does NOT try to reconstruct those sheets into the live/editable workbook --
//  moves the legacy files out of Documents/sub/ so they stop being mixed in with the current
//  id-based sheet cache, into a clearly separate, clearly labeled Documents/RecoveredFiles/
//  folder where RecoveredFilesViewController can list and export them.
//
import Foundation

enum LegacyMigration {

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
    ///
    /// Returns the number of files actually moved *by this call* -- deliberately not the same
    /// as "how many recovered files currently exist" (RecoveredFilesViewController.recoveredFileNames().count),
    /// which stays nonzero forever once anything's been recovered. LegacyFileCheckViewController
    /// uses this return value to show its one-time "Files Recovered" alert only on the launch
    /// that actually found something new, not on every subsequent launch.
    @discardableResult
    static func migrateLegacySheetsIfNeeded() -> Int {
        let fm = FileManager.default
        guard let documentsURL = fm.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return 0
        }

        let subDir = documentsURL.appendingPathComponent("sub")
        guard fm.fileExists(atPath: subDir.path) else {
            return 0
        }

        guard let entries = try? fm.contentsOfDirectory(
            at: subDir,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ) else {
            return 0
        }

        // Legacy sheets are files with no ".xml" extension - the current format always uses
        // "sheet<id>.xml" / "csv_sheet1.xml" style names.
        let legacyFiles = entries.filter { $0.pathExtension.lowercased() != legacyFileExtension }
        guard !legacyFiles.isEmpty else {
            return 0
        }

        let recoveredDir = documentsURL.appendingPathComponent("RecoveredFiles")
        if !fm.fileExists(atPath: recoveredDir.path) {
            do {
                try fm.createDirectory(at: recoveredDir, withIntermediateDirectories: true)
            } catch {
                print("LegacyMigration: failed to create RecoveredFiles directory: \(error.localizedDescription)")
                return 0
            }
        }

        var movedCount = 0
        for fileURL in legacyFiles {
            let destinationURL = recoveredDir.appendingPathComponent(fileURL.lastPathComponent)
            if fm.fileExists(atPath: destinationURL.path) {
                // Already recovered previously, or a name collision - never overwrite existing data.
                print("LegacyMigration: skipping '\(fileURL.lastPathComponent)', already present in RecoveredFiles")
                continue
            }
            do {
                try fm.moveItem(at: fileURL, to: destinationURL)
                movedCount += 1
                print("LegacyMigration: moved legacy sheet '\(fileURL.lastPathComponent)' into Documents/RecoveredFiles/")
            } catch {
                print("LegacyMigration: failed to move '\(fileURL.lastPathComponent)': \(error.localizedDescription)")
            }
        }

        if movedCount > 0 {
            print("LegacyMigration: recovered \(movedCount) legacy sheet(s) into Documents/RecoveredFiles/")
        }

        return movedCount
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
