# GGQCustomizations — AL working agreement

Single per-tenant extension holding **all** GoGo Quinoa customizations. Read `README.md`
for the object registry and folder layout; this file is the rules.

## Non-negotiables
- **Never change the app `id`** (`8f2d1a40-3c5e-4b9a-9f1e-6a7b2c3d4e5f`). BC keys upgrades on
  the GUID. The app can be renamed freely; the GUID cannot.
- **Never rename an already-published object.** The XLIFF `trans-unit` id is a hash of the
  object name — renaming orphans its French translation. This is why reportextension 60102
  "Draft Invoice Currency" keeps its unprefixed name.
- **One app.** Do not scaffold a second AL project for a new report. New objects go here.
- **Bump `version` in app.json on every publish.**

## Conventions
- Object range **60000–60999**: 60000s tables · 60100s report extensions · 60200s reports and
  labels · 60300s pages · 60400s codeunits · 60500s enums. Check `README.md`'s registry for
  the next free ID and **add the new object to that table** in the same change.
- Files: `Rep<id>.<Name>.al`, `RepExt<id>.<Name>.al`, `Tab<id>.<Name>.al`, `Cod<id>.<Name>.al`,
  `Pag<id>.<Name>.al`, under `src/<Kind>/`.
- Namespaces `GGQ.<Area>.<Kind>` (e.g. `GGQ.Inventory.Reports`). New object names prefixed `GGQ `.
- **Report layouts live in the repo**, next to their `.al`, bound with `LayoutFile = './src/...'`.
  Never leave a layout as a manual upload in Report Layouts — it wouldn't be version-controlled.
- **Every user-visible string is a `Label`**, never typed into a Word layout. Layout text can't
  be translated; label text flows through the dataset and can. See `docs/translations.md`.
- French: add a `<target>` to `Translations/GoGo Quinoa Customizations.fr-CA.xlf` for each new
  label, merging from the generated `.g.xlf`. Printed language follows the **customer/vendor
  Language Code** (FRC/ENC), not the user's UI language.

## Build & publish
1. `AL: Download symbols`
2. `Ctrl+Shift+B` — regenerates `Translations/*.g.xlf`
3. `Ctrl+F5` to publish, or upload the `.app` via Extension Management

If a publish complains about removed or changed objects, use **Schema Update Mode = Force Sync**.
Safe while this app owns no tables. Once it does, stop and think first.

## Data conventions that matter here
- Item Ledger Entry `Quantity` is **always in base UOM**. Purchase/receipt line `Quantity` is in
  the line's UOM — use `Quantity (Base)` when you need base units.
- Posted receipt → lots: `Item Ledger Entry` where `Document Type = Purchase Receipt`,
  `Document No.` = receipt no., `Document Line No.` = line no.
- Bags per KG comes from `Item Unit of Measure."Qty. per Unit of Measure"`, not from the line.

## In flight
Report **60201 GGQ Receipt Label** — AL written (`src/Reports/Labels/Rep60201.ReceiptLabel.al`),
no layout yet. Spec: `docs/wms-receiving-labels.md`. Remaining: label stock/printer decision
(drives Word vs RDLC layout), Insight Works Barcode Rule for the printed barcode, French
translations, confirm BAG UOM conversions exist on purchased items.
