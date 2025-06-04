// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {OwnableUpgradeable} from '@openzeppelin-upgradeable/access/OwnableUpgradeable.sol';
import {ReentrancyGuard} from '@openzeppelin/utils/ReentrancyGuard.sol';

import {IBreadfund} from '../interfaces/IBreadfund.sol';

/**
 * @title Breadfund
 * @notice Simple implementation of a Broodfond for ERC20 tokens
 * @author Breadchain Collective
 * @author @exo404
 * @author @valeriooconte
 */
contract Breadfund is IBreadfund, ReentrancyGuard, OwnableUpgradeable {
  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  /// @inheritdoc IBreadfund
  function initialize(address _owner) external override initializer {
    __Ownable_init_unchained(_owner);
  }
}
