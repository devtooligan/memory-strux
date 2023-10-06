// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test, console2 as console} from "forge-std/Test.sol";
import "../src/LibMemArray.sol";

contract LibMemArrayTest is Test {
    using LibMemArray for *;

    function testArr() public pure {
        MemArray arr = LibMemArray.create();
        arr.push(0x69);
        require(arr.get(0) == 0x69, "get 0");
        require(arr.size() == 1, "size 1");
        arr.push(0x269);
        require(arr.get(1) == 0x269, "get 1");
        require(arr.size() == 2, "size 2");
        arr.push(0x369);
        require(arr.get(2) == 0x369, "get 2");
        require(arr.size() == 3, "size 3");

        uint[] memory out = arr.toArray();
        require(out.length == 3, "legacy length");
        require(out[0] == 0x69, "legacy 0");
        require(out[1] == 0x269, "legacy 1");
        require(out[2] == 0x369, "legacy 2");

        uint x0 = arr.pop();
        console.log("x0", x0);

        uint[] memory legacy = new uint[](3);
        legacy[0] = 0x6000;
        legacy[1] = 0x6111;
        legacy[2] = 0x6222;
        MemArray arr2 = legacy.fromArray();
        require(arr2.size() == 3, "legacy size");
        require(arr2.get(0) == 0x6000, "legacy get 0");
        require(arr2.get(1) == 0x6111, "legacy get 1");
        require(arr2.get(2) == 0x6222, "legacy get 2");
    }

    function testFuzz_fromArrayMemorySafety(uint256[] memory _from) public {
        // Grab the size of the array
        uint256 size = _from.length;
        
        // Grab the free memory pointer
        uint64 freeMemPtr;
        assembly {
            freeMemPtr := mload(0x40)
        }
        
        // The following operation should expand memory by:
        // 1. 96 bytes for the linked list fat pointer
        // 2. 64 bytes for the head node
        // 3. 64 * N bytes for the array elements.
        // Totaling 96 + 64 + 64 * N bytes.
        //
        // The only memory that this operation should be allowed to touch is in
        // the range [free_mem_ptr, free_mem_ptr + 96 + 64 + 64 * N).
        vm.expectSafeMemory(freeMemPtr, freeMemPtr + 96 + 64 + 64 * uint64(size));
        _from.fromArray();
    }
}
