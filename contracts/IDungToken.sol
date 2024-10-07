// SPDX-License-Identifier: MIT
pragma solidity >=0.5.8 <0.9.0;

interface IDungToken {
    /**
     * @dev Returns the amount of tokens owned by `account`.
     * @param account The address to query the balance of.
     * @return The amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Transfers `amount` tokens to `recipient`.
     * @param recipient The address to send the tokens to.
     * @param amount The amount of tokens to transfer.
     * @return A boolean value indicating whether the operation succeeded.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` is allowed to spend on behalf of `owner`.
     * @param owner The address of the token owner.
     * @param spender The address of the spender.
     * @return The remaining number of tokens.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Approves `spender` to spend `amount` of the caller's tokens.
     * @param spender The address which will spend the tokens.
     * @param amount The number of tokens to approve for spending.
     * @return A boolean value indicating whether the operation succeeded.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the allowance mechanism.
     * `amount` is then deducted from the caller's allowance.
     * @param sender The address to send the tokens from.
     * @param recipient The address to send the tokens to.
     * @param amount The number of tokens to transfer.
     * @return A boolean value indicating whether the operation succeeded.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}
