# For listening to route changed events in the browser.
module.exports = (onRouteChanged, options = {}) ->
  eventName = if options.useHistory then 'popstate' else 'hashchange'
  window.addEventListener eventName, onRouteChanged, false

  stop = -> window.removeEventListener eventName, onRouteChanged

  {stop}