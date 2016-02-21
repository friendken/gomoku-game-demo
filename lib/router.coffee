Router.configure
  layoutTemplate : 'layout'
  waitOn: ->
    Meteor.subscribe "users"
    Meteor.subscribe "games"

Router.map ->
  @route 'games',
    path:'/'
