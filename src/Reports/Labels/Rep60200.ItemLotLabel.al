namespace GGQ.Inventory.Reports;

using Microsoft.Inventory.Tracking;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using System.Text;

/// <summary>
/// Item/lot identification label driven from the Lot No. Information card.
/// Prints item no. (Code128), description, lot no. and expiry date.
///
/// TODO layout: no Word layout file exists yet. Publish once, then in BC use
/// Report Layouts > Export Layout on this report to get the generated .docx,
/// design it, save it as src/Reports/Labels/ItemLotLabel.docx and re-add:
///
///   DefaultRenderingLayout = WordLayout;
///   rendering
///   {
///       layout(WordLayout)
///       {
///           Type = Word;
///           LayoutFile = './src/Reports/Labels/ItemLotLabel.docx';
///           Caption = 'Item Lot Label (Word)';
///       }
///   }
/// </summary>
report 60200 "GGQ Item Lot Label"
{
    ApplicationArea = All;
    Caption = 'Item Lot Label';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(LotInfo; "Lot No. Information")
        {
            RequestFilterFields = "Item No.", "Lot No.";

            column(ItemNo; "Item No.") { }
            column(ItemNoBarcode; ItemNoBarcodeTxt) { }
            column(ItemDescription; ItemDescriptionTxt) { }
            column(LotNo; "Lot No.") { }
            column(LotExpiryDate; ExpiryDateTxt) { }

            trigger OnAfterGetRecord()
            var
                Item: Record Item;
                ItemLedgerEntry: Record "Item Ledger Entry";
                BarcodeFontProvider: Interface "Barcode Font Provider";
                BarcodeSymbology: Enum "Barcode Symbology";
            begin
                // Item description
                if Item.Get("Item No.") then
                    ItemDescriptionTxt := Item.Description
                else
                    ItemDescriptionTxt := '';

                // Encode Item No. for Code 128 barcode font
                ItemNoBarcodeTxt := '';
                if "Item No." <> '' then begin
                    BarcodeFontProvider := Enum::"Barcode Font Provider"::IDAutomation1D;
                    BarcodeSymbology := Enum::"Barcode Symbology"::Code128;
                    BarcodeFontProvider.ValidateInput("Item No.", BarcodeSymbology);
                    ItemNoBarcodeTxt := BarcodeFontProvider.EncodeFont("Item No.", BarcodeSymbology);
                end;

                // Lot expiry date: taken from the item ledger (posted receipt carries it)
                ExpiryDateTxt := '';
                ItemLedgerEntry.SetRange("Item No.", "Item No.");
                ItemLedgerEntry.SetRange("Lot No.", "Lot No.");
                if "Variant Code" <> '' then
                    ItemLedgerEntry.SetRange("Variant Code", "Variant Code");
                ItemLedgerEntry.SetRange(Positive, true);
                ItemLedgerEntry.SetFilter("Expiration Date", '<>%1', 0D);
                if ItemLedgerEntry.FindLast() then
                    ExpiryDateTxt := Format(ItemLedgerEntry."Expiration Date", 0, '<Year4>-<Month,2>-<Day,2>');
            end;
        }
    }

    requestpage
    {
    }

    labels
    {
        ItemNoCaption = 'Item No.';
        DescriptionCaption = 'Description';
        LotNoCaption = 'Lot No.';
        ExpiryCaption = 'Expiry Date';
    }

    var
        ItemNoBarcodeTxt: Text;
        ItemDescriptionTxt: Text;
        ExpiryDateTxt: Text;
}
