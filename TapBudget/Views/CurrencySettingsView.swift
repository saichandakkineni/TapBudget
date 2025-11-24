import SwiftUI

/// View for currency settings
struct CurrencySettingsView: View {
    @State private var selectedCurrency: String = CurrencyManager.shared.selectedCurrency.code
    
    var body: some View {
        List {
            Section {
                ForEach(CurrencyManager.supportedCurrencies, id: \.code) { currency in
                    HStack {
                        Text(currency.symbol)
                            .font(.title2)
                            .frame(width: 40)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(currency.name)
                                .font(.body)
                            Text(currency.code)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        if selectedCurrency == currency.code {
                            Image(systemName: "checkmark")
                                .foregroundColor(.accentColor)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedCurrency = currency.code
                        CurrencyManager.shared.setCurrency(currency.code)
                    }
                }
            } header: {
                Text("Select Currency")
            } footer: {
                Text("All amounts will be displayed in the selected currency. Note: Currency conversion requires an internet connection and exchange rate API.")
            }
        }
        .navigationTitle("Currency")
        .navigationBarTitleDisplayMode(.inline)
    }
}

