# Description:
#
# Dependencies:
#
# Configuration:
#
# Commands:
#
# Author:
#   Ria Scarlet

module.exports = (robot) ->

  robot.on "ria_code_1a1ee189", (msg) ->
    msg.send 'hihi'

  robot.respond /hahi/, (msg) ->
    return unless '100008976948319' == msg.message.user.id
    room_states.set state: "d6e25f0b", msg.message.room

  robot.on "room_state_handler_message_d6e25f0b", (msg, state) ->
    return unless '100008976948319' == msg.message.user.id
    return robot.emit "room_state_handler_message_default" unless msg.match = msg.message.match robot.respondPattern /hehe/
    robot.emit "ria_code_1a1ee189", msg
