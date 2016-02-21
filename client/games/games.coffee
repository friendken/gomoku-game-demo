# window.onbeforeunload = ->
#   "Do you really want to close?";

#prepare array to talbe
tableRender = []
@countTurn
tableRender.push i for i in [1...16]

compare = (a, b) ->
  if a.count > b.count
    -1
  else if a.count < b.count
    1
  else
    0

addAnimationSuggest = (position, playerTitle)->
  if playerTitle is 'player1'
    classStep = 'icon-cross'
  else
    classStep = 'icon-radio-unchecked'
  $("[data-col=#{position.col}][data-row=#{position.row}] i").addClass classStep
  $("[data-col=#{position.col}][data-row=#{position.row}]").addClass 'animated bounce'
  @checkSetTimeout = Meteor.setTimeout (->
    $("[data-col=#{position.col}][data-row=#{position.row}] i").removeClass classStep
    $("[data-col=#{position.col}][data-row=#{position.row}]").removeClass 'bounce'
    $("[data-col=#{position.col}][data-row=#{position.row}]").removeClass 'animated'
    ),3000


getReasonableMove = ->
  gameSession = Session.get "gameCurrentAvailable_#{Meteor.userId()}"
  if gameSession
    player = {}
    if gameSession?.player1 is Meteor.userId()
      player['player1'] = Meteor.userId()
      playerTitle = 'player1'
    else
      player['player2'] = Meteor.userId()
      playerTitle = 'player2'

    individualPlayer = _.where gameSession?.steps, player
    allCircumstances = []
    if individualPlayer.length > 0
      _.each individualPlayer, (step) ->
        stepCount = new checkStep step, _.keys(step)[2]
        position = {row: step.row, col: step.col}
        allCircumstances = _.union(allCircumstances,
        	{ name: 'lineLeftToRight', count: stepCount.lineLeftToRight(), position: position },
          { name: 'lineToptoDown', count: stepCount.lineToptoDown(), position: position},
          { name: 'diagonallyRightToLeft', count: stepCount.diagonallyRightToLeft(), position: position},
          { name: 'diagonallyLeftToRight', count: stepCount.diagonallyLeftToRight(), position: position})

      allCircumstances.sort compare
      i = 0
      while i < allCircumstances.length
        checkMove = new checkStep allCircumstances[i].position, playerTitle
        result = checkMove.countMove allCircumstances[i].name
        if result isnt false
          addAnimationSuggest result,playerTitle
          break;
        i++

checkAvailableStep = (step)->
  gameSession = Session.get "gameCurrentAvailable_#{Meteor.userId()}"
  lastStep = gameSession?.steps[gameSession?.steps?.length - 1]
  if lastStep and lastStep[_.keys(lastStep)[2]] is Meteor.userId()
    return false

  if $(step).hasClass('icon-radio-unchecked') or $(step).hasClass('icon-cross')
    if $(step).parent().hasClass "bounce"
      #remove animatiion for all position
      $('.gomoku-cell').removeClass "animated"
      $('.gomoku-cell').removeClass "bounce"
      Meteor.clearTimeout @checkSetTimeout
      return true
    return false
  else
    #remove animatiion for all position
    $('.gomoku-cell.bounce i').attr "class", "action"
    $('.gomoku-cell').removeClass "bounce"
    $('.gomoku-cell').removeClass "animated"
    Meteor.clearTimeout @checkSetTimeout
    return true

checkVistory = (position, player) ->
  session = Session.get "gameCurrentAvailable_#{Meteor.userId()}"
  stepClass = new checkStep(position, player)
  if stepClass.lineLeftToRight() is 5 or stepClass.lineToptoDown() is 5 or stepClass.diagonallyRightToLeft() is 5 or stepClass.diagonallyLeftToRight() is 5
    Meteor.call 'updateGameWinner', Meteor.userId(), session._id, (err, response) ->
      return console.error err if err
  else
    Meteor.setTimeout (->
      Meteor.call 'checkCompetitor', session._id, session[player], (err, response) ->
        return console.error err if err
      ),21000

#************************************************
#********** template game functional ************
#************************************************

Template.games.onRendered ->
  #this autorun will check the game availble for current user
  @autorun ->
    unless Session.get "gameCurrentAvailable_#{Meteor.userId()}"
      Meteor.call "getGameAvailable",(err, game) ->
        return console.error if err
        Session.set "gameCurrentAvailable_#{Meteor.userId()}",game

  #update session of user when there is anything change in game collection
  @autorun ->
    Games.find().fetch()
    Meteor.setTimeout (->
      gameData = Session.get "gameCurrentAvailable_#{Meteor.userId()}"
      game = Games.findOne _id: gameData?._id
      Session.set "gameCurrentAvailable_#{Meteor.userId()}", game
    ),500

  #check result of the game and add animation for last step
  @autorun ->
    session = Session.get "gameCurrentAvailable_#{Meteor.userId()}"
    game = Games.findOne _id: session?._id
    Meteor.clearInterval @countTurn
    $('.title-game h3').text "Gomoku game"
    #check last step and add animation for this step
    lastStep = game?.steps[game?.steps?.length - 1]
    if lastStep and lastStep[_.keys(lastStep)[2]] isnt Meteor.userId()
      $("[data-col=#{lastStep.col}][data-row=#{lastStep.row}] i").addClass 'animated flash'
      $('.button-suggest .btn-primary').attr "disabled", false
      #start count time for user
      unless game.winner
        second = 20
        sefl = @
        @countTurn = Meteor.setInterval (->
          if(second is 0)
            Meteor.clearInterval sefl.countTurn
          $('.title-game h3').text second
          second--
          ), 1000
    else
      $('.button-suggest .btn-primary').attr "disabled", true

    #check result of game
    if game and game?.winner
      if game.winner is Meteor.userId()
        $('#message-result-modal .message').text "Congratulation! You're winner"
      else
        $('#message-result-modal .message').text 'Sorry! you lose'
      $('.button-suggest .btn-primary').attr "disabled", true
      $('#message-result-modal').modal 'show'

Template.games.helpers
  stepOfGame: (col ,row) ->
    available = Session.get "gameCurrentAvailable_#{Meteor.userId()}"
    game = Games.findOne { _id: available?._id }
    checkStep = _.findWhere game?.steps, {row: col, col: row}
    if checkStep
      return if checkStep.player1 then 'icon-cross' else 'icon-radio-unchecked'

  tableRender: ->
    tableRender

  isAvailableGame: ->
    #this helpers will check available game and show content
    available = Session.get "gameCurrentAvailable_#{Meteor.userId()}"
    game = Games.findOne { _id: available?._id }
    if game?.player1 and game?.player2
      true
    else
      false

Template.games.events
  "click .button-suggest .btn-primary": ->
    getReasonableMove()

  "click .gomoku-table span": (event, template) ->
    #check available step
    if checkAvailableStep($(event.currentTarget).find('i')) is false
      return false
    #prepare data for step
    dataStep =
      col: $(event.currentTarget).data 'col'
      row: $(event.currentTarget).data 'row'
    session = Session.get "gameCurrentAvailable_#{Meteor.userId()}"
    game = Games.findOne {_id: session._id}
    if game.player1 is Meteor.userId()
      dataStep.player1 = Meteor.userId()
    else
      dataStep.player2 = Meteor.userId()

    #call the method in server
    $('.gomoku-table .action').removeClass "animated flash"
    Meteor.call 'updateStepGame', session._id, dataStep, (err,response) ->
      return console.error err if err
      checkVistory response.position, response.player
