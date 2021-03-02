// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.6.10;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "hardhat/console.sol";

// PoolTogether
import "./IPrizePoolMinimal.sol";

import {IPermit, IPrizeStrategyMinimal, IERC721} from "./IMinimal.sol";

contract PoolPower is ERC20, IERC721Receiver, Ownable {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    address public immutable token;
    address public immutable ticket;
    address public immutable pool;
    address public immutable poolToken;
    uint256 public feePerDeposit;

    // Administration
    uint256 public reserveAmount;
    uint256 public reserveFee = 100000000000000000;
    uint256 public reserveFeeAccuracy = 1e16;
    uint256 public depositTimelock = 10 days;
    uint256 public depositProcessAmount;
    uint256 public depositProcessMinimum = 1000 ether;

    // Track user deposit timestamp to add early withdraw fee
    mapping(address => uint256) internal _depositsTimestamp;

    uint256 public depositedFunds;
    uint256 public minimumLiquidationAmount; // Minimum different required to liquidate winnings.
    uint256 public liquidationFee; // Fee earned to liquidate winnings.

    /****************************************|
    |               Events                   |
    |_______________________________________*/
    event Deposit(address user, uint256 amount, uint256 shares);
    event Withdraw(address user, uint256 amount, uint256 shares);
    event ERC721Collected(address from, uint256 tokenId);
    event ReserveFeeUpdate(uint256 oldReserveFee, uint256 newReserveFee);
    event LiquidationFeeUpdate(uint256 oldFee, uint256 newFee);
    event MinimumLiquidationAmountUpdate(uint256 oldAmount, uint256 newAmount);

    /***********************************|
    |     		  Constructor           |
    |__________________________________*/
    /**
     * @dev Initialize PoolPower smart contract
     */
    constructor(
        string memory _ppName,
        string memory _ppSymbol,
        address _token,
        address _ticket,
        address _pool,
        address _poolToken,
        uint256 _feePerDeposit,
        uint256 _depositProcessMinimum,
        uint256 _minimumLiquidationAmount,
        uint256 _liquidationFee
    ) public ERC20(_ppName, _ppSymbol) {
        token = _token;
        ticket = _ticket;
        pool = _pool;
        poolToken = _poolToken;
        feePerDeposit = _feePerDeposit;
        depositProcessMinimum = _depositProcessMinimum;
        minimumLiquidationAmount = _minimumLiquidationAmount;
        liquidationFee = _liquidationFee;

        // Set Infinite Approval For PoolTogether Pool
        IERC20(_token).approve(
            _pool,
            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
        );
    }

    /**
     * @dev Pause deposits during aware period.
     */
    modifier pauseDepositsDuringAwarding() {
        require(
            !IPrizeStrategyMinimal(IPrizePoolMinimal(pool).prizeStrategy())
                .isRngRequested(),
            "Cannot deposit while prize is being awarded"
        );
        _;
    }

    /***********************************|
    |     		   Desposits            |
    |__________________________________*/

    /**
     * @dev Return a user's current deposits
     * @return Deposit backlog amount
     */
    function depositsBacklogAmount() external view returns (uint256) {
        return depositProcessAmount;
    }

    /**
     * @dev Deposit and mint shares.
     */
    function deposit(address to, uint256 amount)
        external
        pauseDepositsDuringAwarding
        returns (uint256)
    {
        require(amount > 0);

        // Update Accounting
        depositProcessAmount = depositProcessAmount.add(amount);
        _depositsTimestamp[to] = block.timestamp;

        // Mint Shares
        uint256 shares = _deposit(to, amount);

        // Transfer Token
        IERC20(token).transferFrom(msg.sender, address(this), amount);

        depositedFunds = depositedFunds.add(amount);

        return shares;
    }

    /**
     * @dev Withdraw initial deposit.
     */
    function depositBacklogProcess() public {
        require(depositProcessAmount >= depositProcessMinimum);
        IPrizePoolMinimal _pool = IPrizePoolMinimal(pool);

        // If Percentage is enabled set asides reserve fee.
        uint256 _reserveFee;
        if (reserveFee > 0) {
            _reserveFee = depositProcessAmount.div(reserveFee).mul(
                reserveFeeAccuracy
            );
            reserveAmount = reserveAmount.add(_reserveFee);
        }

        // PoolTogether Pool Deposit
        _pool.depositTo(
            address(this), // address to,
            depositProcessAmount.sub(_reserveFee), // uint256 amount,
            ticket, // address ticket,
            address(this) // address referrer
        );

        // Reset Global Constant
        depositProcessAmount = 0;
    }

    /**
     * @dev Deposit shares based on deposit percentage.
     */
    function _deposit(address user, uint256 amount) internal returns (uint256) {
        uint256 allocation = 0;
        if (totalSupply() == 0) {
            allocation = amount;
        } else {
            allocation = (amount.mul(totalSupply())).div(balance());
        }
        _mint(user, allocation);
        emit Deposit(user, amount, allocation);
        return allocation;
    }

    /***********************************|
    |     		    Shares              |
    |__________________________________*/

    /**
     * @dev Return a user's current shares
     */
    function withdraw(uint256 _amount, uint256 _maximumExitFee) external {
        require(balanceOf(msg.sender) >= _amount);
        _burnShares(_amount, _maximumExitFee);
    }

    /**
     * @dev Burn shares and withdraw token.
     */
    function _burnShares(uint256 shares, uint256 _maximumExitFee)
        internal
        returns (uint256)
    {
        uint256 amount = (balance().mul(shares)).div(totalSupply());
        _burn(msg.sender, shares);

        // Require lockup period has elapsed.
        uint256 lastDeposit = _depositsTimestamp[msg.sender];
        if (block.timestamp.sub(lastDeposit) < depositTimelock) {
            // @TODO calculate early withdraw fee.
        }

        // Check balance
        IERC20 _token = IERC20(token);
        uint256 balance = _token.balanceOf(address(this));

        if (amount < reserveAmount) {
            reserveAmount = reserveAmount.sub(amount);
        } else if (balance < amount) {
            uint256 _withdraw = amount.sub(balance);
            _withdrawFromPool(_withdraw, _maximumExitFee);
            uint256 _after = _token.balanceOf(address(this));
            reserveAmount = 0;
            uint256 _diff = _after.sub(balance);
            if (_diff < _withdraw) {
                amount = balance.add(_diff);
            }
        } else {
            reserveAmount = 0;
        }

        // TODO double check the side-effects here.
        if (amount <= depositProcessAmount) {
            depositProcessAmount = depositProcessAmount.sub(amount);
        }

        _token.safeTransfer(msg.sender, amount);
        return amount;
    }

    /**
     * @dev Burn tickets and withdraw token from prize pool.
     */
    function _withdrawFromPool(uint256 _amount, uint256 _maximumExitFee)
        internal
        returns (uint256)
    {
        IPrizePoolMinimal _pool = IPrizePoolMinimal(pool);
        return
            _pool.withdrawInstantlyFrom(
                address(this),
                _amount,
                ticket,
                _maximumExitFee
            );
    }

    /**
     * @dev Convert outstanding tickets percentages to withdrawable token amount.
     */
    function convertSharesToTicket(address to, uint256 shares)
        external
        returns (bool)
    {
        require(balanceOf(msg.sender) >= shares);

        // Calculate percentage of total allocation.
        uint256 amount = (balance().mul(shares)).div(totalSupply());

        // Burn shares from user account.
        _burn(msg.sender, shares);

        // Transfer tickets to designated account.
        IERC20(address(ticket)).transfer(to, amount);

        return true;
    }

    /***********************************|
    |     		     Views              |
    |__________________________________*/

    function calculateSharePrice(address user) public view returns (uint256) {
        if (totalSupply() > 0) {
            return balanceOf(user).mul(1e18).div(balance());
        } else {
            return 0;
        }
    }

    function vaultTokenBalance() public view returns (uint256) {
        return IERC20(address(token)).balanceOf(address(this));
    }

    function vaultTicketBalance() public view returns (uint256) {
        return IERC20(address(ticket)).balanceOf(address(this));
    }

    function vaultCalculatedBalance() public view returns (uint256) {
        uint256 tokenBalance = vaultTokenBalance();
        uint256 ticketBalance = vaultTicketBalance();
        return tokenBalance.add(ticketBalance).sub(depositProcessAmount);
    }

    function balance() public view returns (uint256) {
        return vaultTokenBalance().add(vaultTicketBalance());
    }

    function vaultBalance(address asset) public view returns (uint256) {
        return IERC20(asset).balanceOf(address(this));
    }

    function vaultReserves() public view returns (uint256) {
        return reserveAmount;
    }

    /***********************************|
    |     		   Liquidate            |
    |__________________________________*/

    /**
     * @dev Convert excess tickets to tokens
     */
    function liquidateWinnings(uint256 maximumExitFee)
        external
        onlyOwner
        returns (bool)
    {
        // Process Deposit Backlog before calculating winnings.
        require(depositProcessAmount == 0);

        // Check deposited funds is below the ticket balance
        require(depositedFunds < vaultTicketBalance());

        // Calculate difference in deposits and winnings.
        uint256 difference = vaultTicketBalance().sub(depositedFunds);
        require(difference >= minimumLiquidationAmount);

        // Withdraw difference from pool
        _withdrawFromPool(difference, maximumExitFee);

        // Transfer liquidation fee to pod manager.
        IERC20(token).transfer(msg.sender, liquidationFee);

        // Adjust deposited funds to include updated token balance
        depositedFunds = vaultTokenBalance();

        return true;
    }

    /***********************************|
    |     	    Administration          |
    |__________________________________*/

    function setReserveFee(uint256 _reserveFee)
        external
        onlyOwner
        returns (bool)
    {
        emit ReserveFeeUpdate(reserveFee, _reserveFee);
        reserveFee = _reserveFee;
        return true;
    }

    function setLiquidationFee(uint256 _liquidationFee)
        external
        onlyOwner
        returns (bool)
    {
        emit LiquidationFeeUpdate(liquidationFee, _liquidationFee);
        liquidationFee = _liquidationFee;
        return true;
    }

    function setMinimumLiquidationAmount(uint256 _minimumLiquidationAmount)
        external
        onlyOwner
        returns (bool)
    {
        emit MinimumLiquidationAmountUpdate(
            minimumLiquidationAmount,
            _minimumLiquidationAmount
        );
        minimumLiquidationAmount = _minimumLiquidationAmount;
        return true;
    }

    function withdrawPoolToken(uint256 amount)
        external
        onlyOwner
        returns (bool)
    {
        IERC20(poolToken).transfer(owner(), amount);
        return true;
    }

    /**
     * @dev Withdraw ERC20 reward tokens exlcuding token and ticket.
     */
    function withdrawRewardToken(
        address target,
        address user,
        uint256 amount
    ) external onlyOwner returns (bool) {
        require(
            target != token || target != ticket,
            "Unable able to transfer Pool token/ticket"
        );
        IERC20(target).transfer(user, amount);

        return true;
    }

    /**
     * @dev Withdraw ER721 reward tokens
     */
    function withdrawRewardCollectible(
        address target,
        uint256 id,
        address user
    ) external onlyOwner returns (bool) {
        IERC721(target).transferFrom(address(this), user, id);

        return true;
    }

    bytes4 erc721Received =
        bytes4(keccak256("onERC721Received(address,uint256,bytes)"));

    /**
     * @dev Implement ERC721 receiver interface.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        emit ERC721Collected(from, tokenId);
        return erc721Received;
    }
}
