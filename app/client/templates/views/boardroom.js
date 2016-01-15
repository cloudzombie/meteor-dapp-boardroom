Template['views_boardroom'].rendered = function(){
	Meta.setSuffix(TAPi18n.__("dapp.boardroom.title"));
	
    Meteor.setInterval(function(){
        var sum = function(a, b) { return a + b };     
		var board = Boards.findOne({address: boardroomInstance.address});
		
		if(_.isUndefined(board)
		  || !_.has(board, "numProposals")
		  || !_.has(board, "numExecuted"))
			return;
		
        var data = {
            series: [board.numExecuted, (board.numProposals - board.numExecuted)]
        };
        
        if(board.numProposals == 0)
            data = {
                series: [board.numProposals]
            };

        if(board.numProposals) {
            if($('#proposalsChart').length > 0) {
                new Chartist.Pie('#proposalsChart', data, {
                  donut: true,
                  showLabel: true,
                  labelInterpolationFnc: function(value) {
                    return Math.round(value / data.series.reduce(sum) * 100) + '%';
                  }
                });
            }
        }
    }, 300);
	
	boardroomInstance.addressOfArticle(9, function(err, result){
		console.log(err, result);
	});
};

Template['views_boardroom'].events({
    'click .btn-faucet': function(event, template){
        /*Helpers.post('http://testnet.consensys.net/faucet', {
            address: String(boardroomInstance.address)
        });*/
    },
});

Template['views_boardroom'].helpers({
	'board': function(){		
		return Boards.findOne({address: boardroomInstance.address});	
	},
});