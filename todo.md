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
