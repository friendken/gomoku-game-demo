Meteor.methods
  checkCompetitor: (gameId, userId) ->
    game = Games.findOne {_id: gameId}
    if new Date().getTime() -  new Date(game.updatedAt).getTime() > 20000
      Meteor.call "updateGameWinner", userId, gameId


  #this function use to update the winner for game
  updateGameWinner: (userId, gameId)->
    Games.update { _id: gameId }, $set:
      winner: userId
      status: 'finish'

  #this function will update the step of game
  updateStepGame: (gameId, dataStep) ->
    game = Games.findOne _id: gameId
    if game?.steps.length is 0
      #if there is no step already just update normal
      Games.update { _id: gameId },
        $push: steps: dataStep
        $set: updatedAt: new Date
    else
      previousPlayer = _.keys(game.steps[game.steps.length - 1])?[2]
      currentPlayer = _.keys(dataStep)?[2]
      #check previous step of player with current step of player
      if previousPlayer isnt currentPlayer
        existStep = _.findWhere game.steps, {row: dataStep.row, col: dataStep.col}
        #check if the step is already
        unless existStep
          Games.update { _id: gameId },
            $push: steps: dataStep
            $set: updatedAt: new Date

    {
      position:
        row: dataStep.row
        col: dataStep.col
      player: currentPlayer
    }

  #this function will check the availble game or insert new game for user
  getGameAvailable: ->
    if Meteor.userId()
      game = Games.findOne
              $or: [
                { player1: Meteor.userId() }
                { player2: Meteor.userId() }
              ]
              $and: [ { status: 'waiting' } ]
      unless game
        availbleGame = Games.findOne $or: [
                          { player1: $exists: false }
                          { player2: $exists: false }
                        ]
        if availbleGame
          gameId = availbleGame._id
          dataUpdate =
            status: 'playing'
          unless availbleGame?.player1
            dataUpdate.player1 = Meteor.userId()
          else
            dataUpdate.player2 = Meteor.userId()

          Games.update { _id: gameId }, $set: dataUpdate
        else
          gameId = Games.insert
                    player1: Meteor.userId()
                    status: 'waiting'
                    steps: []
                    createdAt: new Date()

        return Games.findOne {_id: gameId}
      return game
