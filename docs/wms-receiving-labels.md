# Warehouse receiving labels — design spec

Status: **design agreed, report 60201 not yet written.**
Context date: 2026-09-09.

## Goal
Receive purchase orders on handhelds and print an identification label per physical unit
(bag) before put-away. Traceability is a hard requirement — GoGo Quinoa is a food manufacturer.

Required label content:
item code · item description · PO number · supplier lot number · manufacturer best-before
date · receipt date.

## The WMS: WMS Express (Insight Works / DMSi)

Free BC extension, 5 devices per company, Android handhelds only.
Tiers: Standard (PO receiving) · Basic Warehouse · Warehouse (warehouse receipts).

**How printing actually works — this is the key constraint:**
WMS Express cannot talk to printers. It hands the print request to Business Central, and BC
prints through **PrintNode** (account + desktop client on a machine with printer access + API key).

| Setting | Page |
|---|---|
| PrintNode API key | *Insight Works PrintNode Setup* |
| Printer discovery | *Insight Works PrintNode Printers* → New > Get Printers |
| Which report is the label | *Insight Works Report Selection*, Usage = "Item Label" (default report **23045000**) |
| Printer per device | *WMS Express Device Configuration* → General → Label Printer Name |
| Print trigger | *WMS Express Device Configuration* → Receiving → **Print On Qty. Change = Yes** |

After changing device config: on the handheld, **Menu > Reload Config**.

**Known limitation:** the out-of-the-box Item Label report is **Item-table based** — item no.
and description only. Insight Works confirms anything richer is a custom report built by the
partner. Whether WMS Express passes PO / lot / expiration context to a custom report on a
qty-change print is **unverified** — ask Insight Works before designing around it.

**Upgrade path:** WMS Express and Warehouse Insight cannot coexist (same object range, same
`WHI` web service, Codeunit 23044900 "WHI Data Broker"). Same Android APK; uninstall Express
before installing Insight, and re-publish the web service if it disappears. BC-native data and
this label report survive the switch; WMS-app config is re-entered. Warehouse Insight is the
only tier with **License Plating** (pallet IDs) — likely the eventual reason to pay.

## Decision: print from the POSTED receipt, not on scan

Rationale: every required field provably exists after posting; labels stay **reprintable**
forever (decisive in a recall); and it depends on zero WMS Express internals. Cost is a short
walk to the printer after posting.

Flow: release PO → handheld scans PO, bin, item → quantity dialog captures qty + lot no. +
expiration date → **Menu > Post** → label report runs off the posted receipt.

## Field mapping

| Label field | Source |
|---|---|
| Item code | `Purch. Rcpt. Line."No."` |
| Description | `Purch. Rcpt. Line.Description` |
| PO number | `Purch. Rcpt. Line."Order No."` |
| Supplier lot no. | `Item Ledger Entry."Lot No."` |
| Best before | `Item Ledger Entry."Expiration Date"` |
| Receipt date | `Purch. Rcpt. Header."Posting Date"` |
| Vendor, qty, UOM | receipt header / line |

Join posted receipt line → lots:
`Item Ledger Entry` where `Document Type = Purchase Receipt`,
`Document No.` = receipt no., `Document Line No.` = line no.

## Label count: KG ordered → bags received

Patrick orders in **KG**; the supplier delivers **bags**. Bag weight is on the item's
UOM conversion. Because the PO line UOM is KG, the bag UOM never appears on the line — the
report must look it up.

```
Bags = Item Ledger Entry.Quantity / Item Unit of Measure."Qty. per Unit of Measure"
```

(ILE `Quantity` is always base UOM = KG, so no conversion needed.)

**Which UOM is "the bag":** use `Item."Put-away Unit of Measure Code"` (semantically exactly
"the unit we handle in the warehouse"), falling back to `Item."Purch. Unit of Measure"`, then
base UOM = 1 label. Add a dedicated `GGQ Label UOM Code` field only if a real conflict appears.

```al
local procedure BagsForLot(ItemNo: Code[20]; LotQtyBase: Decimal; var QtyPerBag: Decimal): Integer
var
    Item: Record Item;
    ItemUOM: Record "Item Unit of Measure";
    UOMCode: Code[10];
begin
    Item.Get(ItemNo);
    UOMCode := Item."Put-away Unit of Measure Code";
    if UOMCode = '' then
        UOMCode := Item."Purch. Unit of Measure";
    if UOMCode = '' then
        UOMCode := Item."Base Unit of Measure";

    QtyPerBag := 1;
    if ItemUOM.Get(ItemNo, UOMCode) and (ItemUOM."Qty. per Unit of Measure" > 0) then
        QtyPerBag := ItemUOM."Qty. per Unit of Measure";

    exit(Round(LotQtyBase / QtyPerBag, 1, '>'));  // partial bag still needs a label
end;
```

**Compute per lot, not per line.** A 1,000 KG line arriving as three supplier lots is three
sets of labels with three different best-before dates.

**Remainder handling.** Suppliers rarely deliver whole multiples (50 lb = 22.68 KG bags).
Round the count **up**, and print each bag's **actual weight** with the last one flagged
`PARTIAL` — that makes the label countable for inventory, not decorative.

**Rejected alternative:** receiving in BAG instead of KG would give an exact count with no
rounding, but pricing and supplier contracts are in KG. Don't distort the commercial data to
make a label print.

## Barcode
Encode item + lot + qty in one concatenated Code128 (or GS1-128 with AIs `(01)` `(10)` `(17)`
if a customer ever requires it), then add a matching regex in **Insight Works Barcode Rules**
so scanning our own label during put-away / pick / count auto-fills item tracking. Designing
the barcode without the parsing rule wastes half the value.

Existing barcode approach in this app: `Rep60200 "GGQ Item Lot Label"` uses BC's
`Barcode Font Provider` interface (IDAutomation1D / Code128).

## Prerequisite BC setup (verify before building)
- **Item Tracking Code**: Lot Specific Tracking = Yes · Lot Warehouse Tracking = Yes ·
  Man. Expir. Date Entry Reqd. = Yes · Strict Expiration Posting = Yes.
- **Items**: tracking code assigned; `Expiration Calculation` **blank** so the receiver enters
  the manufacturer's date rather than BC computing one.
- **Lot numbering**: use the **supplier's lot number as the BC Lot No.** — one-to-one
  traceability, no cross-reference. Only invent internal lots if supplier lots collide.
- **Item Unit of Measure**: confirm purchased items actually have a BAG UOM with
  `Qty. per Unit of Measure` populated. If not, the label count silently collapses to 1 per lot.
- Bins: if Bin Mandatory is on, the bin must be on the PO line or the handheld errors.
  Insight Works recommends inventory put-aways in that case.

## Open items
1. Confirm BAG UOM conversions exist on the purchased items.
2. Ask Insight Works what context a custom Item Label report receives on a qty-change print.
3. Decide label stock size and printer model — drives Word vs RDLC layout.
4. Write report **60201 GGQ Receipt Label** + its layout; add to `README.md` registry.
