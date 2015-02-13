$ = require 'jquery'
_ = require 'lodash'
React = require 'react/addons'
dom = React.DOM
RouteParser = require '../lib/route_parser.coffee'
RouteListener = require '../lib/route_listener.coffee'
AdminStudentsPage = require './admin_students.coffee'
StudentPage = require './student_page.coffee'


UI = React.createClass
  routeMap:
    '/students/:studentId': 'student'
    '/problems/:problemId': 'problem'
    '/admin/students': 'admin_students'
    '/admin': 'admin_students'
    '/(.*)': 'admin_students'

  readRoutingState: ->
    RouteParser.route @routeMap, RouteParser.readPathFromBrowser useHistory: true

  getInitialState: ->
    routing: @readRoutingState()
    date: 20181001

  componentWillMount: ->
    @_routeListener = RouteListener => @setState routing: @readRoutingState()

  componentDidUnmount: ->
    @_routeListener.stop()

  componentDidUpdate: (nextProps, nextState) ->
    if not _.isEqual nextState.routing, @state.routing
      @browserPushState routeKey, urlParams

  onNavigateTo: (routeKey, urlParams = {}) ->
    @setState routing: {routeKey, urlParams}

  browserPushState: (routeKey, urlParams = {}) ->
    replaceStatePath = switch routeKey
      when 'admin_students' then '/admin/students'
      when 'student' then "/students/#{urlParams.studentId}"
      when 'problem' then "/problems/#{urlParams.problemId}"
      else '/404'

    window.history.pushState {}, window.document.title, replaceStatePath

  render: ->
    dom.div { onClick: @onClick },
      switch @state.routing.routeKey
        when 'admin_students' then AdminStudentsPage
          onNavigateTo: @onNavigateTo
          date: @state.date
        when 'student' then StudentPage
          onNavigateTo: @onNavigateTo
          date: @state.date
          studentId: @state.routing.urlParams.studentId
        when 'problem' then dom.div null, 'problem: ' + @state.routing.urlParams.problemId
        else dom.div null, 'not found'


# Startup
main = ->
  # for debugging only
  _.extend window, {_, $, React}

  appEl = document.querySelector '#app'
  React.renderComponent UI(), appEl



main()