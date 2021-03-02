if (reserveAmount < amount) {
IERC20 \_ticket = IERC20(ticket);
uint256 userShares = balanceOf(msg.sender);

            if (balance >= _ticket.balanceOf(address(this)).add(amount)) {
                _depositsBacklogAmount = _depositsBacklogAmount.sub(amount);
            } else {
                uint256 _withdraw = amount.sub(reserveAmount);
                _withdrawFromPool(_withdraw, _maximumExitFee);
                uint256 _after = _token.balanceOf(address(this));
                uint256 _diff = _after.sub(balance);
                reserveAmount = reserveAmount.sub(reserveAmount);
                if (_diff < _withdraw) {
                    amount = balance.add(_diff);
                }
            }
        } else {
            reserveAmount = reserveAmount.sub(amount);
        }



        if (reserveAmount < amount) {

            if(balance.sub(reserveAmount) > amount) {

            }

            uint256 _withdraw = amount.sub(reserveAmount);
            _withdrawFromPool(_withdraw, _maximumExitFee);
            uint256 _after = _token.balanceOf(address(this));
            uint256 _diff = _after.sub(balance);
            reserveAmount = reserveAmount.sub(reserveAmount);
            if (_diff < _withdraw) {
                amount = balance.add(_diff);
            }
        } else {
            reserveAmount = reserveAmount.sub(amount);
        }
