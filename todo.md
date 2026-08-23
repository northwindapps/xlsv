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
