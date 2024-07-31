/**
 *Submitted for verification at Etherscan.io on 2024-07-30
*/

pragma solidity ^0.8.26;


interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}


contract DegenAirdrops {
    function degenAirdropsEther(address[] calldata  recipients, uint256[] calldata  values) external payable {
        for (uint256 i = 0; i < recipients.length; i++)
            payable(recipients[i]).transfer(values[i]);
        uint256 balance = address(this).balance;
        if (balance > 0)
            payable(msg.sender).transfer(balance);
    }

    function degenAirdropsToken(IERC20 token, address[] calldata  recipients, uint256[] calldata  values) external {
        uint256 total = 0;
        for (uint256 i = 0; i < recipients.length; i++)
            total += values[i];
        require(token.transferFrom(msg.sender, address(this), total));
        for (uint256 i = 0; i < recipients.length; i++)
            require(token.transfer(recipients[i], values[i]));
    }

    function degenAirdropsTokenSimple(IERC20 token, address[] calldata  recipients, uint256[] calldata  values) external {
        for (uint256 i = 0; i < recipients.length; i++)
            require(token.transferFrom(msg.sender, recipients[i], values[i]));
    }
}
