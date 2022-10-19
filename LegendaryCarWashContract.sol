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
    uint256 private totalCarWash;
    uint256 private totalPlayers;
    uint256 private totalBnbDeposited;

    AggregatorV3Interface internal bnbPrice;

    // Eventos que lanzaremos al realizar ciertas acciones
    event add_funds_event(uint256 amount, address wallet, address ref);
    event withdraw_event(uint256 amount, address wallet);
    event upgrade_carWash_event(uint256 carwashId, address wallet);
    event random_security_event(uint randomNumber, bool rob);

    struct User {
        address wallet;
        uint256 balance;
        uint256 harvestDay;
        address referred;
        uint256 refsNumber;
        uint256 timestamp;
        uint256 hrs;
        uint256 harvest;
        bool security;        
        uint8[8] carwash;
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

    function initialized(bool _initializeContract)
        external
        onlyOwner(msg.sender)
    {
        if (_initializeContract) {
            initializeContract = true;
        } else {
            initializeContract = false;
        }
    }

    function addFunds(address _ref) public payable {
        require(initializeContract, "The contract is currently paused.");
        require(msg.value >= 2e16, "The minimum entry amount is 0.02 BNB");
        if (carwashMap[msg.sender].timestamp == 0) {
            _ref = carwashMap[_ref].timestamp == 0 ? devs : _ref;
            carwashMap[_ref].refsNumber++;
            carwashMap[msg.sender].referred = _ref;
            carwashMap[msg.sender].timestamp = block.timestamp;
            totalPlayers++;
        }
        totalBnbDeposited += msg.value;
        carwashMap[msg.sender].balance += msg.value;
        _ref = carwashMap[msg.sender].referred;
        carwashMap[_ref].balance += refFee(msg.value);
        payable(devs).transfer(devFee(msg.value));
        emit add_funds_event(msg.value, msg.sender, _ref);
    }

    function recover() public {
        require(initializeContract, "The contract is currently paused.");
        dataRecovery(msg.sender);
        carwashMap[msg.sender].balance += carwashMap[msg.sender].harvest;
        carwashMap[msg.sender].hrs = 0;
        carwashMap[msg.sender].harvest = 0;
        carwashMap[msg.sender].security = false;
    }

    function withdraw() public {
        require(initializeContract, "The contract is currently paused.");        
        uint256 balance = carwashMap[msg.sender].balance;
        uint256 bnbContract = address(this).balance;
        payable(msg.sender).transfer(
            bnbContract < carwashMap[msg.sender].balance
                ? bnbContract
                : carwashMap[msg.sender].balance
        );
        carwashMap[msg.sender].balance = 0;
        emit withdraw_event(balance, msg.sender);
    }

    function upgradeCarWash(uint256 _carwashId) public {
        require(initializeContract, "The contract is currently paused.");
        require(_carwashId < 8, "8 car washes maximum per user");
        dataRecovery(msg.sender);
        carwashMap[msg.sender].carwash[_carwashId]++;
        carwashMap[msg.sender].balance -= carwashPrice(
            _carwashId,
            carwashMap[msg.sender].carwash[_carwashId]
        );
        carwashMap[msg.sender].harvestDay += harvestAmount(
            _carwashId,
            carwashMap[msg.sender].carwash[_carwashId]
        );
        totalCarWash++;
        emit upgrade_carWash_event(_carwashId, msg.sender);
    }

    function dataRecovery(address _user) internal {
        require(carwashMap[_user].timestamp > 0, "Nulled");
        if (carwashMap[_user].harvestDay > 0) {
            uint256 hrs = block.timestamp /
                3600 -
                carwashMap[_user].timestamp /
                3600;
            if (carwashMap[_user].hrs + hrs > 24) {                
                hrs = 24 - carwashMap[_user].hrs;
                carwashMap[_user].harvest += hrs * carwashMap[_user].harvestDay;
                carwashMap[_user].hrs += hrs;
                if(!carwashMap[_user].security){
                    if(randomSecurity(_user)){
                        carwashMap[_user].harvest = 0;
                    }
                }
            }            
        }
        carwashMap[_user].timestamp = block.timestamp;
    }

    function carwashPrice(uint256 _carwashId, uint256 _level) 
        internal 
        pure 
        returns (uint256)
    {
        if (_level == 1)
            return
                [2e16, 6e16, 18e16, 54e16, 108e16, 216e16, 432e16, 864e16][
                    _carwashId
                ];
        if (_level == 2)
            return
                [28e15, 84e15, 252e15, 756e15, 1512e15, 3024e15, 6048e15, 12096e15][
                    _carwashId
                ];
        if (_level == 3)
            return
                [36e15, 108e15, 324e15, 972e15, 1944e15, 3888e15, 7776e15, 15552e15][
                    _carwashId
                ];
        if (_level == 4)
            return
                [44e15, 132e15, 396e15, 1188e15, 2376e15, 4752e15, 9504e15, 19008e15][
                    _carwashId
                ];
        if (_level == 5)
            return
                [52e15, 156e15, 468e15, 1404e15, 2808e15, 5616e15, 11232e15, 22464e15][
                    _carwashId
                ];
        revert("Incorrect levelId");
    }

    function harvestAmount(uint256 _carwashId, uint256 _level)
        internal
        pure
        returns (uint256)
    {
        if (_level == 1)
            return
                [4e14, 12e14, 36e14, 108e15, 216e15, 432e15, 864e15, 1728e14][
                    _carwashId
                ];
        if (_level == 2)
            return
                [6e14, 17e14, 50e14, 151e15, 302e15, 605e15, 121e15, 2419e14][
                    _carwashId
                ];
        if (_level == 3)
            return
                [7e14, 22e14, 65e14, 194e15, 389e15, 778e15, 1555e14, 311e15][
                    _carwashId
                ];
        if (_level == 4)
            return
                [9e14, 26e14, 79e14, 238e15, 475e15, 950e15, 1901e14, 3802e14][
                    _carwashId
                ];
        if (_level == 5)
            return
                [1e15, 31e14, 94e14, 281e15, 562e15, 1123e14, 2246e14, 4493e14][
                    _carwashId
                ];
        revert("Incorrect levelId");
    }

    function buySecurity(address _adr) public{
        require(initializeContract, "The contract is currently paused.");
        require(_adr == msg.sender);
        require(carwashMap[_adr].timestamp > 0, "The user has not purchased any car wash.");
        require(carwashMap[_adr].hrs == 0, "You can only hire security when you go to collect.");
        require(!carwashMap[_adr].security, "You already have security contracted for today.");
        uint256 securityAmount = SafeMath.div(SafeMath.mul(carwashMap[_adr].harvestDay, 20), 100); 
        require(carwashMap[_adr].balance >= securityAmount, "You don't have enough money to pay for security today. Add funds.");
        carwashMap[_adr].balance -= securityAmount;
        carwashMap[_adr].security = true;
    }

    function randomSecurity(address _adr) public returns(bool){     // ************ CAMBIAR A INTERNAL   
        bool rob = false;
        uint random = uint(keccak256(abi.encodePacked(block.timestamp, _adr))) % 100;
        if(random <= 20){
            rob = true; 
            emit random_security_event(random, rob); 
            return true; 
        }
        rob = false;
        emit random_security_event(random, rob); 
        return false;   
            
    }

    function getStatus() public view returns (bool) {
        return initializeContract;
    }

    function getCarwash(address _adr) public view returns (uint8[8] memory) {
        return carwashMap[_adr].carwash;
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




// quitar minimo de entrada
// no deejar comprar en otro lavadero hasta que se llene al nivel 5 el anterior
// cambiar el % de seguridad