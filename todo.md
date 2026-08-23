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
