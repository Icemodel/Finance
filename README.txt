หมายเหต*
จำเป็นต้องใช้ Algorithm สุ่มค่า Salt ผสมกับ Choice ในไฟล์Python ของอาจาร์ย
และ Choice ที่เลือกได้ จะมี 00 หิน 01 กระดาษ 02 กรรไกร 03 กิ้งก่า 04 Spork 
จากนั้นจึงนำค่าที่สุ่มได้มา ไปใช้กับฟังก์ชั่น GetHash และจึงค่อยนำไป Commit

//ตัวแปร Global ทั้งหมดที่ใช้
uint public numPlayer = 0;
    uint public reward = 0;
    mapping (address => uint) private player_choice; // 00 - Rock, 01 - Paper , 02 - Scissors, 03 - lizard, 04 - spork
    mapping(address => bool) public player_not_played;
    address[] public players;
    uint public numInput = 0;

//สร้างตัวแปรที่มี โดยใช้ Constructor จาก TimeUnit กำหนดคุณสมบัติทั้งหมดของตัวแปร
TimeUnit private timeUnit = new TimeUnit();

CommitReveal private commitReveal = new CommitReveal();

//ฟังก์ชั่นเพิ่มผู้เล่น มี require(msg.sender == .....) 
function addPlayer() public payable {
        require(numPlayer < 2); ป้องกันไม่ให้ผู้เล่นมีมากกว่า 2 คนในเกม
        require(msg.sender == 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4 || ทั้ง 4 Address เพื่อเปิดให้เฉพาะผู้เล่น 4คนที่มี Address ดังนี้เข้ามาเล่นได้เท่านั้น
                msg.sender == 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2 ||
                msg.sender == 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db || 
                msg.sender == 0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB);
        if (numPlayer > 0) {
            require(msg.sender != players[0]); ตรวจดูว่าเป็นผู้เล่นคนเดิมรึป่าวที่เข้ามาเล่น 
        }
        require(msg.value == 1 ether); บังคับให้ผู้เล่นต้องลงเงิน 1 ETH
        reward += msg.value; 
        player_not_played[msg.sender] = true; ให้ผู้เล่นที่เข้ามา มีสถานะ "ยังไม่ได้เล่นเป่ายิ้งฉุบ"
        players.push(msg.sender); เพิ่ม Address ของผู้เล่นคนนั้นเข้าไปใน Array
        numPlayer++;
        timeUnit.setStartTime(); เริ่มจับเวลา
    }

//ฟังก์ชั่นที่ใช้แปลงค่าที่สุ่มมาจาก Python
function getHash(bytes32 data) public pure returns(bytes32){
    return keccak256(abi.encodePacked(data));
    }

//ฟังก์ชั่นถอนเงินกรณีมีผู้เล่นคนเดียวและไม่มีคนอื่นเล้่นด้วย 
    function returnRewardForFirstPlayer() public payable {
        require(block.timestamp - timeUnit.startTime() >= 30 && จับเวลาและต้องมีผู้เล่นเพียงแค่ตนเดียว				
                numPlayer != 2 && และต้องให้ผู้เล่นที่กดเป็นผู้เล่นคนแรกด้วย
                msg.sender == players[0]); และต้องให้ผู้เล่นคนแรกที่เข้ามากดได้เท่านั้น ป้องกันกรณีมีผู้เล่นคนที่ 2 เข้ามาแล้วแต่ฉวยโอกาสกดปุ่มยกเลิกเกม 
        address payable accountFirstPlayer = payable(players[0]);
        accountFirstPlayer.transfer(reward); ให้เงินคืนผู้เล่นคนแรก
        resetGame(); รีสตาร์ทเกมใหม่
    }

//ฟังก์ชั่น Commit 
function commit (bytes32 commitInput) public {
        require(player_not_played[msg.sender] == true); ป้องกันไม่ให้ผู้เล่น ที่เล่นไปแล้วกดซ้ำ
        commitReveal.commit(commitInput, msg.sender);   ทำการเรียกฟังก์ชั่น Commit ส่งทั้ง Choice ที่จะตอบ และส่ง Address ของผู้เล่นที่กดไปด้วย
    }

//
function reveal (bytes32 revealInput) public {
        require(player_not_played[msg.sender] == true); ป้องกันไม่ให้ผู้เล่น ที่กดเล่นไปแล้วกดซ้ำ
        commitReveal.reveal(revealInput, msg.sender); ทำการเรียกฟังก์ชั่น Reveal ส่งทั้ง Byteที่ใช้ไปแปลงและส่งในCommit และส่ง Address ของผู้เล่นที่กดไปด้วย
        bytes1 revealValue = commitReveal.getLastByte(revealInput);  คัดเอาแค่ Byte สุดท้ายมาจากความยาวทั้ง 32 Byte 
        input(revealValue); ส่งค่า Byte สุดท้าย ไปในฟังก์ชั่น Input เพื่อนำไปแปลงเป็นจากBytes1 เป็น Uint
        player_not_played[msg.sender] = false; หากผู้เล่นกดเล่นเป็นครั้งแรก จะปรับสถานะผู้เล่นคนนั้นให้เป็น "เล่นเป่ายิ้งฉุบไปแล้ว"
    }

//ฟังก์ชั้นรับค่า Choice จากผู้เล่น
    function input(bytes1 value) private  { ซ่อน Choiceด้วยการปรับเป็น Private
        uint choice;
        if (value == 0x00) { ส่วนของ if จะรับค่า byte ตัวสุดท้ายมา แล้วมาพิจารณาแปลง Choice ของผู้เล่นจาก Bytes 32 เป็น uint
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
            choice = 999; หาก Choice ไม่ตรงจะได้ค่า เป็น 999 และจะไปติดไม่ผ่าน Require ด้านล่าง
        }
        require(numPlayer == 2); ต้องมีผู้เล่น 2 คน ป้องกันการกดปุ่มเล่น หากมีแค่ผู้เล่นคนเดียว
        require(player_not_played[msg.sender] == true); ผู้เล่นที่กดต้องไม่ได้เล่นมาก่อน
        require(choice == 0 || choice == 1 || choice == 2 || choice == 3 || choice == 4); 
        player_choice[msg.sender] = choice; เก็บค่า Choice ไว้เพื่อตัดสินแพ้ชนะ
        numInput++; บ่งบอกว่า มีคนใส่ Input ไปแล้ว 1 คน เมื่อมีการกด Commit
        timeUnit.setStartTime(); เริ่มนับเวลาใหม่ เมื่อมีผู้เล่นเลือก Choice แล้ว (เพื่อนับเวลาถอยหลังใหม่ เวลามีผู้เล่น2คนแล้วมี 1 คนไม่ยอมกดเล่น)
        if (numInput == 2) {
            _checkWinnerAndPay(); ถ้าคนเล่น ครบ 2 คนแล้วจะตัดสินแพ้ชนะ
        }
    }

//ฟังก์ชั่นตัดสินการแพ้ชนะของการเป่ายิ้งฉุบ
    function _checkWinnerAndPay() private {
        uint p0Choice = player_choice[players[0]];  นำ Choice ของผูเล่นแต่ละคนมาเก็บเป็นตัวแปร
        uint p1Choice = player_choice[players[1]];
        address payable account0 = payable(players[0]); กำหนดสร้างตัวแปรที๋โอนเงินให้ผูเล่นแต่ละคนได้
        address payable account1 = payable(players[1]);
        if ((p0Choice + 1) % 3 == p1Choice || กฎกติกาทั่วไปของเป่ายิ้งฉุบ
            (p0Choice == 3 && p1Choice == 0) || หินชนะกิ้งก่า
            (p0Choice == 4 && p1Choice == 3) || กิ้งก่าชนะ Spork
            (p0Choice == 2 && p1Choice == 4) || Spork ชนะกระดาษ
            (p0Choice == 3 && p1Choice == 2) || กระดาษชนะกรรไกร
            (p0Choice == 1 && p1Choice == 3) || กิ้งก่าชนะกระดาษ
            (p0Choice == 0 && p1Choice == 4) || Spork ชนะหิน
            (p0Choice == 1 && p1Choice == 4)) { Spork ชนะกระดาษ
            // to pay player[1]
            account1.transfer(reward); เคสของผู้เล่นคนที่ 2 ชนะ จะได้เงินไป
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
            account0.transfer(reward); เคสของผู้เล่นคนที่ 2 ชนะ จะได้เงินไป
        }
        else {
            // to split reward 
            account0.transfer(reward / 2); แบ่งรางวัลหากเสมอกัน
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

//ฟังก์ชั่นคืนเงินให้ทั้งสองฝ่าย กรณีผู้เล่นอีกฝ่ายไม่ยอมเล่น (ผู้เล่นที่เล่นไปแล้ว Call ได้เท่านั้น)
    function returnRewardPlayerWaitingForChoice() public payable {
        require(block.timestamp - timeUnit.startTime() >= 30 &&  เวลาต้องนานกว่า 30 วินาที
                numPlayer == 2 &&  ต้องมีผู้เล่น 2 คนในเกมแล้ว
                player_not_played[msg.sender] == false && และผู้เล่นคนที่เล่นไปแล้ว แต่รออีกตนอยู่สามารถกดได้เพียงคนเดียว กันอีกคนมากดเพื่อตั้งใจยกเลิกเกม
                numInput == 1); ต้องมีคนเล่นไปแล้ว 1 คน ป้องกันเริ่มมาตาแรกแล้วกดยกเลิกเกมได้เลย
        address payable accountWaitForPlaying0 = payable(players[0]); สร้างตัวแปรไว้คืนเงินให้ผู้เล่นทั้ง 2
        address payable accountWaitForPlaying1 = payable(players[1]);
        accountWaitForPlaying0.transfer(reward / 2); คืนเงินให้ผู้เล่นทั้ง 2
        accountWaitForPlaying1.transfer(reward / 2);
        resetGame(); รีสตารทเกม
    }

//ฟังก์ชั่นเริ่มเกมใหม่หลังจบตานั้นๆ
    function resetGame() private {
        numPlayer = 0;
        reward = 0;
        numInput = 0;
        delete players;
        commitReveal.restartGame();
    }