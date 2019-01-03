pragma solidity 0.5.2;
import './token/interfaces/IERC20Token.sol';

/*
    Bancor Network interface
*/
contract IBancorNetwork {
    function convert(IERC20Token[] memory _path, uint256 _amount, uint256 _minReturn) public payable returns (uint256);
    function convertFor(IERC20Token[] memory _path, uint256 _amount, uint256 _minReturn, address payable _for) public payable returns (uint256);
    function convertForPrioritized2(
        IERC20Token[] memory _path,
        uint256 _amount,
        uint256 _minReturn,
        address payable _for,
        uint256 _block,
        uint8 _v,
        bytes32 _r,
        bytes32 _s)
        public payable returns (uint256);

    // deprecated, backward compatibility
    function convertForPrioritized(
        IERC20Token[] memory _path,
        uint256 _amount,
        uint256 _minReturn,
        address payable _for,
        uint256 _block,
        uint256 _nonce,
        uint8 _v,
        bytes32 _r,
        bytes32 _s)
        public payable returns (uint256);
}