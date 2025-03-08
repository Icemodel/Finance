// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

contract CommitReveal {

  uint8 public max = 100;

  bytes32 public data_input;

  bytes[] public dynamicData;

  struct Commit {
    bytes32 commit;
    uint64 block;
    bool revealed;
  }

  mapping (address => Commit) public commits;

  function commit(bytes32 dataHash , address player) public {
    commits[player].commit = dataHash;
    commits[player].block = uint64(block.number);
    commits[player].revealed = false;
    emit CommitHash(player,commits[player].commit,commits[player].block);
  }
  event CommitHash(address sender, bytes32 dataHash, uint64 block);

  function reveal(bytes32 revealHash, address player) public {
    //make sure it hasn't been revealed yet and set it to revealed
    require(commits[player].revealed==false,"CommitReveal::reveal: Already revealed");
    commits[player].revealed=true;
    //require that they can produce the committed hash
    require(getHash(revealHash)==commits[player].commit,"CommitReveal::reveal: Revealed hash does not match commit");
    //require that the block number is greater than the original block
    require(uint64(block.number)>commits[player].block,"CommitReveal::reveal: Reveal and commit happened on the same block");
    //require that no more than 250 blocks have passed
    require(uint64(block.number)<=commits[player].block+250,"CommitReveal::reveal: Revealed too late");
    //get the hash of the block that happened after they committed
    bytes32 blockHash = blockhash(commits[player].block);
    //hash that with their reveal that so miner shouldn't know and mod it with some max number you want
    uint random = uint(keccak256(abi.encodePacked(blockHash,revealHash)))%max;
    emit RevealHash(player,revealHash,random);
    
  }
  event RevealHash(address sender, bytes32 revealHash, uint random);

  function getHash(bytes32 data) public pure returns(bytes32){
    return keccak256(abi.encodePacked(data));
  }

  function getLastByte(bytes32 input) public pure returns (bytes1) {
    return bytes1(input[31]); 
  }

  function restartGame() public {
    delete commits[0x5B38Da6a701c568545dCfcB03FcB875f56beddC4]; 
    delete commits[0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2]; 
    delete commits[0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db]; 
    delete commits[0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB];  
  }
}
