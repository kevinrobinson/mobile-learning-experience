# Hacking, just playing around.  Should use a real router,
# but I want one that I can `start`, `stop` and give a callback to,
# and doesn't muck with the components.
pathToRegexp = require 'path-to-regexp'
urllite = require 'urllite/lib/core'


module.exports =
  route: (routeMap, path) ->
    # Match URL path to route
    urlParamKeys = []
    for routePath, routeKey of routeMap
      pathRegex = pathToRegexp routePath, urlParamKeys
      matchInfo = pathRegex.exec path
      break if matchInfo?

    # Transform to a useful form
    return undefined unless matchInfo?
    urlParams = {}
    matchInfo.slice(1).forEach (urlParamValue, index) ->
      paramName = urlParamKeys[index].name
      urlParams[paramName] = urlParamValue

    {routeKey, urlParams}

  readPathFromBrowser: (options = {}) ->
    url = urllite window.location.href
    hash = url.hash ? ''
    path = if options.useHistory then url.pathname else '/' + hash.slice 1
    path = '/' if path.length is 0

    path + url.search