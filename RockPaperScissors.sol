// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract GanFan {
    // 玩家结构体
    struct Player {
        uint8 choice; // 玩家的选择（0 = 石头，1 = 剪刀，2 = 布）
        bool played; // 玩家是否已经玩了游戏
        address Address; //玩家的地址
    }
    // 游戏状态
    enum State {
        Waiting, // 等待玩家加入游戏
        Playing, // 玩家正在玩游戏
        Finished // 游戏已经结束
    }
    // 游戏结构体
    struct Game {
        Player[2] players; // 游戏中的玩家
        State state; // 游戏状态
        address winner; // 获胜者的地址
    }

    Game public game;
    struct Voter
    {
        uint VoteChance;    //投票者的票数
        bool GetTicket;     //是否已经得到初始票
        uint Weight;        //投票者的权重
    }
    struct Restaurant
    {
        uint Ticket;    //餐馆的得票数
        uint Funds;     //餐馆的资金
        uint Number;    //餐馆的编号
    }
    Restaurant[5] restaurant;   //有五家餐馆可供选择
    mapping(address => Voter) public voters;    //将投票者的地址和投票者绑定

    // 玩家加入游戏
    function joinGame(uint8 _choice) public {
        require(game.state == State.Waiting, "Game already started.");
        require(_choice == 0 || _choice == 1 || _choice == 2, "Invalid choice.");

        if (!game.players[0].played) {
            game.players[0].choice = _choice;
            game.players[0].played = true;
            game.players[0].Address = msg.sender;
        } else if (!game.players[1].played) {
            game.players[1].choice = _choice;
            game.players[1].played = true;
            game.players[1].Address = msg.sender;
            game.state = State.Playing;

            // 计算获胜者
            uint8 winnerChoice = (game.players[0].choice + 3 - game.players[1].choice) % 3;
            Voter storage sender_1=voters[game.players[0].Address];
            Voter storage sender_2=voters[game.players[1].Address];
            if (winnerChoice == 2) {
                game.winner = game.players[0].Address; // 第一个玩家获胜
                game.state = State.Finished;
                sender_1.Weight+=1;
            } else if (winnerChoice == 0) {
                game.winner = address(0x0); // 平局
                game.state = State.Finished;
            } else {
                game.winner = game.players[1].Address; // 第二个玩家获胜
                game.state = State.Finished;
                sender_2.Weight+=1;
            }
        } else {
            revert("Game is full.");
        }
    }

    // 获取玩家的选择
    function getChoice(uint8 _player) public view returns (uint8) {
        require(game.state == State.Finished, "Game not yet finished.");
        require(_player == 0 || _player == 1, "Invalid player.");

        return game.players[_player].choice;
    }

    // 获取获胜者的地址
    function getWinner() public view returns (address) {
        require(game.state == State.Finished, "Game not yet finished.");

        return game.winner;
    }

    // 重新开始游戏
    function restartGame() public {
        require(game.state == State.Finished, "Game not yet finished.");

        // 重置游戏状态
        game.players[0].choice = 0;
        game.players[0].played = false;
        game.players[1].choice = 0;
        game.players[1].played = false;
        game.state = State.Waiting;
    }

    //初始化投票者，投票者得到一张初始票
    function GetTickets() public {
        Voter storage sender=voters[msg.sender];
        require(sender.GetTicket!=true,"You have got ticket");
        sender.VoteChance=1;
        sender.GetTicket=true;
    }
    //进行投票，选择餐厅序号，票数，资金
    function Vote(uint Number,uint Ticket) public{
        Voter storage sender=voters[msg.sender];
        require(Ticket<=sender.VoteChance,"Do not have so much tickets");
        restaurant[Number].Ticket+=Ticket;
    }
    //将自己的票交给其他人
    function Delegate(address to) public{
        Voter storage sender=voters[msg.sender];
        require(sender.VoteChance>0,"You have no chance to vote");
        require(to!=msg.sender,"Self-Delegate is not allowed");
        Voter storage delegate_=voters[to];
        delegate_.VoteChance+=sender.VoteChance;
        sender.VoteChance=0;
    }
    function FinalChoice() public view returns (uint Place,uint Fund_Per_Person)
    {
        uint Max_Ticket=0;
        uint Max_Funds=0;
        uint Ticket_number=0;
        uint Total_funds=0;
        for(uint i=0;i<5;i++)
        {
            Ticket_number+=restaurant[i].Ticket;
            Total_funds+=restaurant[i].Funds;
            if(restaurant[i].Funds>Max_Funds)
            {
                Max_Funds=restaurant[i].Funds;
                Max_Ticket=restaurant[i].Ticket;
                Place=i;
            }
            else if(restaurant[i].Funds==Max_Funds)
            {
                if(restaurant[i].Ticket>Max_Ticket)
                {
                    Max_Ticket=restaurant[i].Ticket;
                    Place=i;
                }
            }
        }
        Fund_Per_Person=Total_funds/Ticket_number;
    }
}
