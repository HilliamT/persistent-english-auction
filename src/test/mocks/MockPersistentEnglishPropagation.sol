// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {PersistentEnglishPropagation} from "../../PersistentEnglishPropagation.sol";

contract MockPersistentEnglishPropagation is PersistentEnglishPropagation {
    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    constructor(
        string memory _name,
        string memory _symbol,
        uint32 _totalToSell,
        uint32 _timeBetweenSells
    )
        PersistentEnglishPropagation(
            _name,
            _symbol,
            _totalToSell,
            _timeBetweenSells
        )
    {}

    /*//////////////////////////////////////////////////////////////
                             PURE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function tokenURI(uint256)
        public
        pure
        virtual
        override
        returns (string memory)
    {}
}
