namespace GGQ.Inventory.Reports;

using Microsoft.Purchases.History;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Item;
using System.Text;
using System.Utilities;

/// <summary>
/// Per-bag receiving label, printed from a posted purchase receipt after posting on the
/// WMS Express handheld (labels stay reprintable forever; decisive in a recall). One label
/// per physical bag per lot, not per PO line — a single line can arrive as several supplier
/// lots with different best-before dates. Design: docs/wms-receiving-labels.md.
///
/// Layout: 4in x 6in RDLC, "GGQ Receipt Label.rdlc" — a starting stacked-field layout
/// exported from BC and hand-built to a label-sized page; still needs real design work
/// (spacing, font sizes, barcode font verification) in Report Builder.
///
/// TODO barcode rule: BarcodeTxt below encodes "ItemNo|LotNo|BagQty" (Code128, same font
/// provider as Rep60200) so rescanning the label can auto-fill item tracking on put-away /
/// pick / count — but no Insight Works Barcode Rule regex exists yet to parse that format
/// ("Open items" #2 covers the related qty-change-print question with Insight Works).
///
/// TODO French: rebuild (Ctrl+Shift+B) and merge the new trans-units generated in
/// Translations/GoGo Quinoa Customizations.g.xlf into the .fr-CA.xlf per docs/translations.md.
/// </summary>
report 60201 "GGQ Receipt Label"
{
    ApplicationArea = All;
    Caption = 'GGQ Receipt Label';
    UsageCategory = ReportsAndAnalysis;
    DefaultRenderingLayout = ReceiptLabelRDLC;

    dataset
    {
        dataitem(PurchRcptHeader; "Purch. Rcpt. Header")
        {
            RequestFilterFields = "No.";

            dataitem(PurchRcptLine; "Purch. Rcpt. Line")
            {
                DataItemLink = "Document No." = field("No.");
                DataItemTableView = where(Type = const(Item));

                dataitem(LotEntry; "Item Ledger Entry")
                {
                    DataItemLink = "Document No." = field("Document No."), "Document Line No." = field("Line No.");
                    DataItemTableView = where("Document Type" = const("Purchase Receipt"), Positive = const(true));

                    dataitem(BagLabel; "Integer")
                    {
                        DataItemTableView = sorting(Number);

                        column(BagIndex; Number) { }
                        column(BagCount; NumberOfBags) { }
                        column(BagIndexOfTxt; BagIndexOfTxt) { }
                        column(BagQty; BagQtyValue) { }
                        column(PartialTxt; PartialTxt) { }
                        column(BarcodeTxt; BarcodeFontTxt) { }

                        trigger OnPreDataItem()
                        begin
                            SetRange(Number, 1, NumberOfBags);
                        end;

                        trigger OnAfterGetRecord()
                        var
                            BarcodeFontProvider: Interface "Barcode Font Provider";
                            BarcodeSymbology: Enum "Barcode Symbology";
                            RawBarcodeTxt: Text;
                        begin
                            // Round the bag count up; whatever doesn't fill a whole bag is the last, partial one.
                            if Number = NumberOfBags then
                                BagQtyValue := LotEntry.Quantity - QtyPerBag * (NumberOfBags - 1)
                            else
                                BagQtyValue := QtyPerBag;

                            PartialTxt := '';
                            if (Number = NumberOfBags) and (BagQtyValue <> QtyPerBag) then
                                PartialTxt := PartialLbl;

                            BagIndexOfTxt := StrSubstNo(BagOfLbl, Number, NumberOfBags);

                            RawBarcodeTxt := LotEntry."Item No." + '|' + LotEntry."Lot No." + '|' +
                                Format(BagQtyValue, 0, '<Precision,3><Standard Format,9>');
                            BarcodeFontProvider := Enum::"Barcode Font Provider"::IDAutomation1D;
                            BarcodeSymbology := Enum::"Barcode Symbology"::Code128;
                            BarcodeFontProvider.ValidateInput(RawBarcodeTxt, BarcodeSymbology);
                            BarcodeFontTxt := BarcodeFontProvider.EncodeFont(RawBarcodeTxt, BarcodeSymbology);
                        end;
                    }

                    column(ItemNo; "Item No.") { }
                    column(ItemDescription; PurchRcptLine.Description) { }
                    column(PONo; PurchRcptLine."Order No.") { }
                    column(SupplierLotNo; "Lot No.") { }
                    column(BestBeforeDate; BestBeforeTxt) { }
                    column(ReceiptDate; ReceiptDateTxt) { }
                    column(VendorNo; PurchRcptHeader."Buy-from Vendor No.") { }
                    column(VendorName; PurchRcptHeader."Buy-from Vendor Name") { }
                    column(BagUOMCode; BagUOMCode) { }

                    trigger OnAfterGetRecord()
                    begin
                        // No lot, nothing traceable to print — see Prerequisite BC setup in the design doc.
                        if "Lot No." = '' then
                            CurrReport.Skip();

                        BestBeforeTxt := '';
                        if "Expiration Date" <> 0D then
                            BestBeforeTxt := Format("Expiration Date", 0, '<Year4>-<Month,2>-<Day,2>');
                        ReceiptDateTxt := Format(PurchRcptHeader."Posting Date", 0, '<Year4>-<Month,2>-<Day,2>');

                        NumberOfBags := BagsForLot("Item No.", Quantity);
                    end;
                }
            }

            trigger OnPreDataItem()
            begin
                if GetFilters = '' then
                    Error(SelectReceiptErr);
            end;
        }
    }

    requestpage
    {
    }

    rendering
    {
        layout(ReceiptLabelRDLC)
        {
            Type = RDLC;
            LayoutFile = './src/Reports/Labels/GGQ Receipt Label.rdlc';
            Caption = 'GGQ Receipt Label (RDLC)';
            Summary = 'Starter 4in x 6in label layout — still needs real design work.';
        }
    }

    labels
    {
        ItemNoCaption = 'Item No.';
        ItemDescriptionCaption = 'Description';
        PONoCaption = 'PO No.';
        SupplierLotNoCaption = 'Supplier Lot No.';
        BestBeforeDateCaption = 'Best Before';
        ReceiptDateCaption = 'Receipt Date';
        VendorNoCaption = 'Vendor No.';
        VendorNameCaption = 'Vendor';
        BagUOMCodeCaption = 'UOM';
        BagIndexOfTxtCaption = 'Bag';
        BagQtyCaption = 'Qty';
        PartialTxtCaption = 'Status';
    }

    var
        SelectReceiptErr: Label 'Select at least one posted receipt to print labels for.';
        PartialLbl: Label 'PARTIAL';
        BagOfLbl: Label 'Bag %1 of %2', Comment = '%1 = bag sequence number, %2 = total bags for this lot';
        BestBeforeTxt: Text;
        ReceiptDateTxt: Text;
        BagUOMCode: Code[10];
        QtyPerBag: Decimal;
        NumberOfBags: Integer;
        BagQtyValue: Decimal;
        BagIndexOfTxt: Text;
        PartialTxt: Text;
        BarcodeFontTxt: Text;

    local procedure BagsForLot(ItemNo: Code[20]; LotQtyBase: Decimal): Integer
    var
        Item: Record Item;
        ItemUOM: Record "Item Unit of Measure";
    begin
        // "The bag" = the unit handled in the warehouse: put-away UOM, else purchase UOM, else base (1 label).
        Item.Get(ItemNo);
        BagUOMCode := Item."Put-away Unit of Measure Code";
        if BagUOMCode = '' then
            BagUOMCode := Item."Purch. Unit of Measure";
        if BagUOMCode = '' then
            BagUOMCode := Item."Base Unit of Measure";

        QtyPerBag := 1;
        if ItemUOM.Get(ItemNo, BagUOMCode) and (ItemUOM."Qty. per Unit of Measure" > 0) then
            QtyPerBag := ItemUOM."Qty. per Unit of Measure";

        exit(Round(LotQtyBase / QtyPerBag, 1, '>'));
    end;
}
