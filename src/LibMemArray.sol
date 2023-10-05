// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;


/**

   Example: MemArray myArray = [0x123, 0x456]

  ┌───────────────────────────────────────┬───────────────────────┬───────────────────────────┬────────────────────────┬───────────────────────┐
  │MemArray myArray                      │myArray                │ x-x-x-x-x-x-x-x-x-x-x-x-  │myArray[0] = 0x123      │myArray[1] = 0x456     │
  │LINKED LIST                            │NODE - HEAD            │ MEMORY USED BY SOMETHING  │NODE - CUTOFF           │NODE - TAIL            │
  │                                       │contains no value      │ ELSE - UNRELATED TO THIS  │                        │tail has no next       │
  ├─────────────┬─────────────┬───────────┼─────────────┬─────────┼─────────────┬─────────────┼─────────────┬──────────┼───────────┬───────────┤
  │0x080        │0x0a0        │0x0c0      │0x0e0        │0x100    │0x120        │0x140        │0x160        │0x180     │0x1a0      │  0x1c0    │
  │             │             │           │             │         │             │             │             │          │           │           │
  │ length:     │ head:       │ tail:     │ next:       │ value:  │             │             │ next:       │ value:   │ next:     │   value:  │
  │             │             │           │             │         │             │             │             │          │           │           │
  │      2      │     0x0e0   │    0x1a0  │   0x160     │   0x00  │             │             │   0x1a0     │   0x123  │   0x00    │     0x456 │
  └─────────────┴──────┬──────┴─────┬─────┴─────────┬───┴─────────┴─────────────┴─────────────┴─────────┬───┴──────────┴───────────┴───────────┘
                       │            │        ▲      │                                           ▲  ▲    │                  ▲  ▲
                       │            │        │      │                                           │  │    │                  │  │
                       └────────────┼────────┘      └───────────────────────────────────────────┘  │    │                  │  │
                                    │                                                              │    │                  │  │
                                    │                                                              │    │                  │  │
                                    ├──────────────────────────────────────────────────────────────┘    └──────────────────┘  │
                                    │                                                                                         │
                                    │                                                                                         │
                                    └─────────────────────────────────────────────────────────────────────────────────────────┘                 */


type MemArray is bytes32; // this is a ptr

/// @notice An optimized, in-memory, memory-safe, dynamically resizing array.
/// @author @devtooligan
library LibMemArray {
    struct Node {
        bytes32 next;
        uint256 value;
    }

    struct LinkedList {
        uint256 size;
        Node head; // memloc of head node
        Node tail; // memloc of tail node
    }

    function create() internal pure returns (MemArray newArray) {
        // linked lists always have a head node which does not contain a value
        // the tail, on the other hand, represents the last node (or head if size == 0)
        Node memory head;
        LinkedList memory list = LinkedList({size: 0, head: head, tail: head});
        assembly {
            newArray := list
        }
    }

    // @dev This operation is O(1) because we have a tail pointer
    function push(MemArray ptr, uint256 value) internal pure returns (MemArray) {
        // get linked list
        LinkedList memory linkedList;
        assembly {
            linkedList := ptr
        }

        // create new node
        Node memory newNode = Node({next: 0, value: value});
        bytes32 newNodePtr;
        assembly {
            newNodePtr := newNode
        }

        // attach new node to tail
        Node memory tail = linkedList.tail;
        tail.next = newNodePtr;

        // update length
        unchecked {
            ++linkedList.size;
        }

        // update tail pointer
        linkedList.tail = newNode;

        return ptr;
    }

    // @dev This operation is O(n) because we have to traverse the list to find the second to last node
    function pop(MemArray ptr) internal pure returns (uint256 value) {
        // get linked list
        LinkedList memory linkedList;
        assembly {
            linkedList := ptr
        }
        require(linkedList.size > 0, "list is empty");

        // detach tail
        Node memory tail = linkedList.tail;
        if (linkedList.size == 1) {
            // if there is only one node, zero out head.next
            linkedList.head.next = 0x0;
            linkedList.tail = linkedList.head;
        } else {
            // else get the second to last node and zero out its .next
            Node memory cutoff = _getNode(linkedList.head, linkedList.size - 2);
            cutoff.next = 0x0;
            linkedList.tail = cutoff;
        }

        // retain detached tail value for return
        value = tail.value;

        // update linked list length
        unchecked {
            --linkedList.size;
        }
    }

    /// @dev This operation is O(n) because we have to traverse the list to find the node
    function set(MemArray ptr, uint256 index, uint256 value) internal pure returns (MemArray) {
        // get linked list
        LinkedList memory linkedList;
        assembly {
            linkedList := ptr
        }
        require(linkedList.size > index, "out of bounds");

        // get node
        Node memory node = _getNode(linkedList.head, index);

        // set node
        node.value = value;

        return ptr;
    }

    /// @dev This operation is O(n) because we have to traverse the list to find the node
    function get(MemArray head, uint256 index) internal pure returns (uint256) {
        // get linked list
        LinkedList memory linkedList;
        assembly {
            linkedList := head
        }
        require(linkedList.size > index, "out of bounds");

        // get node
        Node memory node = _getNode(linkedList.head, index);

        return node.value;
    }

    function size(MemArray ptr) internal pure returns (uint256) {
        // get linked list
        LinkedList memory linkedList;
        assembly {
            linkedList := ptr
        }
        return linkedList.size;
    }

    function toArray(MemArray head) internal pure returns (uint256[] memory arr) {
        // get linked list
        LinkedList memory linkedList;
        assembly {
            linkedList := head
        }

        // create array
        arr = new uint256[](linkedList.size);

        // iterate through linked list and populate the legacy array
        bytes32 zeroNodePtr = linkedList.head.next;
        Node memory node;
        assembly {
            node := zeroNodePtr
        }
        for (uint256 i = 0; i < linkedList.size; i++) {
            arr[i] = node.value;
            assembly {
                node := mload(node) // node = node.next
            }
        }
    }

    function fromArray(uint256[] memory arr) internal pure returns (MemArray newArray) {
        // create linked list
        newArray = create();

        // iterate through array
        for (uint256 i = 0; i < arr.length; i++) {
            push(newArray, arr[i]); // this could be optimized a lot
        }
    }

    // internal functions *****************************************************

    function _getNode(Node memory head, uint256 index) internal pure returns (Node memory node) {
        node = head;
        require(head.next != 0x0, "empty list");
        assembly {
            node := mload(node) // node = node.next
            let counter := 0x0
            for {} iszero(eq(counter, index)) {} {
                // while counter != index
                if eq(node, 0x0) {
                    // if node.next == 0
                    revert(0, 0) // revert TODO: pretty error
                }
                node := mload(node) // node = node.next
                counter := add(counter, 0x1) // counter++
            }
        }
    }

    function _hasNode(Node memory head, uint256 index) internal pure returns (bool success, Node memory node) {
        node = head;
        if (head.next == 0x0) return (false, head);
        bool finished = false;
        assembly {
            node := mload(node) // node = node.next
            let counter := 0x0
            for {} iszero(eq(counter, index)) {} {
                // while counter != index
                if eq(node, 0x0) {
                    finished := 1
                    break

                }
                node := mload(node) // node = node.next
                counter := add(counter, 0x1) // counter++
            }
        }
    }

    function _getNodePtr(Node memory head, uint256 index) internal pure returns (bytes32 nodePtr) {
        require(head.next != 0x0, "empty list");
        assembly {
            nodePtr := mload(head) // node = node.next
            let counter := 0x0
            for {} iszero(eq(counter, index)) {} {
                // while counter != index
                if eq(nodePtr, 0x0) {
                    // if node.next == 0
                    revert(0, 0) // revert TODO: pretty error
                }
                nodePtr := mload(nodePtr) // node = node.next
                counter := add(counter, 0x1) // counter++
            }
        }
    }
}
