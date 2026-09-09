namespace GGQ.Sales.Reports;

using Microsoft.Sales.Document;
using Microsoft.Finance.GeneralLedger.Setup;

/// <summary>
/// Adds a standalone Currency Code column to report 1303 "Standard Sales - Draft Invoice"
/// so it can be bound in a Word layout. See docs/draft-invoice-currency.md.
/// </summary>
reportextension 60102 "Draft Invoice Currency" extends "Standard Sales - Draft Invoice"
{
    dataset
    {
        add(Header)
        {
            column(CurrencyCode; GetCurrencyCode())
            {
            }
            column(CurrencyCode_Lbl; CurrencyCodeLbl)
            {
            }
        }
    }

    rendering
    {
        layout("DraftInvoiceWithCurrency.docx")
        {
            Type = Word;
            LayoutFile = './src/ReportExtensions/DraftInvoiceWithCurrency.docx';
            Caption = 'Draft Invoice with Currency (Word)';
            Summary = 'Draft invoice with currency in header and right-aligned amounts.';
        }
    }

    var
        CurrencyCodeLbl: Label 'Currency';

    local procedure GetCurrencyCode(): Code[10]
    var
        GLSetup: Record "General Ledger Setup";
    begin
        // "Currency Code" is blank on LCY documents; fall back to the LCY code (e.g. CAD)
        if Header."Currency Code" <> '' then
            exit(Header."Currency Code");
        GLSetup.Get();
        exit(GLSetup."LCY Code");
    end;
}
