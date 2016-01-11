contract BoardRoom {
	function amendConstitution(uint _article, address _addr){}
	function transfer_ownership(address _addr) {}
	function disolve(address _addr) {}
	function forward(address _destination, uint _value, bytes _transactionBytecode) {}
	function forward_method(address _destination, uint _value, bytes4 _methodName, bytes32[] _transactionData) {}
	
	function addressOfArticle(uint _article) constant returns (address) {}
	function implementer() constant returns (address) {}
}

contract VotingSystem {    
	function canTable(address _board, uint _kind, address _member) constant returns (bool) {}
	function canVote(address _board, uint _proposalID, address _member) constant returns (bool) {}
	function canExecute(address _board, uint _proposalID, address _member) constant returns (bool) {}
}

contract ProcessingSystem {
    function methodName(uint _kind) public constant returns (bytes4) {}
    function expectedDataLength(uint _kind) public constant returns (uint) {}
}

contract ProposalSystem {
	enum DefaultArticles {Proposals, Processor, Voting, Membership, Delegation, Token, Family, Chair, Executive}
	
	struct Proposal {
        string name;
        address from;
        uint kind;
		
        bytes32[] data;
        address[] addr;
        uint[] value;
		
        Vote[] votes;
		uint totalVotes;
        mapping(address => bool) voted;
		mapping(address => uint) toID;
		
        uint executed;
        uint created;
    }
	
	struct Vote {
		uint position;
		address member;
	}
    
	event Tabled(address indexed _board, uint indexed _proposalID, address _member);
	event Executed(address indexed _board, uint indexed _proposalID, address _member);
	event Voted(address indexed _board, uint indexed _proposalID, address _member);
	
    mapping(address => uint) public numExecuted;
    mapping(address => uint) public numProposals;
    mapping(address => mapping(uint => Proposal)) public proposals;
	
	function vote(address _board, uint _proposalID, uint _position) public returns (uint voteID) {
		if(!VotingSystem(BoardRoom(_board).addressOfArticle(uint(DefaultArticles.Voting))).canVote(_board, _proposalID, msg.sender))
			throw;
			
        Proposal p = proposals[_board][_proposalID];
			
		p.totalVotes++;
		voteID = p.votes.length++;
		p.votes[voteID] = Vote({position: _position, member: msg.sender});
		p.voted[msg.sender] = true;
		p.toID[msg.sender] = voteID;
		
		Voted(_board, _proposalID, msg.sender);
	}
	
	function table(address _board, string _name, uint _kind,
				bytes32[] _data, uint[] _value, address[] _addr) public {			
		if(!VotingSystem(BoardRoom(_board).addressOfArticle(uint(DefaultArticles.Voting))).canTable(_board, _kind, msg.sender)
			|| _addr.length != _value.length)
			throw;
			
		uint proposalID = numProposals[_board]++;
        Proposal p = proposals[_board][proposalID];
        p.name = _name;
        p.data = _data;
        p.kind = _kind;
        p.addr = _addr;
        p.from = msg.sender;
        p.value = _value;
        p.created = now;
		
        Tabled(_board, proposalID, msg.sender);
    }
	
	function execute(address _board, uint _proposalID, bytes _transactionBytecode, uint _blockNumber) public {
        Proposal p = proposals[_board][_proposalID];
		
		if(p.executed == 0) {
			if(!VotingSystem(BoardRoom(_board).addressOfArticle(uint(DefaultArticles.Voting))).canExecute(_board, _proposalID, msg.sender))
				throw;
		}
		
		if(p.data[_blockNumber] != sha3(_board, _proposalID, _transactionBytecode)
			|| (_blockNumber != p.executed)
			|| (_blockNumber >= p.data.length))
			throw;
		
		if(_blockNumber == p.data.length - 1)
			numExecuted[_board] += 1;
			
		p.executed = _blockNumber + 1;
		BoardRoom(_board).forward(p.addr[_blockNumber], p.value[_blockNumber], _transactionBytecode);
        Executed(_board, _proposalID, msg.sender);
	}
	
    
    function checkProposalCode(address _board, uint _proposalID, bytes _transactionBytecode, uint _blockNumber) public constant returns (bool) {
        Proposal p = proposals[_board][_proposalID];
        
        if(p.data[_blockNumber] == sha3(_board, _proposalID, _transactionBytecode))
            return true;
    }
	
	function tabledBy(address _board, uint _proposalID) public constant returns (address) {
        Proposal p = proposals[_board][_proposalID];
        
        return p.from;
	}
    
    function kindOf(address _board, uint _proposalID) public constant returns (uint) {
        Proposal p = proposals[_board][_proposalID];
        
        return p.kind;
    }
	
    
    function dataAt(address _board, uint _proposalID, uint _index) public constant returns (bytes32) {
        Proposal p = proposals[_board][_proposalID];
        
        return p.data[_index];
    }
    
    function addressAt(address _board, uint _proposalID, uint _index) public constant returns (address) {
        Proposal p = proposals[_board][_proposalID];
        
        return p.addr[_index];
    }
    
    function valueAt(address _board, uint _proposalID, uint _index) public constant returns (uint) {
        Proposal p = proposals[_board][_proposalID];
        
        return p.value[_index];
    }
	
		
	function createdAt(address _board, uint _proposalID) public constant returns (uint) {
		Proposal p = proposals[_board][_proposalID];
        
        return p.created;
	}
	
	function isExecuted(address _board, uint _proposalID) public constant returns(uint) {
        Proposal p = proposals[_board][_proposalID];
        
        return p.executed;
	}
    
	function voteCountOf(address _board, uint _proposalID) public constant returns (uint){
		Proposal p = proposals[_board][_proposalID];
		
		return p.totalVotes;
	}
	
    function positionOf(address _board, uint _proposalID, uint _voteID) public constant returns (uint) {
        Proposal p = proposals[_board][_proposalID];
        
        return p.votes[_voteID].position;
    }
    
    function memberOf(address _board, uint _proposalID, uint _voteID) public constant returns (address) {
        Proposal p = proposals[_board][_proposalID];
        
        return p.votes[_voteID].member;
    }
    
    function idOf(address _board, uint _proposalID, address _member) public constant returns (uint) {
        Proposal p = proposals[_board][_proposalID];
        
        return p.toID[_member];
    }
    
    function hasVoted(address _board, uint _proposalID, address _member) public constant returns (bool) {
        Proposal p = proposals[_board][_proposalID];
        
        return p.voted[_member];
    }
	
	
	function numValuesIn(address _board, uint _proposalID) public constant returns (uint) {
        Proposal p = proposals[_board][_proposalID];
		
		return p.value.length;	
	}
	
	function numDataIn(address _board, uint _proposalID) public constant returns (uint) {
        Proposal p = proposals[_board][_proposalID];
		
		return p.data.length;
	}
	
	function numAddressesIn(address _board, uint _proposalID) public constant returns (uint) {
        Proposal p = proposals[_board][_proposalID];
		
		return p.addr.length;
	}
}