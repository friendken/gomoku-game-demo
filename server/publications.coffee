Meteor.publish "users", ->
  Meteor.users.find()

Meteor.publish "games", ->
  Games.find()
