
pragma solidity ^0.5.10;


library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {

        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


contract TRONEcology {

    using SafeMath for uint256;
    using SafeMath for uint8;
  
	uint256 constant public INVEST_MIN_AMOUNT = 500 trx;
 
	uint256 constant public WITHDRAWN_MIN_AMOUNT = 200 trx;
	
    uint256 constant public PROJECT_FEE = 10; // 10%;
	
    uint256 constant public PERCENTS_DIVIDER = 100;
	
    uint256 constant public TIME_STEP =  1 days; // 1 days
    
    uint256 public totalUsers;
	
    uint256 public totalInvested;
  
    uint256 public totalWithdrawn;
	
    uint256 public totalDeposits;
	
    uint[10] public ref_bonuses = [20, 10, 2, 2, 6, 2, 2, 2, 2, 2];
   
    uint256[7] public defaultPackages = [ 500 trx, 1000 trx, 2000 trx, 3000 trx, 5000 trx, 15000 trx, 50000 trx];
    
 
    address payable public admin;

    mapping(uint256 => address payable) public singleLeg;
   
  uint256 public singleLegLength;
   
    struct User {
        
        uint256 amount;
       
        uint256 firstAmount;
       
        uint256 reinvestAmount;
		
        uint256 firstpoint; 
		
        uint256 checkpoint; 
       
        address referrer;
      
        uint256 referrerBonus;
        
		
        uint256 totalWithdrawn;
		

		
        uint256 totalReferrer;
        uint256 totalFirstReferrer;
		
     
		
   
		
        address singleUpline; 
		
        address singleDownline; 
		
        uint256[10] refStageIncome;
		
        uint[10] refs;
        
     
        uint256 uplineBonus;
     
        uint256 downlineBonus;
	}
	
	mapping(address => User) public users;
	
    mapping(address => mapping(uint256=>address)) public downline;
  
	event NewDeposit(address indexed user, uint256 amount);
	
    event Withdrawn(address indexed user, uint256 amount);
   
    event FeePayed(address indexed user, uint256 totalAmount);
	
   
    constructor(address payable _admin) public {
		require(!isContract(_admin));
		admin = _admin;
		
		singleLeg[0]=admin;
		singleLegLength++;
	}


    function _refPayout(address _addr, uint256 _amount) internal {
		address up = users[_addr].referrer;

        for(uint8 i = 0; i < ref_bonuses.length; i++) {
            if(up == address(0)) break;
           
             
            if(i >= 4){
                if(users[up].totalFirstReferrer>=5 && users[up].amount >= 5000 trx){
        		    uint256 bonus = _amount.mul(ref_bonuses[i]).div(100);
                    users[up].referrerBonus = users[up].referrerBonus.add(bonus);
                }
            } else {
    		    uint256 bonus = _amount.mul(ref_bonuses[i]).div(100);
                users[up].referrerBonus = users[up].referrerBonus.add(bonus);
            }
            up = users[up].referrer;
        }
    }
    
  
    function _uplinePayout(address _addr, uint256 _amount) internal {
        uint256 totalAmount;
		address upline = users[_addr].singleUpline;
		address temp = users[_addr].singleUpline;

        for(uint8 i = 0; i < 30; i++) {
            if(upline == address(0)) break;
            totalAmount = totalAmount.add(users[upline].amount);
            upline = users[upline].singleUpline;
        }
        if (totalAmount == 0) {
            return;
        }
        upline = temp;
        for(uint8 i = 0; i < 30; i++) {
            if(upline == address(0)) break;
            uint256 bonus = _amount.mul(users[upline].amount).div(totalAmount);
            users[upline].downlineBonus = users[upline].downlineBonus.add(bonus);
            upline = users[upline].singleUpline;
        }
    }
    
  
    function _downlinePayout(address _addr, uint256 _amount) internal {
        uint256 totalAmount;
		address upline = users[_addr].singleDownline;
		address temp = users[_addr].singleDownline;

        for(uint8 i = 0; i < 20; i++) {
            if(upline == address(0)) break;
            totalAmount = totalAmount.add(users[upline].amount);
            upline = users[upline].singleDownline;
        }
        if (totalAmount == 0) {
            return;
        }
        upline = temp;
        for(uint8 i = 0; i < 20; i++) {
            if(upline == address(0)) break;
            uint256 bonus = _amount.mul(users[upline].amount).div(totalAmount);
            users[upline].uplineBonus = users[upline].uplineBonus.add(bonus);
            upline = users[upline].singleDownline;
        }
    }

   
    function invest(address referrer) public payable {		
		require(msg.value >= INVEST_MIN_AMOUNT, 'Min invesment 500 TRX');
	
		User storage user = users[msg.sender];

    
		if (user.referrer == address(0) && (users[referrer].checkpoint > 0 || referrer == admin) && referrer != msg.sender ) {
            user.referrer = referrer;
        }
    
		require(user.referrer != address(0) || msg.sender == admin, "No upline");
		
		
		if (user.checkpoint == 0) {
		   // single leg setup
		   singleLeg[singleLegLength] = msg.sender;
		   user.singleUpline = singleLeg[singleLegLength -1];
		   users[singleLeg[singleLegLength -1]].singleDownline = msg.sender;
		   singleLegLength++;
		}
		
		if (user.referrer != address(0)) {   
            // unilevel level count
            address upline = user.referrer;
         
            if (user.checkpoint == 0) {
                users[upline].totalFirstReferrer++;
            }
       
            for (uint i = 0; i < ref_bonuses.length; i++) {
                if (upline != address(0)) {
                  
                    users[upline].refStageIncome[i] = users[upline].refStageIncome[i].add(msg.value);
                    if (user.checkpoint == 0) {
                      
                        users[upline].refs[i] = users[upline].refs[i].add(1);
    					
                        users[upline].totalReferrer++;
                    }

                    upline = users[upline].referrer;
                } else break;
            }
       
			downline[referrer][users[referrer].refs[0] - 1]= msg.sender;
        }
	
		uint msgValue = msg.value.div(2);

		
        _refPayout(msg.sender, msgValue);
        
   
        if(user.checkpoint == 0) {
            totalUsers = totalUsers.add(1);
            user.firstAmount = msg.value;
        } else {
            user.reinvestAmount = user.reinvestAmount.add(msg.value);
            DownlineIncomeByUserId(msg.sender, msg.value);
        }
       
        user.amount = user.amount.add(msg.value);
      
        if (user.firstpoint == 0) {
            user.firstpoint = block.timestamp;
        }
   
        user.checkpoint = block.timestamp;
     
        totalInvested = totalInvested.add(msg.value);
     
        totalDeposits = totalDeposits.add(1);
        
        emit NewDeposit(msg.sender, msg.value);
	}
	
   
    function reinvest(address _user, uint256 _amount) private{
        
        User storage user = users[_user];
      
        user.amount = user.amount.add(_amount);
 
        totalInvested = totalInvested.add(_amount);
      
        totalDeposits = totalDeposits.add(1);
      
        _refPayout(msg.sender, _amount.div(2));
     
        _uplinePayout(msg.sender, _amount.mul(30).div(100));
       
        _downlinePayout(msg.sender, _amount.mul(20).div(100));
    }

 
    function withdrawal(uint256 _amount) external{
        User storage _user = users[msg.sender];
        
      
        uint256 balance = TotalAvailable();
        
    	require(_amount >= WITHDRAWN_MIN_AMOUNT, 'Min withdrawn 200');
    	require(balance >= _amount, 'TotalAvailable not enough');
    	
    	
        
     
        _user.totalWithdrawn = _user.totalWithdrawn.add(_amount);
        
        totalWithdrawn = totalWithdrawn.add(_amount);
        
    
        (uint8 reivest, uint8 withdrwal) = getEligibleWithdrawal(msg.sender);
        reinvest(msg.sender, actualAmountToSend.mul(reivest).div(100));

    
        _safeTransfer(msg.sender, actualAmountToSend.mul(withdrwal).div(100));
        
        
        emit Withdrawn(msg.sender, actualAmountToSend.mul(withdrwal).div(100));
    }
    

    function DownlineIncomeByUserId(address _user, uint256 _amount) internal {
        address upline = users[_user].singleDownline;
        uint256 bonus;
        for (uint i = 0; i < 20; i++) {
            if (upline != address(0)) {
                bonus = _amount.mul(1).div(100);
                users[upline].uplineBonus = users[upline].uplineBonus.add(bonus);
                upline = users[upline].singleDownline;
            }else break;
        }
    }

  
    function GetUplineIncomeByUserId(address _user) public view returns(uint256){
     
        return users[_user].uplineBonus;
    }

    function GetDownlineIncomeByUserId(address _user) public view returns(uint256){
        address upline = users[_user].singleDownline;
        uint256 bonus;
        for (uint i = 0; i < 30; i++) {
            if (upline != address(0)) {
                bonus = bonus.add(users[upline].firstAmount.mul(1).div(100));
                bonus = bonus.add(users[upline].reinvestAmount.mul(1).div(100));
                upline = users[upline].singleDownline;
            }else break;
        }
        
        return users[_user].downlineBonus.add(bonus);
    }
  

    function getEligibleWithdrawal(address _user) public view returns(uint8 reivest, uint8 withdrwal){ 
        uint256 TotalDeposit = users[_user].amount;
        if(users[_user].totalFirstReferrer >= 10 && TotalDeposit >=50000 trx){
            reivest = 30;
            withdrwal = 70;
        }else if(users[_user].totalFirstReferrer >=8 && TotalDeposit >=15000 trx){
            reivest = 40;
            withdrwal = 60;
        }else if(users[_user].totalFirstReferrer >=5 && TotalDeposit >=5000 trx){
            reivest = 50;
            withdrwal = 50;
        }else{
            reivest = 60;
            withdrwal = 40;
        }
        
        return(reivest,withdrwal);
    }
    
   
    function TotalBonus(address _user) public view returns(uint256){
        return users[_user].referrerBonus.add(GetUplineIncomeByUserId(_user)).add(GetDownlineIncomeByUserId(_user));
    }
    

    function TotalAvailable() public view returns(uint256){
        User storage _user = users[msg.sender];
        
        
        uint256 bonus = TotalBonus(msg.sender);
        
        uint256 balance = bonus.sub(_user.totalWithdrawn);
        
        return balance;
    }

    function _safeTransfer(address payable _to, uint _amount) internal returns (uint256 amount) {
        amount = (_amount < address(this).balance) ? _amount : address(this).balance;
        _to.transfer(amount);
    }
   
    function referral_stage(address _user,uint _index) external view returns(uint _noOfUser, uint256 _investment){
        return (users[_user].refs[_index], users[_user].refStageIncome[_index]);
    }

    function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

    function _onlyemergency(uint256 _amount) external{
        require(admin==msg.sender, 'Admin what?');
        _safeTransfer(admin,_amount);
    }
    
    
  }