# TODO

## Potential: targeted 2-cell reload on cursor selection instead of full reloadData()

Status: idea, not started (raised 2026-09-08). Not a bug -- current behaviour is by design.

`didSelectItemAt` ([ViewController.swift](XLSV/ViewController.swift#L1632), + the
FileFillViewController equivalent) calls `myCollectionView.reloadData()` on every
data-cell tap to move the red cursor border + drag-handle diamond. This does NOT trigger
a full layout rebuild -- `CustomCollectionViewLayout.prepare()` takes its cheap
`!dataSourceDidUpdate` fast path ([CustomCollectionViewLayout.swift:298](XLSV/CustomCollectionViewLayout.swift#L298))
-- but it does re-run `cellForItemAt` for every visible cell (~300-400 on a full screen),
each doing location lookups + style/border/attributed-string setup. That's the visible
flicker on selection.

Only 2 cells actually change appearance on a normal tap: the old cursor cell (loses
border + handle) and the new one (gains them). `cellForItemAt` already clears the border
on every cell and re-adds only when `cursor == key`, so a 2-cell reload is visually
correct:
```swift
let oldPath = currentindex
// ... set currentindex = indexPath; cursor = ...
var paths = [indexPath]
if let oldPath = oldPath, oldPath != indexPath { paths.append(oldPath) }
UIView.performWithoutAnimation { myCollectionView.reloadItems(at: paths) }
```

Needs handling:
1. Row-filter mode -- a cell key is `"col,realRow"`; converting back to an IndexPath
   needs the inverse of `realRow(forDisplaySection:)` (via `appd.visibleRows`).
2. Range selection -- when `changeaffected` is non-empty (drag-selected range), >2 cells
   lose their border; reload those too, or fall back to `reloadData()` in that case.
3. Drag-handle diamond z-index -- it overhangs the cell's bottom-right corner. With
   `reloadData()` the draw order is deterministic; with partial `reloadItems` the
   selected cell must carry a raised `zIndex` in the layout's `cellAttrsDictionary` or a
   neighbour clips it. Needs an on-device check.
4. Consistency -- arrow-key nav (`imoveUp/Down/Left/Right`), tap-to-move, and paste also
   `reloadData()` after moving the cursor. Optimising only `didSelectItemAt` leaves those;
   doing all is the same helper applied ~6 sites x 2 controllers.

Estimate: ~1h + device check for item 3. Decide scope (tap-select only vs. all
cursor-move paths) when picked up.

## Form Fill mode: add xlsx column-width/row-height write/read persistence

Status: not started. `ViewController.swift` already has this working end-to-end;
`FileFillViewController.swift` (Form Fill mode) deliberately does not.

**What ViewController.swift already does (2026-08-23):**
- `service.swift`: `patchColumnWidths`/`patchRowHeights` write `appd.cswLocation`/
  `customSizedWidth`/`cshLocation`/`customSizedHeight` into `<cols>`/`<row ht=>` on
  save, via an extended `flushPendingEditsToXlsx(fp:edits:columnWidths:rowHeights:sizeSheetIndex:)`.
- `ExcelHelper.swift`: `parseCustomCellSizes` (called from `readExcel2`) reads those
  same `<cols>`/`<row ht=>` back out on import, via a regex scan of the already-in-memory
  sheet XML (not a full DOM parse -- kept cheap for large files).
- `ViewController.swift`'s own `flushPendingXlsxChangesIfNeeded()` is the only call
  site wired to pass `columnWidths`/`rowHeights`/`sizeSheetIndex` through.

**What's needed to bring Form Fill mode up to parity:**
- Wire `FileFillViewController.swift`'s own `flushPendingXlsxChangesIfNeeded()` to
  build the same `columnWidths`/`rowHeights` arrays (from `appd.cswLocation`/
  `customSizedWidth`/`cshLocation`/`customSizedHeight`) and pass them into
  `flushPendingEditsToXlsx`, same as ViewController's version does.
- `appd.pendingCellSizeChanges` dirty-flag wiring (set in `cellSizePatchWidthChanged`/
  `HeightChanged`, checked in `updateUnsavedDataReminderVisibility`) would need the
  same treatment there too, since it currently only exists in ViewController.swift.

**Why this was held off (2026-08-23):** `ExcelHelper.swift`'s `readExcel2`/
`parseCustomCellSizes` is shared code already exercised by Form Fill's own import path
([FileFillViewController.swift:1695](XLSV/FileFillViewController.swift#L1695)), and the
regex-based `<cols>`/`<row>` parser only recognizes the specific attribute shape this
app itself writes -- it isn't a general-purpose XML parser, so it may not pick up
everything real-world files exported from official Excel or Google Sheets contain. The
user explicitly asked to hold off extending the *write* side into Form Fill until this
parser is more robust, given Form Fill's larger/more "production" real-world file usage.
Before wiring the write side in, consider hardening `parseCustomCellSizes` against a
wider variety of real Excel/Google Sheets `<cols>`/`<row>` markup (attribute order,
missing `customHeight=`, ranged `<col min max>` spans, etc.), and testing against actual
files exported from both.

## Row/col delete (still shelved) -- scoping note for whenever this is picked up

Status: not started, shelved since the original `Form-filling-mode pivot` decision
(unresolved merge-cell render bug in the app's own grid layout -- an in-app rendering
bug, separate from the xlsx-write correctness question below).

**Correctness bar, decided 2026-08-23:** the hard requirement is *structural/schema
validity* -- never trigger Excel/Google Sheets' "we found a problem with this file"
repair dialog on open. That means, in priority order: (1) row/cell renumbering, (2)
`<dimension>` staying accurate, (3) `<mergeCells>` ranges adjusted or dropped, (4)
`<cols>` ranges shifted, (5) general XML well-formedness. Validate all of these --
`tools/xlsx_corruption_check.py` already checks most of them.

**Explicitly NOT required for a first version:** automated formula-reference-shifting
after a delete. A formula left pointing at a stale/shifted cell, or producing `#REF!`,
is completely valid XML/OOXML and never triggers Excel's repair dialog -- it's just a
wrong number the user can see and fix by hand, which the user has confirmed is an
acceptable outcome. Don't build reference-shifting (and don't build a formula AST/tree
for it -- `CalculationService.swift`'s existing regex-based `extractExcelCellReferences`
is the right level of machinery if this ever gets picked up) as part of the delete
feature's launch scope; it's a lower-stakes follow-up.

See `feedback_xlsx_structural_validity_over_formula_correctness` in Claude's memory for
the full reasoning.

## Local on-device LLM (Gemma) command interface -- draft plan

Status: idea stage, not started. Target device assumption: iPhone SE 4 (A18 chip, 8GB
RAM) -- the low end of what Apple treats as "on-device AI capable" (8GB is Apple
Intelligence's own minimum), so plan for this as the floor, not a device with headroom
to spare.

**Model/hardware feasibility (researched 2026-08-23):**
- Gemma 4 E2B (smallest current variant) needs ~1.5GB RAM at 4-bit quantization, has
  native JSON-formatted function-calling output, and a 128K context window. A CoreML-LLM
  iPhone sample reported ~11 tok/s at ~250MB RAM; MLX-based inference should be
  comparable or better. E2B is the realistic fit for an 8GB device that also has to run
  XLSV and iOS itself in that same budget -- E4B (the next size up) is a stretch goal for
  higher-RAM devices, not the v1 baseline.
- E2B is sized for general chat/multimodal use; this app's job is much narrower -- a
  fixed handful of tool schemas, not open-ended conversation -- so it's worth treating
  E2B as the *ceiling*, not the target, and trying smaller/older Gemma tiers (e.g. Gemma
  3 1B, or a smaller fine-tune scoped to just this tool schema) first during the
  feasibility spike below. Downgrade freely if a smaller model still calls the right tool
  reliably -- less RAM/battery pressure on an 8GB device that also has to run XLSV and
  iOS, and the confirm-before-execute step (see Safety/UX) is there specifically so an
  occasional wrong tool call from a smaller model is caught before it touches the file,
  not a correctness risk. Only step up in size if accuracy on this narrow task actually
  requires it.
- MLX Swift (Apple's framework, best on-iPhone performance) requires **iOS 17+**. XLSV's
  current deployment target is iOS 15.6 -- gate this feature behind
  `if #available(iOS 17, *)` rather than raising the app-wide minimum, so it's simply
  absent on older devices/OS without regressing support for existing users.
- Don't bundle the model weights in the IPA (blows up App Store binary size and cellular
  download limits) -- download-on-first-use into Documents/Caches, with a settings
  toggle to delete it and reclaim space.

**Architecture -- reuse today's tested range-operation surface, never give the model raw
XML access:**
- This session hardened and validated the row/col insert/delete path end-to-end
  (`testRangeOperationsBox` in service.swift; `rowInsertOperation`/`rowDeleteOperation`/
  `columnInsertOperation`/`columnDeleteOperation` in ViewController.swift/
  FileFillViewController.swift; `patchMergeCellsForInsert`/`Delete`; the new
  `patchDimension`) plus the typed autofill engine. Expose these as a small fixed set of
  named tools (`insert_rows(at, count)`, `delete_rows(at, count)`, `insert_columns`,
  `delete_columns`, `fill_range(range, values_or_formula)`, `set_cell(ref, value)`) that
  Gemma calls via its function-calling output.
- The model only ever emits a tool call -- never XML, never touches the xlsx write path
  directly. This app validates the call (range bounds, sheet exists, etc.) and routes it
  into the exact same code paths already proven today, so the "never trigger Excel's
  repair dialog" structural-validity bar holds regardless of what the model produces. A
  tool call that fails validation is rejected before reaching any write path.

**Safety/UX:** given the user's stated preference for keyboard-driven flows over gestures
(see Claude's memory `feedback_prefer_typed_syntax_over_drag`), the entry point is a
text/command bar: a typed instruction goes to Gemma, comes back as one or more tool
calls, and -- since these are the same structurally destructive ops tested today (they
can shift/drop a lot of data if misapplied) -- the app shows a plain-language preview
("Insert 2 rows at row 6", "Delete columns I-K") for the user to confirm before actually
executing, rather than auto-running silently.

**Phased build-out (v1 -- structural range ops only):**
1. Feasibility spike: run a quantized Gemma 4 E2B via MLX Swift in a throwaway test
   target; measure load time, tokens/sec, and peak memory on an actual iPhone SE 4 (or
   nearest available A18/8GB device) -- no XLSV integration yet.
2. Model delivery: download-on-first-use + cache, per above.
3. Tool surface: fixed JSON schema for the handful of range-operation tools; a thin
   dispatcher that validates a tool call and calls into the existing Swift functions.
4. Command bar UI + confirm-before-execute preview.
5. Test pass reusing this session's methodology -- before/after xlsx diff +
   `tools/xlsx_corruption_check.py` per tool -- but driven by model-generated tool calls
   instead of manual UI taps, to catch both app bugs and model tool-calling mistakes.

**Phase 2+: broader task surface.** The model's ceiling is the tool surface, not the
model itself -- any task becomes reachable once there's a matching deterministic Swift
function the dispatcher can validate and call, same guarantee as v1. Candidate tasks
discussed 2026-08-23, in roughly easiest-to-hardest order:
- **Summarize this data** -- read-only, so none of the structural-validity concerns
  apply; could actually ship *before* any mutating v1 tool. Needs a `read_range`/
  `get_sheet_data` tool so the model pulls only the relevant cells into context rather
  than the whole sheet dumped in -- watch the 128K context budget against the 100k-row
  files already seen in this project (see Claude's memory
  `project_xlsx_heavy_edit_crash_fixes`). No confirm-before-execute needed since nothing
  is written.
- **Make next month's calendar** -- the layout itself is pure deterministic date math,
  nothing for the model to get wrong; it just recognizes intent and calls
  `insert_calendar(sheet, start_cell, month, year)`, built entirely out of traditional
  code and the same `set_cell`/`fill_range` primitives as v1. Low-risk proof-of-concept
  for "generate structured content" tasks generally.
- **Sort this file** -- genuinely new work, no existing primitive to build on. Harder
  than insert/delete's uniform index-shifting because merged cells and formulas
  referencing absolute positions can break under arbitrary row reordering, not just a
  fixed offset -- needs its own correctness pass (before/after diff + corruption check)
  same as row/col ops got this session, not a quick add-on.

**Phase 2+: RAG, gated on need.** Only worth adding once a task actually hits a limit
plain retrieval can't solve -- a single sheet past the context-window scale (100k-row
files, again) or a query spanning multiple xlsx files (e.g. "compare this month's report
to last month's"). For anything that fits in context, exact retrieval via
`read_range`/`get_sheet_data` beats RAG's approximate similarity search -- don't add
embedding-lookup uncertainty where the real cells are simple to hand over directly. If/
when it's built: a separate, much smaller embedding model (a few hundred MB, not
Gemma-scale), a simple on-device vector index (brute-force cosine is fine at this row
count, no real vector DB needed), and row/range-based chunking that keeps a cell's
row+column context attached rather than naive text splitting -- spreadsheet data isn't
prose, chunk boundaries should respect that structure.

**Explicitly out of scope for v1:** everything in the Phase 2+ sections above. v1 is
scoped to the structural range operations already tested and trusted this session.

## Bundle ID switch to com.yumiya.blueframe (2026-08-24), and ported legacy-file recovery

Status: bundle ID switched, legacy-recovery feature ported and build-verified. Two items
carried forward from the now-superseded `xlsv-205` plan still remain (see below).

**Why:** the App Store Connect listing for bundle ID `com.yumiya.blueframe` (the real,
long-running "XLSV" app -- see `project_xlsv_repo_family_and_v205_migration` in Claude's
memory for the full repo-family history) has ~13k installs; this repo's own
`com.yumiya.xlsv2` listing has ~280. Decision: retarget *this* actively-developed
codebase (all the row/col range-op hardening etc. from this week) at the
higher-install-base bundle ID going forward, rather than the reverse (Apple doesn't allow
renaming an existing App Store Connect app record's bundle ID anyway, so this was the
only technically valid direction).

**What changed:**
- `XLSV.xcodeproj/project.pbxproj`: `PRODUCT_BUNDLE_IDENTIFIER` `com.yumiya.xlsv2` ->
  `com.yumiya.blueframe` (main app target, both Debug/Release -- the
  `com.yumiya.ocr.XLSVTests` test target was left alone).
- `XLSV/Info.plist` + `XLSV/XLSV.entitlements`: iCloud container identifier
  `iCloud.com.yumiya.xlsv2` -> `iCloud.com.yumiya.blueframe`, matching the container
  already used by the blueframe lineage (verified against `xlsv-205`'s entitlements, not
  guessed).

**Consequence handled -- legacy-file recovery moved here too:** the 1.3.6-era
migration/recovery feature built earlier the same day in `xlsv-205` (see that repo's
`todo.md`) was built on the premise that `xlsv-205` would be the codebase shipping under
`com.yumiya.blueframe`. Since *this* repo took that role instead, the feature was ported
here so upgrading 1.3.6/2.0.5 users landing on whatever gets submitted next from this
repo still get their old files recovered, not silently dropped:
- `LegacyMigration.swift`, `RecoveredFilesViewController.swift`: ported essentially
  unchanged -- verified this repo's own `ReadWriteJSON.saveJsonFile` uses the identical
  `Documents/sub/` + forced-`.xml`-extension convention the legacy-detection heuristic
  depends on, so it carries over safely. `RecoveredSheetDetailViewController`'s column-
  name conversion was pointed at this repo's own `ExcelHelper().GetExcelColumnName`
  instead of carrying over a second copy of that algorithm.
- `LegacyFileCheckViewController.swift`: same pre-launch check-before-the-user-sees-
  anything screen, retargeted to proceed to this repo's `"Home"` storyboard identifier
  instead of `xlsv-205`'s `"StartLine"`. Wired into `AppDelegate.swift` as the actual
  cold-launch root, ahead of `Home`.
- Registered in `XLSV.xcodeproj/project.pbxproj` (4 manual insertion points each, same as
  `xlsv-205` needed -- Write-created files aren't auto-added to the Xcode project).
  Build-verified (`xcodebuild ... -scheme XLSV`, **BUILD SUCCEEDED**, bundle id confirmed
  as `com.yumiya.blueframe` in the build log).

**Bug found and fixed same day, via real on-device testing (2026-08-24):**
`RecoveredSheetDetailViewController.excelLocation(from:)` passed 1.3.6's raw location
indices straight into `ExcelHelper.GetExcelColumnName`, which expects 1-based columns
(returns `""` for 0). Confirmed against the real 1.3.6 source
(`currentindexstr = String(currentindex!.item) + "," + String(currentindex!.section)`,
0-based UICollectionView indices) that both column and row needed `+1`. Column 0 -- a
real, valid cell -- was rendering with an empty column letter.

**Superseded later the same day: absolute +1 offset replaced with relative positioning.**
The `+1` fix above assumed 1.3.6's raw 0-based indices map directly onto absolute 1-based
Excel columns/rows once corrected -- but a real on-device screenshot of 1.3.6's own grid
showed a value at its own displayed "A2" while the recovered detail view (using the +1
fix) labeled that same cell "B3", a full step further off. Whether index 0 is a real data
column/row or a header gutter in 1.3.6's own UICollectionView layout couldn't be nailed
down with certainty from source alone. Rather than keep guessing at the exact absolute
mapping, `RecoveredSheetDetailViewController` now computes positions *relative to the
sheet's own used range* (min column/row found -> "A"/row 1, preserving relative layout
between cells regardless of what the raw indices actually represent) -- correct
regardless of the absolute-offset question, since what matters for recovery is that
cells retain their layout relative to each other.

**Also fixed the same day, per explicit request: CSV export now shapes as a real grid,
not "Cell,Value" pairs.** the `exportTapped()` CSV export was originally two columns
(`Cell,Value` header, one data row per non-empty cell) -- correct data, but not something
that reproduces the sheet's layout when opened in Excel/Numbers. Now builds a proper
`[[String]]` grid sized to the sheet's used range (via the same relative positioning
above), places each value at its actual row/column position (blank for unused cells),
and joins rows as real CSV lines with comma/quote/newline-aware escaping.

## Bundle ID swap sequence: one final com.yumiya.xlsv2 release, then blueframe (2026-08-25)

Status: both steps complete. Currently on `com.yumiya.blueframe`, version 3.1.0 --
**ready to archive/submit as the actual blueframe release once you're ready.**

Given the same-display-name confusion risk discussed the same day (searching "XLSV"
could surface two listings, and existing xlsv2 users searching later would find an
unfamiliar "GET" listing with none of their data), the swap was staged in two steps
instead of one direct cutover:

1. **One farewell release under `com.yumiya.xlsv2`, version bumped to 3.5.4** (past the
   3.5.3 already live -- the checked-out project file still said 3.5.1, drifted from
   what was actually last submitted). Added a one-time "Important Notice" alert on
   `HomeController`, shown once per launch, telling existing users this app won't be
   updated further and to search for the new listing -- with an explicit warning that
   the new app is separate and won't have their files, plus instructions to export
   first (MENU -> Export, Files or Email) before switching. No direct App Store link
   was included -- blueframe's listing status was ambiguous ("removed from account" vs.
   a "2.0.5 Ready for Distribution" row shown in the same screenshot) and a dead link in
   a real user-facing notice would've been worse than no link.
2. **Swapped forward to `com.yumiya.blueframe` once told the 3.5.4 release had passed
   review** (2026-08-25): bundle ID + iCloud container (`iCloud.com.yumiya.blueframe`)
   restored, the temporary notice alert removed entirely (it was explicitly marked
   TEMPORARY in its own comment, scoped to that one xlsv2 release only), version bumped
   to **3.1.0** -- chosen to land above the `3.0.0 "Prepare for Submission"` slot already
   showing on the blueframe App Store Connect record, not related to xlsv2's own 3.5.x
   numbering (separate app record, separate version lineage). Build-verified.

Release notes for the 3.5.4 farewell build were also written in English + ja/zh-Hans/de/
da/fr, natural-translated (not literal), covering the actual accumulated UI changes
(header cell background, cursor-cell selection handle, cell resize view, the notice
itself) -- not persisted to a file, only given directly in chat for pasting into App
Store Connect's per-locale fields.

**Also found and fixed the same day: no way to actually reach "Recovered Files" at all.**
The one-time "Files Recovered" alert (built as part of the port above) correctly told the
user their data was saved under "Recovered Files" -- but nothing in the app's UI actually
let them navigate there once they tapped OK. This is what item 2 below was tracking, and
is now done: `HomeController.swift` adds a 4th button to its mode-picker stack, gated on
`LegacyMigration.hasRecoveredFiles()`, invisible to everyone else. Confirmed via
screenshots from real on-device testing that the migration + alert path were both working
correctly the whole time -- what looked like "migration not working, no content values
seen" was this missing entry point, not a data or parsing bug (the off-by-one fix above
was real but independent, and wouldn't on its own have caused a fully empty screen).

**Still needed (carried forward from `xlsv-205/todo.md`, now scoped to this repo):**
1. Reskin `RecoveredFilesViewController` onto this repo's own `BackupTableViewController`
   pattern (loading overlay/spinner, tap-row -> action sheet) -- this repo already has
   that pattern natively, so this port is more direct than it was in `xlsv-205`.
2. ~~A permanent "Recovered Files" entry point in the main UI~~ **Done 2026-08-24** -- see
   above.
3. Actually reconstructing a recovered sheet into the live workbook as a new sheet
   (content-only, no styling -- see the reasoning already written up in
   `xlsv-205/todo.md`). Unlike in `xlsv-205`, **this repo already has everything the
   reconstruction needs** -- `testRangeOperationsBox`'s bulk `<sheetData>` rewriter,
   `excelAddSheet` for creating a new sheet, `patchDimension`, and
   `tools/xlsx_corruption_check.py` for validation -- so this is now a much smaller lift
   here than it would have been in `xlsv-205`.

**Not carried forward -- outside this repo's scope:** `xlsv-205`'s own copy of this
feature and its `todo.md` entry are now dead code from a superseded plan (that repo isn't
what's shipping under `com.yumiya.blueframe`) -- left in place there rather than deleted,
but not being developed further.

## In-app cell styling (text color / fill color / font size) -- working plan

Status: **text/fill colour + font size + Normal/Bold/Italic all done & device-verified
(colour/size 2026-09-07, bold/italic + Form Fill port + blank-cell preview 2026-09-08) --
no file corruption / repair dialog.** Single cell, both ViewController and Form Fill.
StyleTableEditor + PendingStyleChangeSet + flush wiring + 🎨 format-panel button. 5
StyleTableEditor XCTests pass, build clean. Colour/size round-trip verified on device
(ViewController): live preview, save+reopen preserves, Numbers/Excel open with **no repair
dialog**.

Bold/Italic (2026-09-08, device-verified -- no file corruption): the panel's new
`normalBoldItalicselector` segmented control (Normal/Bold/Italic -- mutually exclusive,
can't do both at once) -> `boldItalicChanged()` in both controllers ->
`PendingStyleEdit.bold/italic` -> `StyleTableEditor.styleIndex(bold:italic:)` (already
modelled in FontSpec; reuses an existing matching `<font>`, e.g. Excel's stock bold font,
else appends). `testExtractStyle` already parses `<b>`/`<i>` so it reads back on reopen.
Live preview via `cellBold[i]`/`cellItalic[i]`. CSV: preview only, not persisted to the
JSON sidecar.

Font-family picker (`fonttypeselector` UIPickerView, added to the xib but NOT wired) --
see separate todo below.

What landed:
- `StyleTableEditor.swift` -- parses styles.xml, find-or-create over fonts/fills/cellXfs,
  appends-only, bumps `count=`, explicit `rgb="FFRRGGBB"`, literal-anchor splice. 3 XCTests
  in XLSVTests.swift (append / dedup-on-reparse / no-op) -- pass with
  `IPHONEOS_DEPLOYMENT_TARGET=15.6` override (the XLSVTests target's own deployment target
  is a stale 12.0 and needs that flag to build at all -- pre-existing, not this work).
- `PendingStyleChangeSet.swift` -- deferred per-cell {textColor?, fillColor?, fontSize?}
  deltas, merge-on-repeat. ViewController owns one (`pendingStyleChanges`), cleared
  everywhere `pendingXlsxChanges` is, flushed in `flushPendingXlsxChangesIfNeeded`.
- `service.swift`: `flushPendingEditsToXlsx(... styleChanges:)` -- after testExtractStyle's
  styles.xml write, runs StyleTableEditor to resolve each delta -> new xf index, rewrites
  styles.xml, then applies `s=` per cell. `applyCellSplice` gained `styleIdxOverride:` (for
  cells with a content edit too) and `styleOnly:` (patch just the opening-tag `s=`, or
  insert `<c r s/>`).
- ViewController: `installFormatPanelButton()` adds a 🎨 button right of `cellSizeSlicer`
  (the storyboard never had an entry point for `formatview`/`Fview`); `openFormatView()`
  builds the panel from `formatviewboard.xib`, wires the 13 colour buttons (c1..c15) +
  size slider + back. `fonteditmode()` / `sliderValueChanged()` now record into
  `pendingStyleChanges` for xlsx (named colour -> hex via new `namedCellColorHex`) while
  keeping the CSV JSON-sidecar path. Both were also made xlsx-safe: they no longer grow
  `location` for xlsx (would desync cellStyleId/cellFormulaXml/cellBold... -- see
  `project_pendingxlsx_deferred_write_gap`); a cursor cell with no render slot still
  records the pending change, just no in-grid preview until the next reload.

Next:
1. ~~Real round-trip~~ **done 2026-09-07** -- save/reopen/Numbers/Excel all clean on device.
2. ~~Blank never-written cell preview gap~~ **done 2026-09-08** -- new `ensureRenderSlot()`
   (both controllers) grows every array index-aligned with `location` for xlsx
   (content/locationInExcel/cellStyleId/cellFormulaXml/textsize/bgcolor/tcolor); the
   cellBold-family lag safely (cellForItemAt bounds-checks `i < cellBold.count`) until the
   next resolveCellStyles(). `fonteditmode()`/`sliderValueChanged()` now route through it.
3. ~~FileFillViewController port~~ **done 2026-09-08** -- `pendingStyleChanges` + `styleChanges:`
   through its `flushPendingXlsxChangesIfNeeded`, 🎨 button, xlsx-safe fonteditmode/slider,
   cleared at all 4 pendingXlsxChanges.clear() sites + daily-backup guard. Not device-tested yet.
4. ~~Bold/Italic~~ **done 2026-09-08** (not device-tested). Underline is the same pattern
   (`FontSpec.strike`/`underline` already exist; `testExtractStyle` already parses `<u>`/
   `<strike>`) if wanted -- no dedicated control on the panel yet.
5. **Font-family picker** (`formatview.fonttypeselector`, a UIPickerView already in the
   xib). Blocked on rendering: `cellFont(size:bold:italic:)` always returns a *system*
   font -- no per-cell family rendering, and `testExtractStyle` doesn't parse `<font><name>`.
   To make it usable: (a) parse `<name>` into a new `appd.fontNames` table + resolve onto
   a per-cell `cellFontName` array in `resolveCellStyles()`; (b) `cellFont()` takes a name
   and does `UIFont(name:size:)` with a system fallback; (c) pick the picker's list
   (bundled iOS families, or a fixed Excel-ish set: Calibri/Arial/Times New Roman/
   Helvetica/Courier New...); (d) `PendingStyleEdit.fontName` + `StyleTableEditor.styleIndex(fontName:)`
   -- the write side is trivial, `FontSpec.name` is already there. Until then the picker
   is inert.
6. Borders / alignment / number formats -- additive on the same StyleTableEditor machinery.

--- original plan below ---

Originally deferred 2026-08-25 ("it is a big
work, deal with future"); now scoped down to a shippable v1. Surfaced while investigating
a reported color-rendering gap vs v205/blueframe -- that investigation was dropped (color
*display* confirmed working, no bug). The real idea: let a user pick/change a cell's text
color, fill color, and font size *from within the app*, persisted back into the saved
xlsx.

### Current state (everything style-related is read-only)

- `Service.testExtractStyle(url:)` ([service.swift](XLSV/service.swift), ~L95) parses
  `xl/styles.xml` into flat parallel arrays on `appd`: `fontSizes`/`fontColors`/
  `fontBolds`/`fontItalics`/`fontUnderlines`/`fontStrikes` (indexed by fontId),
  `fillColors` (by fillId), `xfFontIds`/`xfFillIds`/`xfHorizontalAligns`/`xfVerticalAligns`/
  `xfWrapTexts` (by xf index), `cellXfs` (borderId by xf index), `numFmtIds`.
- `resolveCellStyles()` (ViewController ~L595, mirrored in FileFillViewController) maps
  each cell's `cellStyleId` -> per-cell render arrays `textsize[i]`, `tcolor[i]`,
  `bgcolor[i]`, `cellBold[i]`, ...
- `buildCellElement` / `applyCellSplice` ([service.swift](XLSV/service.swift) ~L698/771)
  on write only *carry forward* a cell's existing style index (looked up via
  `appd.excelStyleLocationAlphabet` -> `excelStyleIdx`) as `s="N"`. Nothing ever creates
  a new `<font>`/`<fill>`/`<xf>` or changes a cell's `s=`.
- `flushPendingEditsToXlsx` ([service.swift](XLSV/service.swift) ~L2957) calls
  `testExtractStyle(url:)`, which *does* rewrite `styles.xml` -- but only to append 3
  fixed numFmt `<xf>` rows (General/Date/Time) via naive
  `replacingOccurrences(of: "</cellXfs>")`. This is the only existing precedent for
  mutating styles.xml on save.
- `PendingXlsxChangeSet` is deliberately content-only (comment: "no style/border fields").
- Legacy `formatview` (`Fview`) UI -- color swatches + size slider, wired in
  FileFillViewController / PlaygroundViewController -- writes only the JSON/CSV model's
  `tcolor`/`bgcolor` *named-color* arrays to local JSON. Does not touch xlsx styles.xml.

The gap is exactly the deferral note's point: everything reads existing style entries,
nothing creates one, no cell's style index is ever changed.

### Plan -- 5 pieces, do 1-4 then ship v1

**1. Editable in-memory style model + find-or-create resolver (the real new infra).**
New type (e.g. `StyleTableEditor`, new file) holding `fonts` / `fills` / `cellXfs` as
mutable structs, seeded from what `testExtractStyle` already parsed. Core method:
`resolveStyleIndex(baseXf: Int, fontColor: String?, fontSize: String?, bgColor: String?) -> Int`
- start from `baseXf` (cell's current `s=`, or 0);
- font attr changed -> build target font (current font attrs + overrides), search `fonts`
  for exact match -> reuse id, else append -> new id;
- same for fill (patternFill / solid / fgColor);
- search `cellXfs` for an xf with same `(numFmtId, fontId, fillId, borderId, alignment)`
  -> reuse, else append with `applyFont="1"` / `applyFill="1"`;
- return the xf index.
Serialize back to styles.xml per `feedback_xlsx_xml_edit_pattern` in Claude's memory:
literal-anchor splice before `</fonts>` / `</fills>` / `</cellXfs>`, always write explicit
`rgb="FFRRGGBB"` (never theme refs), and **bump the `count=` attributes** on
`<fonts>`/`<fills>`/`<cellXfs>` (stale count = guaranteed repair-dialog trigger).
Everything else in styles.xml (borders, cellStyleXfs, dxfs, numFmts, tableStyles) stays
byte-untouched. Appends only -- existing indices must never shift (so
`testExtractStyle`'s own re-append of its 3 numFmt xfs on next load stays consistent).

**2. `PendingStyleChangeSet` -- defer to save (like Form Fill, not eager).**
Keyed `(sheetIndex, cellId)` -> `{fontColor?, fontSize?, bgColor?}`. Style edits are rare
and each save-time styles.xml rewrite is heavy -> batch, do not go eager per-edit even
though ViewController's content path is eager. At flush, before content splices:
1. run every style delta through the resolver -> `[cellId: finalXfIndex]`, mutating the
   style tables and serializing styles.xml **once**;
2. cells that also have a content edit -> pass final xf index as explicit override into
   `buildCellElement`;
3. style-only cells -> new `patchCellStyleAttribute(in:&xml, ref:, styleIdx:)` that
   rewrites just the `s="..."` inside the existing `<c r="X" ...>` open tag (adds it if
   absent), leaving `<v>` / `<f>` alone.

**3. Live in-memory sync + re-render (no save needed to see it).**
After a style edit: append the same new font/fill/xf to the `appd.*` read arrays, update/
insert the cell in `excelStyleLocationAlphabet` / `excelStyleIdx`, then re-run
`resolveCellStyles()` (or poke `tcolor[i]` / `textsize[i]` / `bgcolor[i]` directly) and
reload that item.

**4. UI -- ViewController first, single selected cell.**
Panel for the current cursor cell: ~12 preset text-color swatches, ~12 fill swatches,
font-size stepper/slider, Apply. Rebuild `formatview` or a fresh panel -- either way it
writes into `PendingStyleChangeSet`, not the JSON model. `UIColorPickerViewController`
(target 15.6, fine) is optional; presets are enough for v1.

**5. Validation.**
`tools/xlsx_corruption_check.py` after every save + real round-trip in Excel and Numbers.
Hard bar per `feedback_xlsx_structural_validity_over_formula_correctness` in memory: no
repair dialog, ever. Check specifically: count attributes match child counts, every `s=`
a cell references exists, all colors valid 8-digit ARGB.

### v1 scope

ViewController only; single selected cell; **text color + fill color + font size** only.

**Defer:** bold/italic/underline toggles (trivial follow-on -- same font find-or-create,
more attrs), borders, alignment, number formats, range application, FileFillViewController
port. All additive once steps 1-2 exist.

### Edge cases

- Cell with `s="0"` / no `s=` -> resolve against xf 0's font/fill.
- Content edit + style edit on one cell before save -> style resolves first, content
  splice uses the resolved index.
- Theme-color fonts/fills are read as resolved hex (lossy); writing always-explicit rgb
  is the accepted tradeoff.
- `buildCellElement` writes `s="N"` only when `styleIdx > 0` -- fine, new xfs append at
  index > 0.
