
// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./TimeUnit.sol";
import "./CommitReveal.sol"; 


    

contract RPS {
    uint public numPlayer = 0;
    uint public reward = 0;
    mapping (address => uint) private player_choice; // 00 - Rock, 01 - Paper , 02 - Scissors, 03 - lizard, 04 - spork
    mapping(address => bool) public player_not_played;
    address[] public players;
    uint public numInput = 0;

      
    // สร้างตัวแปรที่มี โดยใช้ Constructor จาก TimeUnit กำหนดคุณสมบัติทั้งหมดของตัวแปร
    TimeUnit private timeUnit = new TimeUnit();

    CommitReveal private commitReveal = new CommitReveal();

    //ฟังก์ชั่นที่ใช้มาทดสอบการนับเวลา (ไม่จำเป็นต้องมี)
    function elapsedSeconds() public view returns (uint256) { 
        return timeUnit.elapsedSeconds();
    } 

    //ฟังก์ชั่นเพิ่มผู้เล่น
    function addPlayer() public payable {
        require(numPlayer < 2);
        require(msg.sender == 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4 ||
                msg.sender == 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2 ||
                msg.sender == 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db || 
                msg.sender == 0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB);
        if (numPlayer > 0) {
            require(msg.sender != players[0]);
        }
        require(msg.value == 1 ether);
        reward += msg.value;
        player_not_played[msg.sender] = true;
        players.push(msg.sender);
        numPlayer++;
        timeUnit.setStartTime();
    }

    function getHash(bytes32 data) public pure returns(bytes32){
    return keccak256(abi.encodePacked(data));
    }

    //ฟังก์ชั่นถอนเงินกรณีมีผู้เล่นคนเดียวและไม่มีคนอื่นเล้่นด้วย
    function returnRewardForFirstPlayer() public payable {
        require(block.timestamp - timeUnit.startTime() >= 30 && 
                numPlayer != 2 && 
                msg.sender == players[0]);
        address payable accountFirstPlayer = payable(players[0]);
        accountFirstPlayer.transfer(reward);
        resetGame();
    }

    function commit (bytes32 commitInput) public {
        require(player_not_played[msg.sender] == true);
        commitReveal.commit(commitInput, msg.sender);   
    }

    function reveal (bytes32 revealInput) public {
        require(player_not_played[msg.sender] == true);
        commitReveal.reveal(revealInput, msg.sender);
        bytes1 revealValue = commitReveal.getLastByte(revealInput);
        input(revealValue);
        player_not_played[msg.sender] = false;
    }

    //ฟังก์ชั้นรับค่า Choice จากผู้เล่น
    function input(bytes1 value) private  {
        uint choice;
        if (value == 0x00) {
            choice = 0; 
        } else if (value == 0x01){
            choice = 1;
        } else if (value == 0x02){
            choice = 2;
        } else if (value == 0x03){
            choice = 3;
        } else if (value == 0x04){
            choice = 4;
        } else {
            choice = 999;
        }
        require(numPlayer == 2);
        require(player_not_played[msg.sender] == true);
        require(choice == 0 || choice == 1 || choice == 2 || choice == 3 || choice == 4);
        player_choice[msg.sender] = choice;
        numInput++; //บ่งบอกว่า มีคนใส่ Input ไปแล้ว 1 คน
        timeUnit.setStartTime();
        if (numInput == 2) {
            _checkWinnerAndPay();
        }
    }

    //ฟังก์ชั่นตัดสินการแพ้ชนะของการเป่ายิ้งฉุบ
    function _checkWinnerAndPay() private {
        uint p0Choice = player_choice[players[0]];
        uint p1Choice = player_choice[players[1]];
        address payable account0 = payable(players[0]);
        address payable account1 = payable(players[1]);
        if ((p0Choice + 1) % 3 == p1Choice || 
            (p0Choice == 3 && p1Choice == 0) ||
            (p0Choice == 4 && p1Choice == 3) ||
            (p0Choice == 2 && p1Choice == 4) ||
            (p0Choice == 3 && p1Choice == 2) ||
            (p0Choice == 1 && p1Choice == 3) ||
            (p0Choice == 0 && p1Choice == 4) ||
            (p0Choice == 1 && p1Choice == 4)) {
            // to pay player[1]
            account1.transfer(reward);
        }
        else if ((p1Choice + 1) % 3 == p0Choice ||
            (p1Choice == 3 && p0Choice == 0) ||
            (p1Choice == 4 && p0Choice == 3) ||
            (p1Choice == 2 && p0Choice == 4) ||
            (p1Choice == 3 && p0Choice == 2) ||
            (p1Choice == 1 && p0Choice == 3) ||
            (p1Choice == 0 && p0Choice == 4) ||
            (p1Choice == 1 && p0Choice == 4)) {
            // to pay player[0]
            account0.transfer(reward); 
        }
        else {
            // to split reward
            account0.transfer(reward / 2);
            account1.transfer(reward / 2);
        }
        resetGame();
    }

    //ฟังก์ชั่นคืนเงินให้ทั้งสองฝ่าย กรณีผู้เล่นอีกฝ่ายไม่ยอมเล่น (ผู้เล่นที่เล่นไปแล้ว Call ได้เท่านั้น)
    function returnRewardPlayerWaitingForChoice() public payable {
        require(block.timestamp - timeUnit.startTime() >= 30 && 
                numPlayer == 2 && 
                player_not_played[msg.sender] == false &&
                numInput == 1);
        address payable accountWaitForPlaying0 = payable(players[0]);
        address payable accountWaitForPlaying1 = payable(players[1]);
        accountWaitForPlaying0.transfer(reward / 2);
        accountWaitForPlaying1.transfer(reward / 2);
        resetGame();
    }

    //ฟังก์ชั่นเริ่มเกมใหม่หลังจบตานั้นๆ
    function resetGame() private {
        numPlayer = 0;
        reward = 0;
        numInput = 0;
        delete players;
        commitReveal.restartGame();
    }
}