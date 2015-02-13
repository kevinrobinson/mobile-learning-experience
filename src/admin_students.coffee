$ = require 'jquery'
_ = require 'lodash'
React = require 'react/addons'
dom = React.DOM
Header = require './header.coffee'
Slot = require '../lib/slot.coffee'
stats = require 'stats-lite'

module.exports = AdminPage = React.createClass
  displayName: 'AdminPage'

  propTypes:
    date: React.PropTypes.number.isRequired
    onNavigateTo: React.PropTypes.func.isRequired

  getInitialState: ->
    students: Slot.idle()
    # problems: []
    # problemsRequestState: 'idle'

  componentDidMount: ->
    studentsRequest = $.ajax('/dataset/students', data: date: @props.date)
    @setState students: Slot.pending studentsRequest
    studentsRequest.done (response) => @setState students: Slot.resolved JSON.parse response
    studentsRequest.fail (err) => @setState students: Slot.rejected err

  #   @setState problemsRequestState: 'pending'
  #   $.ajax('/dataset/problems').done(@onProblemsSucceeded)


  # onProblemsSucceeded: (response) ->
  #   @setState
  #     problemsRequestState: 'resolved'
  #     problems: JSON.parse response

  render: ->
    return dom.div null, 'loading...' unless @state.students.state is Slot.States.RESOLVED

    dom.div null,
      Header date: @props.date
      @renderOverallCalibration @state.students.value
      @renderStudents @state.students.value



  # How many students have not done anything?
  # Of the students who have, how
  # How is the class as a whole calibrated for the students?
      # student stats
      # student clustering?
      # -> wholesale curriculum changes
  # What is the engagement dropoff throughout the course, compared to what is typical?
  renderOverallCalibration: (students) ->
    studentsWithAttempts = students.filter (student) -> student.problemsAttempted > 0
    activeAllTimePercentText = Math.round(100 * studentsWithAttempts.length / students.length)
    dom.div null,
      dom.h2 null, 'Overall calibration:'
      dom.div null, 'Enrolled:', students.length
      dom.div null, 'Active (all time):', activeAllTimePercentText + '%'


  # Which problems have been particularly easy or difficult for students, so I can adjust the pace of the course?
  # How many students are able to complete problems without videos?
  # Which problems are students skipping?
  # At the end of the course, what changes should I make for next year?
  renderProblems: ->
  #   return dom.div null, 'loading...' unless @state.problemsRequestState is 'resolved'

  #   dom.div null, 'problems:',
  #   dom.div null, @state.problems.map (problem) ->
  #     dom.pre { key: problem.id }, JSON.stringify problem, null, 2

  # Which videos are the most students watching?
  # Which videos are losing students? (pace isn't calibrated for them)
    # show problem success rate, to get at is video too slow or too fast
  # Which videos lead to the lowest problem success rate? (these videos need work)
  # Which videos are being watched repeatedly (they're highly valuable, or too confusing or too much in one video)
  renderVideos: ->

  # Who is engaged but struggling to complete the course?
      # Which students have the worst ratio of 'effort vs. completed problems`, so I can encourage or look at other interventions?
      # -> *automated nudge*
      # -> teacher reaches out, provides help, additional resources, encourages peer study group
  # Which students are at risk for dropping out from low engagement?
      # -> *automated nudge*
      # -> teacher reaches out, nudge of `not as involved as other students`
  # Which students can I look to as leaders to help other students?
      # -> nudge them to offer help to others
  # Which students should I encourage to take more challenging work?
      # -> nudge them to enroll for next course
  renderStudents: (students) ->
    # TODO(kr) distribution
    # problemsCompletedValues = _.pluck students, 'problemsCompleted'
    # problemsCompletedStats = @computeStats _.pluck students, 'problemsCompleted'


    dom.div null,
      dom.h2 null, 'Students'
      dom.div null,
        dom.h4 null, 'Problems attempted and completed :'
        dom.pre null, JSON.stringify({
          attempted: @computeStats(_.pluck students, 'problemsAttempted')
          completed: @computeStats(_.pluck students, 'problemsCompleted')
          completionPercentage: @computeStats(_.pluck students, 'completionPercentage')
        }, null, 2)
      dom.div null,
        dom.h4 null, 'Problems attempted:'
        dom.pre null, JSON.stringify @computeStats(_.pluck students, 'problemsAttempted'), null, 2
      dom.h4 null, 'Students:'
      dom.div null, _.sortBy(students, (d) -> -1 * d.problemsAttempted).map (student) ->
        dom.div { key: student.studentId },
          dom.a { href: '/students/' + student.studentId }, student.name
          dom.pre { style: marginTop: 0 }, JSON.stringify student, null, 2

  computeStats: (values, options = {}) ->
    filteredValues = if options.includeZeros then values else values.filter (d) -> d isnt 0
    min = Math.min filteredValues...
    max = Math.max filteredValues...

    count: values.length
    zeros: values.length - filteredValues.length
    range: [min, max]
    mean: stats.mean filteredValues
    variance: stats.variance filteredValues
    percentiles:
      p0: min
      p25: stats.percentile filteredValues, 0.25
      p50: stats.percentile filteredValues, 0.50
      p75: stats.percentile filteredValues, 0.75
      p90: stats.percentile filteredValues, 0.90
      p95: stats.percentile filteredValues, 0.95
      p99: stats.percentile filteredValues, 0.99
      p100: max

