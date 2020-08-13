pragma solidity ^0.4.3;

contract RPC {
    // a mapping that will store possible outcomes of the game 
    mapping (string => mapping(string => int)) winDec;
    // These are the addresses of the two players
    address player1;
    address player2;
    // These variable store the hashes of each of the player choices
    bytes32 player1ChoiceHash;
    bytes32 player2ChoiceHash;
    // This variable store the choices made by the players (but are only revealed after both players have submitted)
    string public player1Choice;
    string public player2Choice;
    // Stores the total balance of the contract 
    uint balance;
    // Stores the amount of money bet by the first player 
    uint public amount; 
    // Stores the time of when the the first player revealed
    uint public revealTime;
    // stores the time when player 1 started the game
    uint startTime;
    
    
    constructor () public 
    {
        // Setting the possible outcomes
        // Format: winDec[player1's choice][player2's choice] = number of player that wins that match
        winDec["rock"]["rock"] = 0;
        winDec["rock"]["paper"] = 2;
        winDec["rock"]["scissors"] = 1;
        winDec["paper"]["rock"] = 1;
        winDec["paper"]["paper"] = 0;
        winDec["paper"]["scissors"] = 2;
        winDec["scissors"]["rock"] = 2;
        winDec["scissors"]["paper"] = 1;
        winDec["scissors"]["scissors"] = 0;
    }
    // resets the variables, and cannot be called by an external source
    function reset() private {
        player1Choice = "";
        player2Choice = "";
        player1 = 0;
        player2 = 0;
	    player1ChoiceHash = 0;
    	player2ChoiceHash = 0;
    }
    // function that's called when a new player invokes the contract with a payable
    function newPlayer() payable public
    {
        // sets a requirement that at least 1 ether must be a bet
        require(msg.value >= 1 ether);
        // if no players have joined, set current sender to player 1 and set the bet to amount of ether player1 sent
        if (player1 == 0) {
            player1 = msg.sender;
            amount = msg.value;
	    startTime = now;
	    balance = amount;
        }
        // if there is a player, but not a player2, and the current sender matches the bet, 
        // then set current sender to player2
        else if (player2 == 0 && amount == msg.value) {
            player2 = msg.sender;
	    balance = amount*2;
        }
        // If there already 2 players, refuse entry to any other person 
        else {
            revert("Sorry! There are already two players in the game");
        }
    }
    // Function that stores the hash of the player's choice and random key to "playerxChoiceHash"
    function hash(bytes32 hashF) public {
        if(msg.sender == player1 && player1ChoiceHash == 0) {
            player1ChoiceHash = hashF;
        }
        if(msg.sender == player2 && player2ChoiceHash == 0) {
            player2ChoiceHash = hashF; 
        }
    }
    // This function should be invoked by the players once both have submitted their hashes
    function reveal(string choice, string random) public
    {
        // checks if the sender is a player
        if(msg.sender == player1 || msg.sender == player2) {
            // checks if both players have submitted their choices
            if(player1ChoiceHash != 0 && player2ChoiceHash !=0) {
                // other player has 3 minutes to reveal after the player that revealed first
                if (bytes(player1Choice).length == 0 && bytes(player2Choice).length == 0)
    	        {
                    revealTime == now;
        	    }
                // if hash matches initial hash, meaning the player hasn't changed their initial submission, choice is stored (and revealed)
                if (msg.sender == player1 && keccak256(keccak256(choice) ^ keccak256(random)) == player1ChoiceHash)
    	        {
                    player1Choice = choice;
    	        }
                if (msg.sender == player2 && keccak256(keccak256(choice) ^ keccak256(random)) == player2ChoiceHash)
    	        {
                    player2Choice = choice;
                }
            }
            else 
            {
                revert("The other player hasn't submitted their choice yet!");
            }
        }
        else 
        {
            revert("Sorry! You're not a player thus are denied access.");
        }
        // Once both players reveal, this statement will call the "checkWinner()" function
        if (bytes(player1Choice).length != 0 && bytes(player2Choice).length != 0) 
        {
            checkWinner();
        }
    }   
    // This function checks who won the match and then transfers money accordingly
    // function was set private so it can't be accessed externally
    function checkWinner() private
    {
        // money will only be transfered if both players have revealed
        if (bytes(player1Choice).length != 0 && bytes(player2Choice).length != 0)
        {
            // if both revealed, then decide on winner
            int winner = winDec[player1Choice][player2Choice];
            if (winner == 1) 
            {
                player1.transfer(address(this).balance);
            }
            else if (winner == 2) 
            {
                 player2.transfer(address(this).balance);
            }
            // if there's a tie, split the money'
            else 
            {
                player1.transfer(address(this).balance/2);
                player2.transfer(address(this).balance/2);
            }

            // Resets players and choices for future games
           reset();
        }
        // if a player reveals after three minutes, then the first player automatically gets the ether
        else if (now > revealTime + 180)
        {
            // If time elapsed since revealTime has passed 3 minutes, winner is the one who revealed first
            if (bytes(player1Choice).length != 0)
                player1.transfer(address(this).balance);
            else if (bytes(player2Choice).length != 0)
                player2.transfer(address(this).balance);
        }
        
    }
    // this function serves to ensure that ether can be returned to player1 if no other player joins after 10 minutes
    // made public so player1 can call it when necessary
    function checkTime () public
    {
	    if (now > startTime + 10 minutes && player2ChoiceHash == 0) {
            player1.transfer(address(this).balance);
            reset();
        }
    }
    // this function returns the contract balance for reference
    function getContractBalance () public constant returns (uint a)
    {
        return address(this).balance;
    }
}

contract hashFHelper{
    // This is a contract for generating hashes of the choice and rand
    // choice: what the player chooses between rock paper scissors
    // rand: a random string that the player chooses
    string public  paper = "paper";
    string public rock = "rock";
    string public scissors = "scissors"; 
    modifier check_choice(string choice) {
    	// Checks if the choice a player made is a valid hand
        if (keccak256(choice) == keccak256(paper) ||  
            keccak256(choice) == keccak256(rock) || 
            keccak256(choice) == keccak256(scissors)) { _; } 
        else 
        {
            revert("choice must be either rock, paper, or scissors");
        }
    } 
    // hashes the choice and rand sent after checking the choice is valid
    function hash(string choice, string rand) public check_choice(choice) returns(bytes32){
        bytes32 result = keccak256(keccak256(choice) ^ keccak256(rand));
        return result;
    }
}