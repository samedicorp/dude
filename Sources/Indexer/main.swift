// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 05/05/2021.
//  All code (c) 2021 - present day, Elegant Chaos.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

/*
 {"604112": {"id": 604112, "ingredients": [{"name": "Glass product", "quantity": 1.0, "type": "GlassProduct", "id": 2118283057}, {"name": "Basic LED", "quantity": 1.0, "type": "led_1", "id": 1137501015}], "level": 1, "products": [{"name": "Basic Laser Chamber xs", "quantity": 1.0, "type": "laserchamber_1_xs", "id": 604112}], "time": 60.0, "name": "Basic Laser Chamber xs"}
 */

struct Product: Codable {
    let name: String
    let type: String
    let id: Int?
    
    init(_ productQuantity: ProductQuantity) {
        self.name = productQuantity.name
        self.type = productQuantity.type
        self.id = productQuantity.id
    }
}

struct ProductQuantity: Codable {
    let name: String
    let quantity: Double
    let type: String
    let id: Int?
}

struct Schematic: Codable {
    let id: Int
    let name: String
    let ingredients: [ProductQuantity]
    let level: Int
    let products: [ProductQuantity]
    let time: Double
}

struct CompactQuantity: Codable {
    let product: String
    let quantity: Double
}

struct CompactSchematic: Codable {
    let ingredients: [CompactQuantity]
    let products: [CompactQuantity]
    let level: Int
    let time: Double
}

typealias Schematics = [String:Schematic]

let dataURL = URL(fileURLWithPath: #file).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("Data")

var schematicNameToID: [String:Int] = [:]
var schematicIDToName: [Int:String] = [:]
var compactSchematics: [Int:CompactSchematic] = [:]
var productsByType: [String:Product] = [:]
var productNameToType: [String:String] = [:]
var productIDToType: [Int:String] = [:]

func write<T>(_ value: T, name: String, kind: String = "Schematics") where T: Encodable {
    let encoder = JSONEncoder()
    do {
        let url = dataURL.appendingPathComponent(kind).appendingPathComponent(name).appendingPathExtension("json")
        let data = try encoder.encode(value)
        try data.write(to: url)
    } catch {
        print("Failed to encode \(value).\n\n\(error)")
    }
}

func add(product: Product) {
    if let existing = productsByType[product.type] {
        assert(existing.name == product.name)
        assert(existing.type == product.type)
        assert(existing.id == product.id)
    }
    productsByType[product.type] = product
    if let id = product.id {
        productIDToType[id] = product.type
    }
    productNameToType[product.name] = product.type
}


let decoder = JSONDecoder()
let url = dataURL.appendingPathComponent("Schematics").appendingPathComponent("raw.json")
let data = try Data(contentsOf: url)
let schematics = try decoder.decode(Schematics.self, from: data)

print("\(schematics.count) records imported.")


for (id, schematic) in schematics {
    assert(Int(id) == schematic.id)
    schematicNameToID[schematic.name] = schematic.id
    schematicIDToName[schematic.id] = schematic.name
    for product in schematic.products {
        add(product: Product(product))
    }
    let compactIngredients = schematic.ingredients.map({ CompactQuantity(product: $0.type, quantity: $0.quantity)})
    let compactProducts = schematic.products.map({ CompactQuantity(product: $0.type, quantity: $0.quantity)})
    let compact = CompactSchematic(ingredients: compactIngredients, products: compactProducts, level: schematic.level, time: schematic.time)
    compactSchematics[schematic.id] = compact
}

write(compactSchematics, name: "compact")
write(schematicNameToID, name: "names")
write(schematicIDToName, name: "ids")
write(productsByType, name: "products", kind: "Products")
write(productNameToType, name: "names", kind: "Products")
write(productIDToType, name: "ids", kind: "Products")
