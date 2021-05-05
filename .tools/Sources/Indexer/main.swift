// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 05/05/2021.
//  All code (c) 2021 - present day, Elegant Chaos.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

struct Product: Codable {
    let name: String
    let schematic: Int?
    
    init(_ productQuantity: ProductQuantity) {
        self.name = productQuantity.name
        self.schematic = productQuantity.id
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

let rootURL = URL(fileURLWithPath: #file).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
let dataURL = rootURL.appendingPathComponent("Data")

var schematicNameToID: [String:Int] = [:]
var schematicIDToName: [Int:String] = [:]
var compactSchematics: [Int:CompactSchematic] = [:]
var productsByType: [String:Product] = [:]
var productNameToType: [String:String] = [:]

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

func add(product: Product, type: String, primary: Bool) {
    let existing = productsByType[type]
    if let existing = existing {
        assert(existing.name == product.name)
        assert(existing.schematic == product.schematic)
    }
    
    if (existing == nil) || primary {
        productsByType[type] = product
        productNameToType[product.name] = type
    }
}

let decoder = JSONDecoder()
let url = dataURL.appendingPathComponent("Schematics").appendingPathComponent("raw.json")
let data = try Data(contentsOf: url)
let schematics = try decoder.decode(Schematics.self, from: data)

print("\(schematics.count) records imported.")
var text = ""

let sorted = schematics
    .values
    .sorted(by: { r1, r2 in
        if r1.level == r2.level {
            return r1.name < r2.name
        } else {
            return r1.level < r2.level
        }
    })

for schematic in sorted {
    schematicNameToID[schematic.name] = schematic.id
    schematicIDToName[schematic.id] = schematic.name
    var primary = true
    for product in schematic.products {
        add(product: Product(product), type: product.type, primary: primary)
        primary = false
    }
    for product in schematic.ingredients {
        add(product: Product(product), type: product.type, primary: false)
    }
    let compactIngredients = schematic.ingredients.map({ CompactQuantity(product: $0.type, quantity: $0.quantity)})
    let compactProducts = schematic.products.map({ CompactQuantity(product: $0.type, quantity: $0.quantity)})
    let compact = CompactSchematic(ingredients: compactIngredients, products: compactProducts, level: schematic.level, time: schematic.time)
    compactSchematics[schematic.id] = compact
    
    let ingredientText: String
    if schematic.ingredients.count == 0 {
        ingredientText = ""
    } else {
        let formatted = schematic.ingredients.map({ "- \($0.name) x \($0.quantity)"}).joined(separator: "\n")
        ingredientText = "\nIngredients:\n\(formatted)"
    }
    
    let outputText: String
    if schematic.products.count == 0 {
        outputText = ""
    } else {
        let formatted = schematic.products.map({ "- \($0.name) x \($0.quantity)"}).joined(separator: "\n")
        outputText = "\nOutput:\n\(formatted)\n"
    }

    text.append("Name: \(schematic.name)\nLevel: \(schematic.level)\nTime: \(schematic.time)\(ingredientText)\(outputText)\n\n")
}

print("\(compactSchematics.count) schematics exported.")
write(compactSchematics, name: "compact")
write(schematicNameToID, name: "names")
write(schematicIDToName, name: "ids")

print("\(productsByType.count) products exported.")
write(productsByType, name: "products", kind: "Products")
write(productNameToType, name: "names", kind: "Products")

let textURL = dataURL.appendingPathComponent("Schematics/readable.txt")
try text.write(to: textURL, atomically: true, encoding: .utf8)
