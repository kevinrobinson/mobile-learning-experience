###
slot =
  {'idle'}
  {'pending'|promise|abort}
  {'resolved'|value}
  {'rejected'|error}
###
module.exports = class Slot
  @States:
    IDLE: 'idle'
    PENDING: 'pending'
    RESOLVED: 'resolved'
    REJECTED: 'rejected'

  @idle: ->
    state: Slot.States.IDLE

  @pending: (jqXhr) ->
    state: Slot.States.PENDING
    promise: jqXhr.promise
    abort: jqXhr.abort

  @resolved: (value) ->
    state: Slot.States.RESOLVED
    value: value

  @rejected: (error) ->
    state: Slot.States.REJECTED
    error: error
