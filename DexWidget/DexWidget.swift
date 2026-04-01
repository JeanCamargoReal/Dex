//
//  DexWidget.swift
//  DexWidget
//
//  Created by Jean Camargo on 29/03/26.
//

import WidgetKit
import SwiftUI
import CoreData

// MARK: - Provider (Provedor de dados da Timeline)
// O Provider é responsável por fornecer os dados que o widget vai exibir.
// Ele conforma ao protocolo TimelineProvider, que exige 3 funções obrigatórias.
struct Provider: TimelineProvider {
    var randomPokemon: Pokemon {
        var results: [Pokemon] = []
        
        do {
            results = try PersistenceController.shared.container.viewContext
                .fetch(Pokemon.fetchRequest())
        } catch {
            print("Couldn't fetch: \(error)")
        }
        
        if let randomPokemon = results.randomElement() {
            return randomPokemon
        }
        return PersistenceController.previewPokemon
    }

    // Retorna um entry de placeholder, usado enquanto o widget ainda está carregando.
    // É o que aparece como "preview" antes dos dados reais estarem disponíveis.
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry.placeholder
    }

    // Retorna um snapshot (captura instantânea) do widget.
    // Usado para exibir uma prévia rápida, por exemplo, na galeria de widgets.
    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry.placeholder

        completion(entry)
    }

    // Cria a timeline (linha do tempo) do widget — ou seja, uma sequência de entries
    // que o sistema usará para atualizar o widget ao longo do tempo.
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [SimpleEntry] = []

        // Gera 5 entries, cada uma com 1 hora de diferença, a partir da data atual.
        // O sistema exibirá cada entry no horário correspondente.
        let currentDate = Date()
        for hourOffset in 0 ..< 10 {
            let entryDate = Calendar.current.date(byAdding: .second,
                                                  value: hourOffset * 5,
                                                  to: currentDate)!

            let entryPokemon = randomPokemon

            let entry = SimpleEntry(date: entryDate,
                                    name: entryPokemon.name!,
                                    types: entryPokemon.types!,
                                    spriteData: entryPokemon.sprite)

            entries.append(entry)
        }

        // Cria a timeline com a política .atEnd, que significa:
        // "Quando a última entry for exibida, solicite uma nova timeline ao Provider."
        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

// MARK: - SimpleEntry (Modelo de dados do Widget)
// Cada entry representa um "momento" na timeline do widget.
// Deve conformar ao protocolo TimelineEntry, que exige pelo menos uma propriedade `date`.
struct SimpleEntry: TimelineEntry {
    let date: Date   // A data/hora em que esta entry deve ser exibida
    let name: String
    let types: [String]
    let spriteData: Data?

    var sprite: Image {
        if let data = spriteData, let uiImage = UIImage(data: data) {
            return Image(uiImage: uiImage)
        }
        return Image(.bulbasaur)
    }

    static var placeholder: SimpleEntry {
        SimpleEntry(
            date: .now,
            name: "bulbasaur",
            types: ["grass", "poison"],
            spriteData: nil
        )
    }

    static var placeholder2: SimpleEntry {
        SimpleEntry(
            date: .now,
            name: "mew",
            types: ["psychic"],
            spriteData: nil
        )
    }
}

// MARK: - DexWidgetEntryView (View do Widget)
// A View que define a interface visual do widget.
// Recebe uma entry do Provider e usa seus dados para renderizar o conteúdo.
struct DexWidgetEntryView : View {
    @Environment(\.widgetFamily) var widgetSize
    
    var entry: Provider.Entry
    
    var pokemonImage: some View {
        entry.sprite
            .interpolation(.none)
            .resizable()
            .scaledToFit()
            .shadow(color:.black, radius: 6)
    }
    
    var typesView: some View {
        ForEach(entry.types, id: \.self) { type in
            Text(type.capitalized)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.black)
                .padding(.horizontal, 13)
                .padding(.vertical, 5)
                .background(Color(type.description.capitalized))
                .clipShape(.capsule)
                .shadow(radius: 3)
        }
    }

    var body: some View {
        switch widgetSize {
        case .systemMedium:
            HStack {
                pokemonImage
                
                Spacer()
                
                VStack(alignment: .leading) {
                    Text(entry.name.capitalized)
                        .font(.title)
                        .padding(.vertical, 1)
                    
                    HStack {
                        typesView
                    }
                }
                .layoutPriority(1)
                
                Spacer()
            }
        case .systemLarge:
            ZStack {
                pokemonImage
                
                VStack(alignment: .leading) {
                    Text(entry.name.capitalized)
                        .font(.largeTitle)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                    
                    Spacer()
                    
                    HStack {
                        Spacer()
                        
                        typesView
                    }
                }
            }
            
        default:
            pokemonImage
        }
    }
}

// MARK: - DexWidget (Configuração do Widget)
// A struct principal que define o widget em si.
// Conforma ao protocolo Widget e configura como o widget funciona.
struct DexWidget: Widget {
    // Identificador único do widget. Usado internamente pelo sistema.
    let kind: String = "DexWidget"

    var body: some WidgetConfiguration {
        // StaticConfiguration: widget que não aceita input do usuário (não é configurável).
        // Recebe o kind, o provider de dados, e uma closure que retorna a View.
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                DexWidgetEntryView(entry: entry)
                    .foregroundStyle(.black)
                    // containerBackground: define o fundo do widget (obrigatório no iOS 17+)
                    .containerBackground(
                        Color(entry.types[0].capitalized),
                        for: .widget
                    )
            } else {
                DexWidgetEntryView(entry: entry)
                    .padding()
                    .background()
            }
        }
        // Nome exibido na galeria de widgets
        .configurationDisplayName("Pokemon")
        // Descrição exibida na galeria de widgets
        .description("See a random Pokemon.")
    }
}

// MARK: - Preview
// Macro de preview que permite visualizar o widget no Xcode.
// O parâmetro .systemSmall define o tamanho do widget na preview.
// O bloco `timeline` define as entries que serão usadas na simulação.
#Preview(as: .systemSmall) {
    DexWidget()
} timeline: {
    SimpleEntry.placeholder
    SimpleEntry.placeholder2
}

#Preview(as: .systemMedium) {
    DexWidget()
} timeline: {
    SimpleEntry.placeholder
    SimpleEntry.placeholder2
}

#Preview(as: .systemLarge) {
    DexWidget()
} timeline: {
    SimpleEntry.placeholder
    SimpleEntry.placeholder2
}
