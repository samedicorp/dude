// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 05/05/2021.
//  All code (c) 2021 - present day, Elegant Chaos.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import ElegantStrings
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

func matchingKey(name: String, recipes: [String:DUMap.Recipe]) -> String? {
    let lower = name.lowercased()
    if recipes[lower] != nil {
        return lower
    }
    
    if let name = lower.remainder(ifPrefix: "basic ").map({ String($0) }), recipes[name] != nil {
        return name
    }

    let swapped = ["pure", "full", "empty"]
    for item in swapped {
        if let name = lower.remainder(ifPrefix: "\(item) ").map({ String($0) }) {
            let switched = "\(name) \(item)"
            if recipes[switched] != nil {
                return switched
            }
        }
    }

    if let name = lower.remainder(ifSuffix: " product").map({ String($0) }), recipes[name] != nil {
        return name
    }

    let subs = [("fuel tank", "fuel-tank"), ("antimatter", "anti-matter"), ("infrared", "infra-red"), ("core unit", "core"), ("wingtip", "wing tip")]
    for sub in subs {
        if lower.contains(sub.0) {
            let replaced = lower.replacingOccurrences(of: sub.0, with: sub.1)
            if recipes[replaced] != nil {
                return replaced
            }
        }
    }

    return nil
}

func matchingKey(id: String, product: Product, schematic: String?, recipes: [String:DUMap.Recipe]) -> String? {
    if let matched = matchingKey(name: product.name, recipes: recipes) {
        return matched
    }

    if let matched = matchingKey(name: id, recipes: recipes) {
        return matched
    }

    if let schematic = schematic, let matched = matchingKey(name: schematic, recipes: recipes) {
        return matched
    }

    return nil
}

let url = dataURL.appendingPathComponent("Schematics").appendingPathComponent("raw.json")
let schematics = try JSONSchematics.load(from: url)
let sorted = schematics.sortedByLevel
print("\(schematics.count) records imported.")


for schematic in sorted {
    schematicNameToID[schematic.name] = schematic.id
    schematicIDToName[schematic.id] = schematic.name
    var primary = true
    let sortedProducts = schematic.products.sorted(by: { $0.name < $1.name })
    for product in sortedProducts {
        add(product: Product(product), type: product.type, primary: primary)
        primary = false
    }
    let sortedIngredients = schematic.ingredients.sorted(by: {$0.name < $1.name })
    for product in sortedIngredients {
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
let luaURL = dataURL.appendingPathComponent("data.lua")
try lua.write(to: luaURL, atomically: true, encoding: .utf8)

var recipes = DUMap.loadRecipes(normaliseNames: true)
print("\(recipes.count) recipes loaded.")

var combined: [String:FullProduct] = [:]
for product in productsByType {
    let recipe: DUMap.Recipe?
    if let key = matchingKey(id: product.key, product: product.value, schematic: schematicIDToName[product.value.schematic ?? -1], recipes: recipes) {
        recipe = recipes[key]
        recipes.removeValue(forKey: key)
    } else {
        recipe = nil
    }
    
    combined[product.key] = FullProduct(product: product.value, recipe: recipe)
}

if recipes.count > 0 {
    print("\(recipes.count) recipes weren't matched.")
    print(recipes.keys.joined(separator: "\n"))
}

write(combined, name: "combined", kind: "Products")
