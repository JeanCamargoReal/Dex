//
//  DexWidget.swift
//  DexWidget
//
//  Created by Jean Camargo on 29/03/26.
//

import WidgetKit
import SwiftUI

// MARK: - Provider (Provedor de dados da Timeline)
// O Provider é responsável por fornecer os dados que o widget vai exibir.
// Ele conforma ao protocolo TimelineProvider, que exige 3 funções obrigatórias.
struct Provider: TimelineProvider {

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
        for hourOffset in 0 ..< 5 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let entry = SimpleEntry.placeholder
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
    let sprite: Image
    
    static var placeholder: SimpleEntry {
        SimpleEntry(
            date: .now,
            name: "bulbasaur",
            types: ["grass", "poison"],
            sprite: Image(.bulbasaur)
        )
    }
    
    static var placeholder2: SimpleEntry {
        SimpleEntry(
            date: .now,
            name: "mew",
            types: ["psyhic"],
            sprite: Image(.mew)
        )
    }
}

// MARK: - DexWidgetEntryView (View do Widget)
// A View que define a interface visual do widget.
// Recebe uma entry do Provider e usa seus dados para renderizar o conteúdo.
struct DexWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        VStack {
            entry.sprite
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
                    // containerBackground: define o fundo do widget (obrigatório no iOS 17+)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                DexWidgetEntryView(entry: entry)
                    .padding()
                    .background()
            }
        }
        // Nome exibido na galeria de widgets
        .configurationDisplayName("My Widget")
        // Descrição exibida na galeria de widgets
        .description("This is an example widget.")
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
