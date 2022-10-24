// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }
}

/*
 * Developed by Spaar Games
 *
 *     spaar-games.com
 */

contract LegendaryCarWash {
    using SafeMath for uint256;

    address payable private devs;
    uint256 private devFeeVal = 4;
    uint256 private refFeeVal = 3;
    bool private initializeContract;
    uint256 public totalCarWash;
    uint256 public totalPlayers;
    uint256 public totalBnbDeposited;

    AggregatorV3Interface internal bnbPrice;

   
    event random_security_event(uint randomNumber, bool rob);

    struct User {
        uint256 balance;
        uint256 harvestDay;
        address referred;
        uint256 refsNumber;
        uint256 timestamp;        
        bool harvest;
        bool security;
        uint carwashes;
        uint256 carwashId;
        uint256 levelCarwash;        
    }

    mapping(address => User) public carwashMap;
    
    modifier onlyOwner(address _adr) {
        require(_adr == devs, "Only the owner can execute this function.");
        _;
    }
    
    constructor() {
        devs = payable(msg.sender);
        initializeContract = false;
        bnbPrice = AggregatorV3Interface(
            0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526
            // 0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE --> Mainnet
        );
    }

    function initialized(bool _initializeContract) external onlyOwner(msg.sender){
        if (_initializeContract) { initializeContract = true; }
        else { initializeContract = false; }
    }

    function addMoney(address _ref) public payable {
        require(initializeContract, "The contract is currently paused.");
        if (carwashMap[msg.sender].timestamp == 0) {
            _ref = carwashMap[_ref].timestamp == 0 ? devs : _ref;
            carwashMap[_ref].refsNumber++;
            carwashMap[msg.sender].referred = _ref;
            carwashMap[msg.sender].timestamp = block.timestamp;
            carwashMap[msg.sender].harvest = false;
            totalPlayers++;
        }
        totalBnbDeposited += msg.value;
        carwashMap[msg.sender].balance += msg.value;
        _ref = carwashMap[msg.sender].referred;
        carwashMap[_ref].balance += refFee(msg.value);
        payable(devs).transfer(devFee(msg.value));
    }

    function recoverMoney() public {
        require(initializeContract, "The contract is currently paused.");
        dataRecovery(msg.sender);
        if(carwashMap[msg.sender].harvest){
            carwashMap[msg.sender].balance += carwashMap[msg.sender].harvestDay;
            carwashMap[msg.sender].harvest = false;
        }        
        carwashMap[msg.sender].security = false;
    }

    function withdrawMoney() public {
        require(initializeContract, "The contract is currently paused.");        
        uint256 bnbContract = address(this).balance;
        payable(msg.sender).transfer(
            bnbContract < carwashMap[msg.sender].balance
                ? bnbContract
                : carwashMap[msg.sender].balance
        );
        carwashMap[msg.sender].balance = 0;
    }

    function buyCarWash() public {
        require(initializeContract, "The contract is currently paused.");
        dataRecovery(msg.sender);        
        checkLevels(msg.sender);
        carwashMap[msg.sender].carwashes++;        
        carwashMap[msg.sender].balance -= carwashPrice(carwashMap[msg.sender].carwashId,carwashMap[msg.sender].levelCarwash);
        carwashMap[msg.sender].harvestDay += harvestAmount(carwashMap[msg.sender].carwashId,carwashMap[msg.sender].levelCarwash);
        carwashMap[msg.sender].security = false;
        totalCarWash++;
    }

    function checkLevels(address _adr) internal {
        uint256 countCarwash = getCarwashes(_adr);
        uint256 carwashId = 0;
        while(countCarwash > 0){
            if(countCarwash % 5 == 0) { carwashId++; }                
            countCarwash--;
        }
        carwashMap[_adr].levelCarwash = (getCarwashes(_adr) - (carwashId * 5)) + 1;
        carwashMap[_adr].carwashId = carwashId;        
    }

    function dataRecovery(address _adr) internal {
        require(carwashMap[_adr].timestamp > 0, "Not registered user");
        if (carwashMap[_adr].harvestDay > 0) {
            // uint256 hrs = block.timestamp / 3600 - carwashMap[_adr].timestamp / 3600;
            // if (hrs >= 24) {                
            //     if(!carwashMap[_adr].security){
            //         if(randomSecurity(_adr)){ carwashMap[_adr].harvest = false; }
            //         else{ carwashMap[_adr].harvest = true; }                    
            //     }                
            // } 
            uint256 _minutes = block.timestamp / 60 - carwashMap[_adr].timestamp / 60;
            if(_minutes >= 20){
                if(!carwashMap[_adr].security){
                    if(randomSecurity(_adr)){ carwashMap[_adr].harvest = false; }
                    else{ carwashMap[_adr].harvest = true; }                    
                }   
                else{                    
                    carwashMap[_adr].harvest = true;
                }  
            }                 
        }
        carwashMap[_adr].timestamp = block.timestamp;
    }

     function buySecurity(address _adr) public{
        require(initializeContract, "The contract is currently paused.");
        require(_adr == msg.sender);
        require(carwashMap[_adr].timestamp > 0, "The user has not purchased any car wash.");
        require(!carwashMap[_adr].security, "You already have security contracted for today.");
        uint256 securityAmount = SafeMath.div(SafeMath.mul(carwashMap[_adr].harvestDay, 20), 100); 
        require(carwashMap[_adr].balance >= securityAmount, "You don't have enough money to pay for security today. Add funds.");
        carwashMap[_adr].balance -= securityAmount;
        carwashMap[_adr].security = true;
    }

    function randomSecurity(address _adr) internal returns(bool){  
        bool rob = false;
        uint random = uint(keccak256(abi.encodePacked(block.timestamp, _adr))) % 100;
        if(random <= 40){
            rob = true; 
            emit random_security_event(random, rob); 
            return true; 
        }
        rob = false;
        emit random_security_event(random, rob); 
        return false;               
    }

    function carwashPrice(uint256 _carwashId, uint256 _level) 
        internal 
        pure 
        returns (uint256)
    {
        if (_level == 1) return[2e16, 6e16, 18e16, 54e16, 108e16, 216e16, 432e16, 864e16][_carwashId];
        if (_level == 2) return[28e15, 84e15, 252e15, 756e15, 1512e15, 3024e15, 6048e15, 12096e15][_carwashId];
        if (_level == 3) return[36e15, 108e15, 324e15, 972e15, 1944e15, 3888e15, 7776e15, 15552e15][_carwashId];
        if (_level == 4) return[44e15, 132e15, 396e15, 1188e15, 2376e15, 4752e15, 9504e15, 19008e15][_carwashId];
        if (_level == 5) return[52e15, 156e15, 468e15, 1404e15, 2808e15, 5616e15, 11232e15, 22464e15][_carwashId];
        revert("Incorrect level id");
    }

    function harvestAmount(uint256 _carwashId, uint256 _level)
        internal
        pure
        returns (uint256)
    {
        if (_level == 1)return[4e14, 12e14, 36e14, 108e14, 216e14, 432e14, 864e14, 1728e14][_carwashId];
        if (_level == 2)return[6e14, 17e14, 50e14, 151e14, 302e14, 605e14, 121e15, 2419e14][_carwashId];
        if (_level == 3)return[7e14, 22e14, 65e14, 194e14, 389e14, 778e14, 1555e14, 311e15][_carwashId];
        if (_level == 4)return[9e14, 26e14, 79e14, 238e14, 475e14, 950e14, 1901e14, 3802e14][_carwashId];
        if (_level == 5)return[1e15, 31e14, 94e14, 281e14, 562e14, 1123e14, 2246e14, 4493e14][_carwashId];
        revert("Incorrect level id");
    }

    function getStatus() public view returns (bool) {
        return initializeContract;
    }    

    function devFee(uint256 _amount) private view returns (uint256) {
        return SafeMath.div(SafeMath.mul(_amount, devFeeVal), 100);
    }

    function refFee(uint256 _amount) private view returns (uint256) {
        return SafeMath.div(SafeMath.mul(_amount, refFeeVal), 100);
    }

    function getLatestPrice() public view returns (int) {
        (
            /*uint80 roundID*/,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = bnbPrice.latestRoundData();        
        return price * 1e10;
    }
}