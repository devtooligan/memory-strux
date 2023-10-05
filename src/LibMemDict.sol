// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {console2 as console} from "forge-std/Test.sol";

type MemDict is bytes32; // this is a ptr

/// @notice An optimized, in-memory, memory-safe, dictionary data structure.
/// @author @devtooligan
library LibMemDict {
    struct DictNode {
        bytes32 next;
        uint256 key;
        uint256 value;
    }

    struct LinkedList {
        uint256 keysLength;
        DictNode head; // memloc of head node
        DictNode tail; // memloc of tail node
    }

    function create() internal pure returns (MemDict newDict) {
        // linked lists always have a head node which does not contain a value
        DictNode memory head;
        LinkedList memory list = LinkedList({keysLength: 0, head: head, tail: head});
        assembly {
            newDict := list
        }
    }

    /// @dev there is no protection against duplicate keys
    function addKey(MemDict ptr, uint256 key) internal pure returns (MemDict newDict) {
        LinkedList memory linkedList = getLinkList(ptr);
        _addKey(linkedList, key);
        return ptr;
    }


    function set(MemDict ptr, uint256 key, uint256 value) internal pure returns (MemDict) {
        LinkedList memory linkedList = getLinkList(ptr);
        DictNode memory node = _getOrAddDictNode(linkedList, key);
        node.value = value;
        return ptr;
    }

    /// @dev like set() but it adds the value to the existing value
    function sum(MemDict ptr, uint256 key, uint256 value) internal pure returns (MemDict) {
        LinkedList memory linkedList = getLinkList(ptr);
        DictNode memory node = _getOrAddDictNode(linkedList, key);
        node.value += value;
        return ptr;
    }

    function getLinkList(MemDict ptr) internal pure returns (LinkedList memory linkedList) {
        assembly {
            linkedList := ptr
        }
        return linkedList;
    }

    function get(MemDict ptr, uint256 key) internal pure returns (uint256) {
        LinkedList memory linkedList = getLinkList(ptr);
        require(linkedList.keysLength > 0, "out of bounds");
        (bool success, DictNode memory node) = _getNodeByKey(linkedList.head, key);
        require(success, "key not found");
        return node.value;
    }

    function clear(MemDict ptr, uint256 key) internal pure {
        LinkedList memory linkedList = getLinkList(ptr);
        (bool success, DictNode memory node) = _getNodeByKey(linkedList.head, key);
        require(success, "key not found");
        node.value = 0;
    }

    function keysLength(MemDict ptr) internal pure returns (uint256) {
        LinkedList memory linkedList = getLinkList(ptr);
        return linkedList.keysLength;
    }

    function toMapping(MemDict ptr, mapping(uint => uint) storage mappingTarget) internal {
        LinkedList memory linkedList = getLinkList(ptr);
        DictNode memory node = linkedList.head;
        for (uint i = 0; i < linkedList.keysLength; i++) {
            assembly {
                node := mload(node) // node = node.next
            }
            mappingTarget[node.key] = node.value;
        }
    }

    function importFromMapping(MemDict ptr, mapping(uint => uint) storage mappingTarget, uint[] memory keys) internal view {
        LinkedList memory linkedList = getLinkList(ptr);
        for (uint i = 0; i < keys.length; i++) {
            uint key = keys[i];
            uint value = mappingTarget[key];
            if (value != 0) {
                DictNode memory node = _getOrAddDictNode(linkedList, key);
                node.value = value;
            }
        }
    }

    // same as importFromMapping but it doesn't check if the key exists before setting the value
    function createFromMapping(mapping(uint => uint) storage mappingTarget, uint[] memory keys) internal view returns (MemDict ptr) {
        ptr = create();
        LinkedList memory linkedList = getLinkList(ptr);
        for (uint i = 0; i < keys.length; i++) {
            uint key = keys[i];
            uint value = mappingTarget[key];
            if (value != 0) {
                DictNode memory node = _addKey(linkedList, key);
                node.value = value;
            }
        }
    }



    // internal functions *****************************************************

    function _getOrAddDictNode(LinkedList memory linkedList, uint256 key) private pure returns (DictNode memory) {
        (bool success, DictNode memory node) = _getNodeByKey(linkedList.head, key);
        if (success) {
            return node;
        } else {
            return _addKey(linkedList, key);
        }
    }


    /// @notice does not check for duplicate keys
    function _addKey(LinkedList memory linkedList, uint256 key) private pure returns (DictNode memory newNode) {
        // create new node
        newNode.key = key;
        bytes32 newNodePtr;
        assembly {
            newNodePtr := newNode
        }

        // attach new node to tail
        DictNode memory tail = linkedList.tail;
        tail.next = newNodePtr;

        // update linked list tail
        linkedList.tail = newNode;

        // update linked list length
        unchecked {
            ++linkedList.keysLength;
        }
    }

    /// @dev does not revert on key error
    /// @param success true if key exists
    /// @param node the node with the given key if found, else head
    function _getNodeByKey(DictNode memory head, uint256 key)
        internal
        pure
        returns (bool success, DictNode memory node)
    {
        node = head;

        while (node.next != 0x0) {
            assembly {
                node := mload(node) // node = node.next
            }
            if (node.key == key) {
                return (true, node);
            }
        }
        return (false, node);
    }
}
