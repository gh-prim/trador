import SwiftUI

struct GlossaryView: View {
    @State private var search = ""

    private var results: [GlossaryTerm] {
        guard !search.isEmpty else { return Glossary.terms }
        return Glossary.terms.filter {
            $0.term.localizedCaseInsensitiveContains(search) || $0.definition.localizedCaseInsensitiveContains(search)
        }
    }

    var body: some View {
        NavigationStack {
            List(results) { item in
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.term)
                        .font(.headline)
                    Text(item.definition)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 2)
            }
            .navigationTitle("Glossary")
            .searchable(text: $search, prompt: "Search terms")
        }
    }
}
