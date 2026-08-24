# TODO

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
