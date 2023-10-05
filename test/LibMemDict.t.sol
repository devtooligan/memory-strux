// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test, console2 as console} from "forge-std/Test.sol";
import "../src/LibMemDict.sol";

contract LibMemArrayTest is Test {
    using LibMemDict for *;

    mapping(uint => uint) public someMap;

    function testMemDict() public {
        MemDict myDict = LibMemDict.create();
        myDict.set(0x69, 0x420);
        require(myDict.get(0x69) == 0x420, "get 0x69");

        myDict.set(0x01, 0x02);
        myDict.sum(0x01, 0x02);
        require(myDict.get(0x01) == 0x04, "2 + 2 != 4");

        myDict.clear(0x01);
        require(myDict.get(0x01) == 0x00, "clear");


        // test create from mapping
        uint256[] memory someKeys = new uint256[](3);
        someKeys[0] = 0x2;
        someKeys[1] = 0x3;
        someKeys[2] = 0x4;

        uint256[] memory someValues = new uint256[](3);
        someValues[0] = 0x22;
        someValues[1] = 0x33;
        someValues[2] = 0x44;

        someMap[someKeys[0]] = someValues[0];
        someMap[someKeys[1]] = someValues[1];
        someMap[someKeys[2]] = someValues[2];

        MemDict myOtherDict = LibMemDict.createFromMapping(someMap, someKeys);
        require(myOtherDict.get(someKeys[0]) == someValues[0], "cfm get 0");
        require(myOtherDict.get(someKeys[1]) == someValues[1], "cfm get 1");
        require(myOtherDict.get(someKeys[2]) == someValues[2], "cfm get 2");

        myOtherDict.clear(someKeys[0]);
        myOtherDict.clear(someKeys[1]);
        myOtherDict.clear(someKeys[2]);

        // test import from mapping
        myOtherDict.importFromMapping(someMap, someKeys);
        require(myOtherDict.get(someKeys[0]) == someValues[0], "ifm get 0");
        require(myOtherDict.get(someKeys[1]) == someValues[1], "ifm get 1");
        require(myOtherDict.get(someKeys[2]) == someValues[2], "ifm get 2");

        // test toMapping
        someMap[someKeys[0]] = 0x0;
        someMap[someKeys[1]] = 0x0;
        someMap[someKeys[2]] = 0x0;

        myOtherDict.toMapping(someMap);

        require(someMap[someKeys[0]] == someValues[0], "tm get 0");
        require(someMap[someKeys[1]] == someValues[1], "tm get 1");
        require(someMap[someKeys[2]] == someValues[2], "tm get 2");



    }
}
