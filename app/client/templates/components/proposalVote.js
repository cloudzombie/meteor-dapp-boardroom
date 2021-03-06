var transactionObject,
	proposal;

Template['components_proposalVote'].rendered = function(){
    TemplateVar.set(this, 'state', {});
	proposal = Proposals.findOne({boardroom: boardroomInstance.address, id: objects.params._proposal});
	
    Meteor.setInterval(function(){
        var sum = function(a, b) { return a + b };  
		
		if(_.isUndefined(proposal) || !_.has(proposal, 'numFor'))
			return;
		
        var data = {
                series: [proposal.numFor, proposal.numAgainst]
            };
		
		if(proposal.numFor == 0 && proposal.numAgainst == 0)
			data.series.push(1);
        
		if ($("#proposalChart").length > 0){
			new Chartist.Pie('#proposalChart', data, {
			  labelInterpolationFnc: function(value) {
				return Math.round(value / data.series.reduce(sum) * 100) 
					+ '%';
			  }
			});
		}
    }, 300);
};

Template['components_proposalVote'].events({
    'click .btn-vote-for': function(event, template){
        objects.defaultComponents.Proposals.vote.sendTransaction(boardroomInstance.address, objects.params._proposal, 1,
                                {from: web3.eth.defaultAccount,
                                gas: 3000000}, 
                                function(err, result){
            if(err)
                return TemplateVar.set(template, 'state', {isError: true, error: String(err)});
			
        	TemplateVar.set(template, 'state', {isMining: true, transactionHash: result});
        });
		
		objects.defaultComponents.Proposals.Voted({_board: boardroomInstance.address, _proposalID: objects.params._proposal, _member: web3.eth.defaultAccount}, function(err, result){
			if(err)
				return TemplateVar.set(template, 'state', {isError: true, error: String(err)});
			
        	TemplateVar.set(template, 'state', {isVoted: true, transactionHash: result.transactionHash});
			
			web3.eth.getTransactionReceipt(result.transactionHash, function(err, txResult){
				TemplateVar.set(template, 'state', {isVoted: true, address: result.address, transactionHash: txResult.transactionHash, cumulativeGasUsed: txResult.cumulativeGasUsed});
			});
		});
    },
    
    'click .btn-vote-against': function(event, template){
        objects.defaultComponents.Proposals.vote.sendTransaction(boardroomInstance.address, objects.params._proposal, 0,
                                {from: web3.eth.defaultAccount,
                                gas: 3000000}, 
                                function(err, result){
            if(err)
                return TemplateVar.set(template, 'state', {isError: true, error: String(err)});
			
        	TemplateVar.set(template, 'state', {isMining: true});
        });
    },
    
    'click .btn-delegate': function(event, template){
		var delegationAddress = $('#delegation-address').val();
        
        objects.defaultComponents.Delegation.delegate.sendTransaction(boardroomInstance.address, objects.params._proposal, delegationAddress, 
                                    {from: web3.eth.defaultAccount,
									 gas: 3000000}, 
                               function(err, result){
            if(err)
                return TemplateVar.set(template, 'state', {isError: true, error: String(err)});
			
        	TemplateVar.set(template, 'state', {isMining: true});
        });
    },
    
    'click .btn-execute': function(event, template){
		proposal = Proposals.findOne({boardroom: boardroomInstance.address, id: objects.params._proposal});
		
		if(_.isUndefined(proposal))
			throw "proposal not defined";
		
		for(var block_number = 0; block_number < proposal.numAddresses; block_number++){	
			var bytecode = '0x' + proposal.ipfsData.blocks[block_number].bytecode; // PROBLEM HERE!
			
			objects.defaultComponents.Proposals.execute.sendTransaction(boardroomInstance.address, objects.params._proposal, bytecode,
										{from: web3.eth.defaultAccount,
										 gas: 3000000},
								   function(err, result){
				if(err)
					return TemplateVar.set(template, 'state', {isError: true, error: String(err)});

				TemplateVar.set(template, 'state', {isMining: true});
			});
		}
    },
});

Template['components_proposalVote'].helpers({
    'refresh': function(){
        TemplateVar.set('state', {});
    },
	
	'registeredMembers': function(){
		return Members.find({boardroom: boardroomInstance.address});
	},
    
    'update': function(){   
    },
});