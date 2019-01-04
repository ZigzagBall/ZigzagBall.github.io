pragma solidity ^0.4.23;

import "./SafeMath.sol";
import "./Ownable.sol";

//
contract ZigZag is Ownable {
	using SafeMath for uint;

	struct PlaceBet{
		uint8 winProbability;//probability of winning 1% -> 100%
		uint8 prizeRate;//ex: x0, x2, x5....
	}

	struct Bet{
		address player;
		uint bet_amount;
		uint8 result_place;
		uint win_amount; 
		uint time;
	}

    	mapping(uint8 => PlaceBet) public placeBets;
    	mapping(uint => Bet) public bets;

	uint private randomFactor;
	uint private totalUserBets;
	uint private totalUserWin;

	uint public currentBet;
	uint public gameMaxBet;
	uint public gameMinBet;

	event UserBet(address indexed player, uint bet_amount, uint8 result_place, uint win_amount, uint id);

	//contract constructor
	constructor() public {
		randomFactor = now.mod(10);
		gameMaxBet = 2000000000;//2000 TRX
		gameMinBet = 1000000;//1 TRX
		placeBets[1] = PlaceBet({winProbability: 24, prizeRate: 0});
		placeBets[2] = PlaceBet({winProbability: 15, prizeRate: 2});//x2
		placeBets[3] = PlaceBet({winProbability: 22, prizeRate: 0});
		placeBets[4] = PlaceBet({winProbability: 12, prizeRate: 3});//x3
		placeBets[5] = PlaceBet({winProbability: 22, prizeRate: 0});
		placeBets[6] = PlaceBet({winProbability: 5, prizeRate: 5});//x5
		// 6 placeBet => total winProbability = 100 (100%)
		//1: 0->23, 2: 24->38, 3: 39->60, 4: 61->72, 5: 73->94, 6: 95->99
	}

	function setPlaceBets(
		uint8 win1, uint8 prize1, 
		uint8 win2, uint8 prize2, 
		uint8 win3, uint8 prize3, 
		uint8 win4, uint8 prize4,
		uint8 win5, uint8 prize5,
		uint8 win6, uint8 prize6
	) public onlyOwner {
	    	if (win1==0 || win2==0 || win3==0 || win4==0 || win5==0 || win6==0) revert("error winProbability.");
	    	if (prize1>20 || prize2>20 || prize3>20 || prize4>20 || prize5>20 || prize6>20) revert("error prizeRate.");
	    	if ((win2 + win3 + win4 + win5 + win6 + win1) != 100) revert("error total winProbability != 100.");
		placeBets[1].winProbability = win1;
		placeBets[1].prizeRate = prize1;
		placeBets[2].winProbability = win2;
		placeBets[2].prizeRate = prize2;
		placeBets[3].winProbability = win3;
		placeBets[3].prizeRate = prize3;
		placeBets[4].winProbability = win4;
		placeBets[4].prizeRate = prize4;
		placeBets[5].winProbability = win5;
		placeBets[5].prizeRate = prize5;
		placeBets[6].winProbability = win6;
		placeBets[6].prizeRate = prize6;
	}


	function getMaxPrizeRate() public view returns(uint8) {
		uint8 maxRate = 0;
		for(uint8 i = 1; i <= 6; i++){
			if(placeBets[i].prizeRate > maxRate)maxRate = placeBets[i].prizeRate;
		}
        	return maxRate;
	}

	//
	function userBet(uint amount) public payable {
		if (msg.value < amount) revert("You not enough TRX provided.");
		if (amount < gameMinBet) revert("You place the bet amount smaller than the minimum amount.");
		if (amount > gameMaxBet) revert("You set the bet amount greater than the maximum amount.");
		if (amount.mul(getMaxPrizeRate()) > address(this).balance) revert("This contract not enough TRX provided.");
        	totalUserBets = totalUserBets.add(amount);
		uint random_number = random_uint();
		randomFactor = randomFactor.add(random_number.mod(10).add(1));
		uint result_number = random_number.mod(100);
		//
		uint8 winMaxNumber_1 = placeBets[1].winProbability;
		uint8 winMaxNumber_2 = placeBets[2].winProbability + winMaxNumber_1;
		uint8 winMaxNumber_3 = placeBets[3].winProbability + winMaxNumber_2;
		uint8 winMaxNumber_4 = placeBets[4].winProbability + winMaxNumber_3;
		uint8 winMaxNumber_5 = placeBets[5].winProbability + winMaxNumber_4;
		//uint8 winMaxNumber_6 = placeBets[6].winProbability.add(winMaxNumber_5);//100
		uint8 result_place = 0;
		if(result_number < winMaxNumber_1-1){//0 to winMaxNumber_1-1
		    result_place = 1;
		} else if(result_number < winMaxNumber_2-1){
		    result_place = 2;
		} else if(result_number < winMaxNumber_3-1){
		    result_place = 3;
		} else if(result_number < winMaxNumber_4-1){
		    result_place = 4;
		} else if(result_number < winMaxNumber_5-1){
		    result_place = 5;
		} else{//winMaxNumber_5 to 99
		    result_place = 6;
		}

		uint win_amount = 0;
		if(placeBets[result_place].prizeRate > 0){
			win_amount = amount.mul(placeBets[result_place].prizeRate);
			totalUserWin = totalUserWin.add(win_amount);
			msg.sender.transfer(win_amount);
		}
		bets[currentBet] = Bet(
		{
			player: msg.sender,
			bet_amount: amount,
			result_place: result_place,
			win_amount: win_amount,
			time: now
		});
        	uint id = currentBet;
		emit UserBet(msg.sender, amount, result_place, win_amount, id);
		currentBet++;
	}

	function getRandomFactor() public onlyOwner view returns(uint) {
        	return randomFactor;
	}

	function setRandomFactor(uint num) public onlyOwner {
        	randomFactor = num;
	}

	function getTotalUserBets() public onlyOwner view returns(uint) {
        	return totalUserBets;
	}

	function getTotalUserWin() public onlyOwner view returns(uint) {
        	return totalUserWin;
	}


	function setGameMaxBet(uint num) public onlyOwner {
        	gameMaxBet = num;
	}

	function setGameMinBet(uint num) public onlyOwner {
        	gameMinBet = num;
	}
	//random
	function random_uint() private view returns (uint256) {
		return uint256(blockhash(block.number-1-block.timestamp.mod(100))) + randomFactor;
	}

	//withdraw
	function withdraw(uint amount) public onlyOwner {
		require(amount <= address(this).balance);
		owner().transfer(amount);
	}

    	function() public payable{}
}
