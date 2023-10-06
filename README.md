## MemoryStrux

**Optimized, in-memory, memory safe data structures.**

__This is a proof of concept for you to build on, not fully tested or production ready__


-   [MemArray](#MemArray): Dynamic resizing uint array.
-   [MemDict](#MemDict): Dictionary type data structure with import/export to storage mappings.

## Usage

### MemArray

_Optimized, memory-safe, dynamically resizing, in-memory array._

```solidity
type MemArray is bytes32;

MemArray myArray = LibMemArray.create();

// push, pop, get
myArray.push(0x69);  // [0x69]
myArray.push(0x420);  // [0x69, 0x420]
myArray.get(1); // 0x420
myArray.pop();  // (returns 0x420) [0x69]

// to/from legacy array
uint[] memory legacyArray = myArray.toArray();
MemArray myOtherArray = legacyArray.fromArray();

```

### MemDict
_Optimized, memory-safe, dynamically resizing, in-memory dictionary like data structure._

Note: This is _not_ a hash map and lookup times are O(n).  However, due to gas, for smaller dictionaries the cost is less than a O(1) lookup in a storage mapping.

```solidity
type MemDict is bytes32;

MemDict myDict = LibMemDict.create();
myDict.set(0x01, 0x999);
myDict.get(0x01);
```

In addition to basic functionality, MemDict can be imported from or exported to a storage mapping:

```solidity
mapping(uint -> uint) public myMapping;

uint[] keys = new uint[](3);
keys[0] = 1
keys[1] = 2
keys[2] = 3

MemDict myDict = LibMemDict.create();
myDict.set(keys[0], 0x69);
myDict.set(keys[1], 0x6969);
myDict.set(keys[2], 0x696969);

myDict.toMapping(myMapping); // sets values of 3 keys on storage mapping

MemDict myOtherDict = LibMemDict.createFromMapping(myMapping, keys); // creates new MemDict based on storage values for selected keys

```

## Future Direction

- [x] Uint MemArray
- [ ] Int MemArray
- [ ] Bytes32 MemArray
- [x] Dictionary
- [ ] Set
- [ ] Queue
- [ ] Stack
- [x] Linked List (TODO: separate LL logic from MemArray)
- [ ] Tree
- [ ] Graph
