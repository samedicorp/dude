# Welcome, DUDE.

Welcome to DUDE, the Dual Universe Data Enclave*.

This is an open source repository containing data files useful for [Dual Universe](https://www.dualuniverse.game) scripting.

**Credits**: Thanks to **Movix** for the initial data extraction, **Archaegeo:** for feedback & suggestions, and of course to Novaquark for the actual game.

---

(* _yes, the last word of the name absolutely could have been anything at all, as long as it began with "E" and enabled the cheesy acronym_)


### Industry

The first category of data archived here is a dump of all schematics and products. 

This comes in the form of JSON data, captured using an in-game script and the schematics API. 

My plan is to try to keep this up to date by re-running the script periodically. If you notice minor errors, please also consider correcting it and submitting a [pull request](https://github.com/samedicorp/dude/pulls).

Along with the raw data are some index files processed from it, which may prove to be more compact/useful, depending on your requirements.

These have been automatically generated from the raw data, and will be updated whenever it is.

There is also a human-readable dump of the data (`readable.txt`), and some generated Lua code (`data.lua`) which you can copy & paste into your scripts.

#### Efficiency

Each schematic uses one or more ingredients, and produces one or more products. In the raw data dump, all the data for each product is repeated everywhere that it appears, which is not very efficient.

A compact schematic index has therefore been generated, which only refers to each product using its unique identifier and quantity. 

To accompany this, the product data has been extracted into its own file. With both files you can reconstruct the full data if you need to. 

The product index includes links back to the id of the schematic that makes it. If a product is produced by more than one schematic (eg as a side-effect of another schematic), it is linked only to the schematic where it is the main output. 

### Data Files

```
Data/
  data.lua        Lua code which defines a schematic index and a product index.

  Schematics/
    raw.json        The raw data returned by the schematics API.
    compact.json    A compact index removing all names.
    names.json      An index mapping a schematic name to its id.
    ids.json        An index mapping a schematic id to its name.
    readable.txt    A human-readable version of the data.

  Products/
    products.json   A dump of all products, extracted from the schematic data, indexed by type identifier.
    names.json      An index that maps from a product name to the corresponding type identifier. 
```

### Suggestions Wanted

Is there more data that you'd like to see collected here?

It makes sense to pool our effort so if anyone wants to suggest or supply other static data files for inclusion, I am up for that.

In particular, some of the data files from [dumap](https://github.com/yamamushi/dumap) might make sense in here, if we can keep them up to date and if the original authors are ok with it.

Add an [issue](https://github.com/samedicorp/dude/issues) or a [pull request](https://github.com/samedicorp/dude/pulls) if you have suggestions...