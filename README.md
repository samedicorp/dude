# Welcome, DUDE.

Welcome to DUDE, the Dual Universe Data Enclave*.

This is an open source repository containing data files useful for [Dual Universe](https://dualthegame.com) scripting.

### Industry

The first file in this repo is a dump of all schematics JSON data, initially captured by Movix using an in-game script. 

The plan is to try to keep this up to date by re-running the script periodically.

Along with the raw data are some index files processed from it, which may prove to be more compact/useful, depending on your requirements.

These have been automatically generated from the raw data, and will be updated whenever it is.

### Data Files

```
Data/
  Schematics/
    raw.json        The raw data dump
    compact.json    A compact index removing all names.
    names.json      An index mapping a schematic name to its id.
    ids.json        An index mapping a schematic id to its name.
    
  Products/
    products.json   A dump of all products, extracted from the schematic data, indexed by type identifier.
    names.json      An index that maps from a product name to the corresponding type identifier. 
    ids.json        An index that maps from a product id to the corresponding type identifier.
```
(* _yes, this absolutely could have been any word at all, as long as it began with "E" and enabled the cheesy acronym_)

