> Part of the **GoGo Quinoa Customizations** app. Source: `src/ReportExtensions/RepExt60102.DraftInvoiceCurrency.al`

# Add Currency Code to Draft Invoice (report 1303) Word layout

## Why this is needed
The Draft Invoice is report **1303** "Standard Sales - Draft Invoice" (1306 is the *posted* invoice). Its dataset has no standalone currency column — currency only appears embedded in `TotalExclVATText` / `TotalInclVATText`. This report extension adds two columns to the Header dataitem:

- `CurrencyCode` — the document's Currency Code, falling back to the LCY code (CAD) when blank
- `CurrencyCode_Lbl` — the label "Currency"

## Step 1 — Deploy the extension
1. Open this folder in VS Code with the AL Language extension.
2. `AL: Download symbols` against your BC 28 environment.
3. Object ID **60102**, range 60000-60999 (see the root `README.md` object registry).
4. `Ctrl+F5` (publish) or build the .app and upload via Extension Management.

## Step 2 — Update the Word layout
1. In BC, search **Report Layouts**.
2. Find report 1303, layout `DraftInvoiceWithCurrency.docx` (or the one you use).
3. **Export Layout** — export AFTER installing the extension so the new columns are in the custom XML part.
4. Open in Word. Enable the **Developer** tab (File > Options > Customize Ribbon).
5. Developer > **XML Mapping Pane** > select the custom XML part `urn:microsoft-dynamics-nav/reports/Standard_Sales___Draft_Invoice/1303`.
6. Under `Header`, find `CurrencyCode` and `CurrencyCode_Lbl`, right-click each > **Insert Content Control > Plain Text** at the spot where you want it (e.g. next to Payment Terms or in the totals area).
7. Save the .docx.
8. Back in **Report Layouts**: **New Layout** > report 1303 > Format Word > upload your file (or Replace Layout on an existing custom one).
9. Set it as the default via **Report Layout Selection** (or the "Set Default" action).

## Verify
Print/preview a draft invoice in a foreign currency (e.g. USD) and one in CAD — the field should show USD and CAD respectively.

## Notes
- To also cover the posted invoice later, add a second `reportextension` (next free ID in 60100-60199) extending "Standard Sales - Invoice" with the same code.
- The content control placement is per-layout; if you maintain the Blue/Email layouts too, repeat step 2 for each.
