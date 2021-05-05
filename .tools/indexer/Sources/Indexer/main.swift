// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 05/05/2021.
//  All code (c) 2021 - present day, Elegant Chaos.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation
import duswift

struct CompactSchematic: Codable {
    let level: Int
    let time: Double
    let main: String?
    let ingredients: [String:Double]
    let products: [String:Double]
}


let rootURL = URL(fileURLWithPath: #file).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
let dataURL = rootURL.appendingPathComponent("Data")

var schematicNameToID: [String:Int] = [:]
var schematicIDToName: [Int:String] = [:]
var compactSchematics: [Int:CompactSchematic] = [:]
var productsByType: [String:Product] = [:]
var productNameToType: [String:String] = [:]
var text = ""
var lua = """
    local data = {}
    data.schematics = {
    
    """

func write<T>(_ value: T, name: String, kind: String = "Schematics") where T: Encodable {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]
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

func addProductLua(for product: Product, type: String) {
    let schematicString: String
    if let schematic = product.schematic {
        schematicString = ", schematic = \(schematic)"
    } else {
        schematicString = ""
    }
    
    lua.append("    [\"\(type)\"] = { name = \"\(product.name)\"\(schematicString) },\n")
}

let url = dataURL.appendingPathComponent("Schematics").appendingPathComponent("raw.json")
let schematics = try JSONSchematics.load(from: url)
let sorted = schematics.sortedByLevel
print("\(schematics.count) records imported.")


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
    let compactIngredients = Dictionary<String,Double>(uniqueKeysWithValues: schematic.ingredients.map({ (product: $0.type, quantity: $0.quantity)}))
    let compactProducts = Dictionary<String,Double>(uniqueKeysWithValues: schematic.products.map({ (product: $0.type, quantity: $0.quantity)}))
    let main = schematic.products.count > 1 ? schematic.products.first?.type : nil
    let compact = CompactSchematic(level: schematic.level, time: schematic.time, main: main, ingredients: compactIngredients, products: compactProducts)
    compactSchematics[schematic.id] = compact
    
    text.append(schematic.summary)
    lua.append("    [\(schematic.id)] = \(schematic.asLUA),\n")
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

lua += "}\n\nproducts = {\n"
for (type, product) in productsByType {
    addProductLua(for: product, type: type)
}

lua += "}\n\nreturn data"
let luaURL = dataURL.appendingPathComponent("Schematics/data.lua")
try lua.write(to: luaURL, atomically: true, encoding: .utf8)
