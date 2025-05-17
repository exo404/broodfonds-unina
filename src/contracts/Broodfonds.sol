// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {OwnableUpgradeable} from '@openzeppelin-upgradeable/access/OwnableUpgradeable.sol';
import {IERC20} from '@openzeppelin/token/ERC20/IERC20.sol';
import {ReentrancyGuard} from '@openzeppelin/utils/ReentrancyGuard.sol';

import {IBroodfonds} from '../interfaces/IBroodfonds.sol';

/**
 * @title Broodfonds
 * @notice Simple implementation of a Broodfond for ERC20 tokens
 * @author Breadchain Collective
 * @author @exo404
 * @author @valeriooconte
 */
contract Broodfonds is IBroodfonds, ReentrancyGuard, OwnableUpgradeable {
  uint256 public constant MINIMUM_MEMBERS = 25;
  uint256 public constant MAXIMUM_MEMBERS = 50;
  uint256 public nextId;

  mapping(uint256 id => Fond fond) public fonds;
  mapping(uint256 id => mapping(address token => uint256 balance)) public balances;
  mapping(uint256 id => mapping(address member => bool status)) public isMember;
  mapping(address member => uint256[] ids) public memberFonds;
  mapping(uint256 id => mapping(address member => uint256 withdraws)) public fondMemberWithdrawals;
  mapping(uint256 id => mapping(address member => uint256 contribute)) public fondMemberContribute;
  mapping(address token => bool status) public allowedTokens;

  /// @inheritdoc IBroodfonds
  function create(Fond memory _fond) external override returns (uint256 _id) {
    _id = nextId++;

    if (fonds[_id].owner != address(0)) revert AlreadyExists();
    if (!allowedTokens[_fond.token]) revert TokenNotAllowed();
    if (_fond.depositInterval == 0) revert InvalidDepositInterval();
    if (_fond.depositAmount == 0) revert InvalidDepositAmount();
    if (_fond.maxDeposits == 0) revert InvalidMaxDeposits();
    if (_fond.fondStart == 0) revert InvalidfondStartTime();
    if (_fond.currentIndex != 0) revert InvalidCurrentIndex();
    if (_fond.owner == address(0)) revert InvalidOwner();
    if (_fond.members.length < MINIMUM_MEMBERS) revert InvalidMemberCount();
    if (_fond.members.length > MAXIMUM_MEMBERS) revert InvalidMemberCount();
    if (_fond.members.length != _fond.depositAmount.length) revert InvalidMemberCount();

    // Broodfonds specific checks
    if (_fond.initialDeposit <= 0) revert InvalidInitialDeposit();
    if (_fond.fixedDeposit <= 0) revert InvalidFixedDeposit();
    if (_fond.maxwithdraws <= 0) revert InvalidMaxWithdraws();
    if (_fond.maxwithdraws > 24) revert InvalidMaxWithdraws();

    //Caching the fond members length to avoid multiple lookups
    uint256 _fondMembersLength = _fond.members.length;

    for (uint256 i = 0; i < _fondMembersLength; i++) {
      address _member = _fond.members[i];
      if (_member == address(0)) revert InvalidMemberAddress();
      isMember[_id][_member] = true;
      memberfonds[_member].push(_id);
      fondMemberContribute[_id][_member] = _fond.depositAmount[i];
    }

    fonds[_id] = _fond;

    emit BroodfondsCreated(_id, _fond.members, _fond.token, _fond.depositAmount, _fond.depositInterval, _fond.fixedDeposit, _fond.maxwithdraws, _fond.depositAmount);
    return _id;
  }

  /// @inheritdoc IBroodfonds
  function decommission(uint256 _id) external override nonReentrant {
    Fond memory _fond = fonds[_id];

    //Caching the fond members variables to avoid multiple lookups
    uint256 _fondMembersLength = _fond.members.length;
    uint256 _fondDepositAmount = _fond.depositAmount;

    bool hasIncompleteDeposits = false;
    for (uint256 i = 0; i < _fondMembersLength; i++) {
      if (balances[_id][_fond.members[i]] < _fondDepositAmount) {
        hasIncompleteDeposits = true;
        break;
      }
    }
    if (!hasIncompleteDeposits) revert NotDecommissionable();

    // Return deposits to members
    for (uint256 i = 0; i < _fondMembersLength; i++) {
      address _member = _fond.members[i];
      uint256 _balance = balances[_id][_member];

      if (_balance > 0) {  
        balances[_id][_member] = 0;
        bool success = IERC20(_fond.token).transfer(_member, _balance);
        if (!success) revert TransferFailed();
      }
    }

    delete fonds[_id];

    emit BroodfondsDecommissioned(_id);
  }
  
}
