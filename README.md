# GoGo Quinoa Customizations

Single per-tenant extension (PTE) holding **all** Business Central customizations for
GoGo Quinoa. One app, one object range, one deployment, one translation set.

| | |
|---|---|
| App ID | `8f2d1a40-3c5e-4b9a-9f1e-6a7b2c3d4e5f` (never change — BC keys upgrades on it) |
| Publisher | Patrick Corbeil |
| Target | BC 28 (Cloud / SaaS), runtime 17.0 |
| Object range | **60000–60999** |
| Environments | Sandbox `Sandbox07082026` (see `.vscode/launch.json`) |

## Object ID blocks

| Range | Kind |
|---|---|
| 60000–60099 | Tables, table extensions |
| 60100–60199 | Report extensions |
| 60200–60299 | Reports (incl. labels) |
| 60300–60399 | Pages, page extensions |
| 60400–60499 | Codeunits |
| 60500–60599 | Enums |

## Object registry

Keep this table current — it is the fastest way to find a free ID.

| ID | Type | Name | Purpose | Docs |
|---|---|---|---|---|
| 60102 | reportextension | Draft Invoice Currency | Adds `CurrencyCode` to report 1303 for Word layouts | [docs](docs/draft-invoice-currency.md) |
| 60200 | report | GGQ Item Lot Label | Item/lot label from Lot No. Information (Code128) | — |
| 60201 | report | GGQ Receipt Label | Per-bag receiving label from a posted purchase receipt, one per lot | [docs](docs/wms-receiving-labels.md) |

## Folder layout

```
app.json
README.md
src/
  Reports/            reports; label reports under Reports/Labels/
  ReportExtensions/   extensions to standard reports
  Tables/  Pages/  Codeunits/  Enums/
Translations/         *.fr-CA.xlf (the *.g.xlf is generated, gitignored)
docs/                 per-feature notes and deployment steps
.output/              local build artifacts, gitignored
```

## Conventions

- **Layout files live in the app**, next to their report, and are bound with
  `LayoutFile = './src/...'`. Never leave a layout as a manual upload in Report Layouts —
  it would not be version-controlled.
- **File naming**: `Rep<id>.<Name>.al`, `RepExt<id>.<Name>.al`, `Tab<id>.<Name>.al`,
  `Cod<id>.<Name>.al`, `Pag<id>.<Name>.al`.
- **Object naming**: prefix new objects `GGQ ` (e.g. `GGQ Item Lot Label`).
  Objects already published without the prefix keep their name — renaming one changes its
  XLIFF trans-unit hash and orphans its French translation.
- **Namespaces**: `GGQ.<Area>.<Kind>`, e.g. `GGQ.Sales.Reports`, `GGQ.Inventory.Reports`.
- **Every user-visible string is a `Label`**, never hard-coded in a Word layout —
  layout text cannot be translated. See [docs/translations.md](docs/translations.md).
- **Bump `version` in app.json** on every publish so Extension Management shows what is live.

## Build & publish

1. `AL: Download symbols` against the target environment.
2. `Ctrl+Shift+B` to build (regenerates `Translations/GoGo Quinoa Customizations.g.xlf`).
3. `Ctrl+F5` to publish, or build the `.app` and upload via Extension Management.

> **First publish after the 2.0.0.0 restructure:** objects were renamespaced. If publishing
> reports removed/changed objects, use **Schema Update Mode = Force Sync**. Safe here — the
> app owns no tables and therefore no data.

## History

- **2.0.0.0** — Renamed from "Draft Invoice Currency" to a consolidated customizations app.
  ID range widened 60100–60149 → 60000–60999. Objects moved into `src/` by type;
  Item Lot Label renumbered 50100 → 60200 and brought into the app.
- **1.1.0.0** — Initial: report extension 60102 adding Currency Code to draft invoice 1303.
