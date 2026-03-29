//
//  Persistence.swift
//  Dex
//
//  Created by Jean Camargo on 06/03/26.
//

import CoreData

/// O PersistenceController gerencia a stack do Core Data no aplicativo.
struct PersistenceController {
    /// Uma instância compartilhada (Singleton) para ser usada em todo o app.
    static let shared = PersistenceController()
    
    static var previewPokemon: Pokemon {
        let context = PersistenceController.preview.container.viewContext
        
        let fetchRequest: NSFetchRequest<Pokemon> = Pokemon.fetchRequest()
        fetchRequest.fetchLimit = 1
        
        let results = try! context.fetch(fetchRequest)
        
        return results.first!
    }

    /// Uma instância configurada especificamente para as Previews do SwiftUI.
    /// Ela usa armazenamento em memória para que os dados não sejam persistidos permanentemente.
    static let preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        // Cria alguns dados de exemplo para as previews.
        let newPokemon = Pokemon(context: viewContext)
        newPokemon.id = 1
        newPokemon.name = "bulbasaur"
        newPokemon.types = ["grass", "poison"]
        newPokemon.hp = 45
        newPokemon.attack = 49
        newPokemon.defense = 49
        newPokemon.specialAttack = 65
        newPokemon.specialDefense = 65
        newPokemon.speed = 45
        newPokemon.spriteURL = URL(string: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/1.png")
        newPokemon.shinyURL = URL(string: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/shiny/1.png")
        
        do {
            try viewContext.save()
        } catch {
            print(error)
        }
        return result
    }()

    /// O container que encapsula o modelo, a stack e o armazenamento do Core Data.
    let container: NSPersistentContainer

    /// Inicializa o controlador de persistência.
    /// - Parameter inMemory: Se verdadeiro, armazena os dados em memória (/dev/null) em vez do disco.
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "Dex")
        
        if inMemory {
            // Configura o local do armazenamento para nulo para evitar persistência em disco.
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        
        // Carrega os armazenamentos persistentes.
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                /*
                 Erros comuns aqui incluem:
                 * Diretório pai não existe ou sem permissão de escrita.
                 * Falta de espaço em disco.
                 * Incompatibilidade na migração de versão do modelo.
                 */
                print(error)
            }
        })
        
        // Garante que as mudanças no contexto pai sejam automaticamente mescladas no viewContext.
        container.viewContext.mergePolicy = NSMergePolicy.mergeByPropertyStoreTrump
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}
