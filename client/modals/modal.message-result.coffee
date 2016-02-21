Template.messageResultModal.events
  'click .continue-play': ->
    $('#message-result-modal').modal 'hide'
    Session.set "gameCurrentAvailable_#{Meteor.userId()}", null
