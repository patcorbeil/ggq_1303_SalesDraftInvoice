# Adding the French translation

1. Rebuild the app (Ctrl+Shift+B). With the "TranslationFile" feature enabled, the compiler now generates `Translations\GoGo Quinoa Customizations.g.xlf` (source language, all labels).
2. Copy that file and rename the copy to `GoGo Quinoa Customizations.fr-CA.xlf` (keep it in the Translations folder).
3. Edit the copy:
   - On the `<file>` element, add `target-language="fr-CA"`.
   - For each `<trans-unit>`, add a `<target>` line under the `<source>`:

```xml
<trans-unit id="..." size-unit="char" translate="yes" xml:space="preserve">
  <source>Currency</source>
  <target>Devise</target>
  ...
</trans-unit>
```

   (Keep the `id` exactly as generated — it's a hash, don't invent it.)
4. Rebuild and publish. Print a draft invoice for a customer whose Language Code is FRC — the label shows "Devise"; ENC/ENU customers still get "Currency".

## Notes

- The built-in labels (Payment Terms, Shipment Method, Total, etc.) are translated by Microsoft's base app — nothing to do there.
- The language that prints is driven by the **Language Code on the customer card** (FRC = fr-CA, ENC = en-CA), not by the user's UI language.
- If you add more labels later, repeat: rebuild → merge new trans-units from the .g.xlf into the .fr-CA.xlf. The VS Code extension "XLIFF Sync" automates this merge.
- Word-layout caveat: labels flow through the dataset (CurrencyCode_Lbl), so translation is automatic. Any text you typed directly INTO the Word layout is static — keep text out of the layout and bind labels instead if it must be bilingual.
