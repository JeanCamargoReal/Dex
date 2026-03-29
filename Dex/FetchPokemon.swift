//
//  FetchPokemon.swift
//  Dex
//
//  Created by Jean Camargo on 08/03/26.
//

import Foundation

/// Estrutura responsável por mapear os dados brutos recebidos da PokéAPI.
/// Ela implementa `Decodable` para permitir a conversão automática do JSON para objetos Swift.
struct FetchPokemon: Decodable {
    let id: Int16
    let name: String
    let types: [String]
    let hp: Int16
    let attack: Int16
    let defense: Int16
    let specialAttack: Int16
    let specialDefense: Int16
    let speed: Int16
    let sprite: URL
    let shiny: URL
    
    /// Define as chaves de mapeamento para o JSON. 
    /// Devido à estrutura aninhada da PokéAPI, utilizamos enums internos para navegar nas camadas.
    enum CodingKeys: CodingKey {
        case id
        case name
        case types
        case stats
        case sprites
        
        // Navegação em: types -> [ { type: { name: "..." } } ]
        enum TypeDictionaryKeys: CodingKey {
            case type
            
            enum TypeKeys: CodingKey {
                case name
            }
        }
        
        // Navegação em: stats -> [ { base_stat: 0 } ]
        enum StatDictionaryKeys: CodingKey {
            case baseStat
        }
        
        // Mapeamento das URLs das imagens dentro de 'sprites'
        enum SpriteKeys: String, CodingKey {
            case sprite = "frontDefault"
            case shiny = "frontShiny"
        }
    }
    
    /// Inicializador personalizado para realizar a decodificação manual de estruturas JSON complexas.
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Decodificação de valores diretos do primeiro nível
        self.id = try container.decode(Int16.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        
        // --- Decodificação de Tipos ---
        // 'types' é um array no JSON. Percorremos cada item para extrair o nome do tipo.
        var decodedTypes: [String] = []
        var typesContainer = try container.nestedUnkeyedContainer(forKey: .types)
        while !typesContainer.isAtEnd {
            let typesDictionaryContainer = try typesContainer.nestedContainer(
                keyedBy: CodingKeys.TypeDictionaryKeys.self
            )
            let typeContainer = try typesDictionaryContainer.nestedContainer(
                keyedBy: CodingKeys.TypeDictionaryKeys.TypeKeys.self,
                forKey: .type
            )
            let type = try typeContainer.decode(String.self, forKey: .name)
            decodedTypes.append(type)
        }
        
        if decodedTypes.count == 2 && decodedTypes[0] == "normal" {
//            let tempType = decodedTypes[0]
//            decodedTypes[0] = decodedTypes[1]
//            decodedTypes[1] = tempType
            decodedTypes.swapAt(0, 1)
        }
        
        self.types = decodedTypes
        
        // --- Decodificação de Atributos (Stats) ---
        // 'stats' também é um array. Extraímos os valores base e os atribuímos seguindo a ordem da API.
        var decodedStats: [Int16] = []
        var statsContainer = try container.nestedUnkeyedContainer(forKey: .stats)
        while !statsContainer.isAtEnd {
            let statsDictionaryContainer = try statsContainer.nestedContainer(
                keyedBy: CodingKeys.StatDictionaryKeys.self
            )
            
            let stat = try statsDictionaryContainer.decode(
                Int16.self,
                forKey: .baseStat
            )
            decodedStats.append(stat)
        }
        // Atribuição baseada na ordem padrão retornada pela PokéAPI
        self.hp = decodedStats[0]
        self.attack = decodedStats[1]
        self.defense = decodedStats[2]
        self.specialAttack = decodedStats[3]
        self.specialDefense = decodedStats[4]
        self.speed = decodedStats[5]
        
        // --- Decodificação de Imagens (Sprites) ---
        // Acessamos o objeto 'sprites' para obter as URLs das imagens normal e brilhante (shiny).
        let spriteContainer = try container.nestedContainer(
            keyedBy: CodingKeys.SpriteKeys.self,
            forKey: .sprites
        )
        self.sprite = try spriteContainer.decode(URL.self, forKey: .sprite)
        self.shiny = try spriteContainer.decode(URL.self, forKey: .shiny)
    }
}
