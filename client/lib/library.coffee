#this class use to check position of step of user
class @checkStep
  constructor: (position, player) ->
    @position = position
    @player = player
    @classObject =
      player1: 'icon-cross'
      player2: 'icon-radio-unchecked'
    @convertCase =
      lineLeftToRight: ['case7', 'case8']
      lineToptoDown: ['case5', 'case6']
      diagonallyRightToLeft: ['case3', 'case4']
      diagonallyLeftToRight: ['case1', 'case2']

  diagonallyLeftToRight: ->
    return @countStep 'case1', 'case2'

  diagonallyRightToLeft: ->
    return @countStep 'case3', 'case4'

  lineToptoDown: ->
    return @countStep 'case5', 'case6'

  lineLeftToRight: ->
    return @countStep 'case7', 'case8'

  countStep: (condition1, condition2)->
    previousPosition = @getNewPosition {row: @position.row, col: @position.col}, condition1
    count1 = @positionRecursion previousPosition, @player, 0, condition1

    nextPosition = @getNewPosition {row: @position.row, col: @position.col}, condition2
    count2 = @positionRecursion nextPosition, @player, 0, condition2
    return count1 + count2 + 1

  positionRecursion: (position, player, count, condition) ->
    if $("[data-col=#{position.col}][data-row=#{position.row}] i").hasClass(@classObject[player])
      newPosition = @getNewPosition position, condition
      count++
      @positionRecursion newPosition, player, count, condition
    else
      return count

  countMove:(type) ->
    circumstances = @convertCase[type]
    previousPosition = @getNewPosition {row: @position.row, col: @position.col}, circumstances[0]
    firstCase = @moveRecursion previousPosition, @player, circumstances[0]

    if firstCase is false
      nextPosition = @getNewPosition {row: @position.row, col: @position.col}, circumstances[1]
      secondCase = @moveRecursion nextPosition, @player, circumstances[1]
      return secondCase
    else
      return firstCase

  moveRecursion: (position, player, condition) ->
    if $("[data-col=#{position.col}][data-row=#{position.row}] i").hasClass(@classObject[player])
      newPosition = @getNewPosition position, condition
      @moveRecursion newPosition, player, condition
    else
      if player is 'player1'
        findClass = @classObject['player2']
      else
        findClass = @classObject['player1']

      if $("[data-col=#{position.col}][data-row=#{position.row}] i").hasClass(findClass)
        return false
      else
        position

  getNewPosition: (position, condition)->
    switch condition
      when 'case1'
        position.row -= 1
        position.col -= 1
      when 'case2'
        position.row += 1
        position.col += 1
      when 'case3'
        position.row -= 1
        position.col += 1
      when 'case4'
        position.row += 1
        position.col -= 1
      when 'case5'
        position.row -= 1
      when 'case6'
        position.row += 1
      when 'case7'
        position.col -= 1
      when 'case8'
        position.col += 1
    return position
