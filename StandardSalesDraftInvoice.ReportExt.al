namespace Corbeil.Sales.Reports;

using Microsoft.Sales.Document;
using Microsoft.Finance.GeneralLedger.Setup;

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
            LayoutFile = './src/DraftInvoiceWithCurrency.docx';
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
