// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/** 
 * @title Ballot
 * @dev Implements voting process along with vote delegation
 */
contract Ballot {

    struct Voter {
        uint weight; // weight is accumulated by delegation
        bool voted;  // if true, that person already voted
        address delegate; // person delegated to
        uint vote;   // index of the voted proposal
    }

    struct Proposal {
        // If you can limit the length to a certain number of bytes, 
        // always use one of bytes1 to bytes32 because they are much cheaper
        bytes32 name;   // short name (up to 32 bytes) // 提案名字
        uint voteCount; // number of accumulated votes // 提案的得票数
    }

    // 合约的制定者作为主席将给予每个地址投票权
    address public chairperson;
    // 投票人和自身拥有的属性之间的映射
    mapping(address => Voter) public voters;
    // 提案数组
    Proposal[] public proposals;

    /** 
     * @dev Create a new ballot to choose one of 'proposalNames'.
     * @param proposalNames names of proposals
     */
    constructor(bytes32[] memory proposalNames) {
        // 主席即为合约的调用者
        chairperson = msg.sender;
        // 主席自然有自己的投票权重
        voters[chairperson].weight = 1;
        // 初始化提案数组，每个提案的初始得票数都为0
        for (uint i = 0; i < proposalNames.length; i++) {
            // 'Proposal({...})' creates a temporary
            // Proposal object and 'proposals.push(...)'
            // appends it to the end of 'proposals'.
            proposals.push(Proposal({
                name: proposalNames[i],
                voteCount: 0
            }));
        }
    }

    /** 
     * @dev Give 'voter' the right to vote on this ballot. May only be called by 'chairperson'.
     * @param voter address of voter
     */
    function giveRightToVote(address voter) public {
        require(
            msg.sender == chairperson,
            "Only chairperson can give right to vote."
        );
        // 要求被授权的投票者必须是没有投过票的
        require(
            !voters[voter].voted,
            "The voter already voted."
        );
        // 要求被授权的投票者原来的权重必须是0
        require(voters[voter].weight == 0);
        // Voter结构体初始化时权重属性为0，此时赋予投票者权重说明该投票者已经被赋予了投票的权利
        voters[voter].weight = 1;
    }

    /**
     * @dev Delegate your vote to the voter 'to'.
     * @param to address to which vote is delegated
     * msg.sender委托自己的投票给投票者‘to’
     */
    function delegate(address to) public {
        Voter storage sender = voters[msg.sender];
        // 确保msg.sender没有投过票
        require(!sender.voted, "You already voted.");
        // 确保msg.sender没有委托自己投票
        require(to != msg.sender, "Self-delegation is disallowed.");
        // 处理有连续委托人的情况，直到最后一个没有可委托的人为止
        // 这最后一个人将作为真正的"to"
        while (voters[to].delegate != address(0)) {
            to = voters[to].delegate;

            // We found a loop in the delegation, not allowed.
            // 确保连续委托的情况，所经过的每个委托人都不是msg.sender（也就是排除委托给自己的情况）
            require(to != msg.sender, "Found loop in delegation.");
        }
        // 赋值msg.sender投过票了
        sender.voted = true;
        // msg.sender选定“to”为投票委托人
        sender.delegate = to;
        Voter storage delegate_ = voters[to];
        if (delegate_.voted) {
            // If the delegate already voted,
            // directly add to the number of votes
            // 如果delegate_之前已经给delegate_.vote这个提案投过票了，
            // 现在因为是受sender的委托再投票，所以直接把sender的权重加到delegate_.vote这个提案上
            proposals[delegate_.vote].voteCount += sender.weight;
        } else {
            // If the delegate did not vote yet,
            // add to her weight.
            // 如果delegate_还没有给任何一个提案投过票，sender就把自己的权重给delegate_供以后投票使用
            delegate_.weight += sender.weight;
        }
    }

    /**
     * @dev Give your vote (including votes delegated to you) to proposal 'proposals[proposal].name'.
     * @param proposal index of proposal in the proposals array
     * msg.sender直接自己投票提案
     */
    function vote(uint proposal) public {
        Voter storage sender = voters[msg.sender];
        // msg.sender有权重代表着有投票的权利
        require(sender.weight != 0, "Has no right to vote");
        // 确保msg.sender还没投过票
        require(!sender.voted, "Already voted.");
        sender.voted = true;
        // 记录msg.sender所投的提案编号
        sender.vote = proposal;

        // If 'proposal' is out of the range of the array,
        // this will throw automatically and revert all
        // changes.
        // 直接将msg.sender的权重加到编号为proposal的提案的原有得票数上
        proposals[proposal].voteCount += sender.weight;
    }

    /** 
     * @dev Computes the winning proposal taking all previous votes into account.
     * @return winningProposal_ index of winning proposal in the proposals array
     * 选出得票数最高的提案并赋给winningProposal_变量返回
     */
    function winningProposal() public view
            returns (uint winningProposal_)
    {
        uint winningVoteCount = 0;
        for (uint p = 0; p < proposals.length; p++) {
            if (proposals[p].voteCount > winningVoteCount) {
                winningVoteCount = proposals[p].voteCount;
                // 注意返回值变量可以在函数中使用
                winningProposal_ = p;
            }
        }
    }

    /** 
     * @dev Calls winningProposal() function to get the index of the winner contained in the proposals array and then
     * @return winnerName_ the name of the winner
     * 返回获胜提案的名字
     */
    function winnerName() public view
            returns (bytes32 winnerName_)
    {
        winnerName_ = proposals[winningProposal()].name;
    }
}