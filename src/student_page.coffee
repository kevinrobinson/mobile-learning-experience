$ = require 'jquery'
_ = require 'lodash'
React = require 'react/addons'
dom = React.DOM
merge = (objs...) -> _.extend {}, objs...
Header = require './header.coffee'
Slot = require '../lib/slot.coffee'
moment = require '../vendor/moment'

###
FOCUS to LEARN:
  next step
    what do i do next?
  how far along in course:
    should i keep working?
    how close am i to achieving something?
  fellow learners:
    interesting threads about the course?
###

# finish something you're almost done with!
# entice to start new subject, show them why
# advice

# let users add their own reward images into the pool


colors =
  darkGreen: '#008800'
  darkRed: 'darkred'

styles =
  section:
    margin: 5
    marginTop: 15
    marginBottom: 15
  panel:
    display: 'inline-block'
    verticalAlign: 'top'
    background: '#e9afc9'
    borderTop: '1px solid #F4C7DB'
  plainList:
    marginTop: 5
  button:
    display: 'inline-block'
    padding: 5
    marginLeft: 10


module.exports = StudentPage = React.createClass
  propTypes:
    studentId: React.PropTypes.string.isRequired
    date: React.PropTypes.number.isRequired
    onNavigateTo: React.PropTypes.func.isRequired

  getInitialState: ->
    student: Slot.idle()
    problems: Slot.idle()
    studentAggregates: Slot.idle()
    nextStep: null
    progress: null
    classmates: [
      { name: 'Jen', email: 'kevin@foo.com', tease: 'working on p123' }
      { name: 'Melissa', email: 'melissa@foo.com', tease: 'finished p123' }
      { name: 'Dan', email: 'dan@foo.com', tease: 'watching v678' }]
    advice: null

  componentDidMount: ->
    @requestStudentData()
    @requestCourseData()
    @requestStudentAggregates()

  # TODO(kr) This is sloppy
  setSlotState: (stateKey, jqXhr) ->
    obj = {}
    obj[stateKey] = Slot.pending jqXhr
    @setState studentAggregates: Slot.pending jqXhr
    jqXhr.done (response) =>
      obj[stateKey] = Slot.resolved JSON.parse response
      @setState obj
    jqXhr.fail (err) =>
      obj[stateKey] = Slot.rejected err
      @setState obj
    undefined

  requestStudentData: ->
    @setSlotState 'student', $.ajax('/dataset/student', data: date: @props.date, studentId: @props.studentId)
    undefined

  requestStudentAggregates: ->
    @setSlotState 'studentAggregates', $.ajax('/dataset/student_aggregates', data: date: @props.date)
    undefined

  requestCourseData: ->
    @setSlotState 'problems', $.ajax('/dataset/problems', data: date: @props.date)
    undefined

  isAllDataLoaded: ->
    return false unless @state.student.state is Slot.States.RESOLVED
    return false unless @state.problems.state is Slot.States.RESOLVED
    return false unless @state.studentAggregates.state is Slot.States.RESOLVED
    true

  render: ->
    return dom.div null, 'loading...' unless @isAllDataLoaded()

    dom.div { style: width: '100%' },
      Header date: @props.date
      @renderPanel @renderNextStepWithFinishAdvice()
      # @renderPanel @renderNextStep()
      @renderPanel @renderProgress()
      # @renderPanel @renderProblems()
      # @renderPanel @renderVideoProgress()
      @renderPanel @renderTimeRhythm()
      @renderPanel @renderFellowLearners()
      @renderPanel @renderRanks()
      @renderPanel @renderCompareMe()
      dom.div { style: merge(styles.panel, background: 'lightblue') },
        @renderAdvice()

  renderPanel: (child) ->
    dom.div { style: merge(styles.panel, width: '100%') },
      dom.div { style: padding: 5 }, [child]

  renderProblemButton: (problemId) ->
    dom.button {
        href: '/problem/' + problemId
        style: styles.button
        onClick: => @props.onNavigateTo 'problem', {problemId}
      }, '#' + problemId

  renderNextStep: ->
    problemsCompleted = 10
    problemsTotal = 13
    problemsLeft = [
      @renderProblemButton('p123')
      dom.span null, '#p124'
      dom.span null, '#p125'
    ]
    subSectionText = "Week 1, Lecture 4"
    percentCompleted = problemsCompleted / problemsTotal

    dom.section { style: styles.section },
      dom.div { style: marginBottom: 15 }, "You're only " + problemsLeft.length + " problems away from finishing subsection " + subSectionText + "!"
      dom.div null, problemsLeft.map (renderedProblem) ->
        dom.div { style: margin: 4, display: 'inline-block' }, renderedProblem


  # curl -e http://www.my-ajax-site.com 'https://ajax.googleapis.com/ajax/services/search/images?v=1.0&q=teacher%20cat'
  # with `dog professor` for tough love advice
  renderNextStepWithFinishAdvice: ->
    dom.section { style: styles.section },
      dom.img {
        src: 'https://www.classwallet.com/wp-content/uploads/2014/11/cat8-300x295.jpeg'
        style:
          width: '100%'
          marginBottom: 20
          display: 'block'
      }
      dom.span null, @state.student.value.name + ', finish off this section!'
      @renderProblemButton('p123')

  renderProgress: ->
    student = @state.student.value
    percentCompleted = Math.round(100 * student.problemsCompleted / @state.problems.value.length)
    {subSectionsCompleted, percentSubSectionsCompleted} = @computeProgressBySubSections()

    dom.section { style: styles.section },
      dom.div { style: marginBottom: 15 }, @state.student.value.name + ", you've finished " + student.problemsCompleted + " problems in this course, and " + subSectionsCompleted + " subsections."
      @renderBar percentCompleted
      @renderBar percentSubSectionsCompleted

  renderBar: (percentCompleted) ->
    dom.div {
        style:
          width: '95%'
          margin: '2%'
          border: '1px solid #ccc'
          background: 'rgb(213, 237, 213)'
      },
        dom.div {
          style:
            fontSize: 10
            padding: 4
            color: 'white'
            textAlign: 'right'
            width: percentCompleted + '%'
            background: colors.darkGreen
        }, percentCompleted + '%'

  # TODO(kr) hacking
  timeAgoString: (momentUtc) ->
    year = @props.date.toString().slice(0, 4)
    month = @props.date.toString().slice(4, 6)
    day = @props.date.toString().slice(6, 8)
    agoText = momentUtc.from(moment.utc("#{year}-#{month}-#{day}"))

    # remind of day of week if it wasn't today
    if agoText.indexOf('seconds') isnt -1
      agoText
    else if agoText.indexOf('minutes') isnt -1
      agoText
    else
      agoText + ' ' + momentUtc.format('dddd')

  inferCourseSequenceNumber: (section, subSection) ->
    sectionNumber = section.match(/week\s(\d*)/i)[1]
    subSectionNumber = subSection.match(/lecture\s(\d*)/i)[1]
    1000 * sectionNumber + subSectionNumber

  # Determine what's the `next` problem for the student to work on.
  # Any past problems they still haven't mastered?
  # based on problem attempts
  inferCurrentSubSection: ->
    problemAttempts = @state.student.value.problemAttempts
    problemsCompleted = problemAttempts.filter (attempt) ->
      Number(attempt.score) is Number(attempt.maxPoints)

    # use courseSequence as a tie-breaker, since `dateAttempted` is not high enough resolution
    # really want a timestamp here instead.
    lastProblemCompletedByDate = _.max problemsCompleted, (attempt) =>
      dateAttempted = Number(attempt.dateAttempted.replace(/-/g, ''))
      courseSequenceNumber = @inferCourseSequenceNumber attempt.section, attempt.subSection
      dateAttempted * 100000000 + courseSequenceNumber
    lastProblemCompletedByCourseSequence = _.max problemsCompleted, (attempt) =>
      @inferCourseSequenceNumber attempt.section, attempt.subSection

    {lastProblemCompletedByDate, lastProblemCompletedByCourseSequence}

  computeProgressBySubSections: ->
    allSubSections = @state.problems.value.map (problem) -> [problem.section, problem.subSection]
    sortedSubSections = _.sortBy _.uniq(allSubSections, (tuple) -> tuple.join '_'), (tuple) =>
      @inferCourseSequenceNumber tuple[0], tuple[1]
    {lastProblemCompletedByDate, lastProblemCompletedByCourseSequence} = @inferCurrentSubSection()
    studentCurrentIndex = _.findIndex sortedSubSections, (tuple) ->
      lastProblemCompletedByCourseSequence.section is tuple[0] and lastProblemCompletedByCourseSequence.subSection is tuple[1]
    subSectionsCompleted = studentCurrentIndex + 1
    percentSubSectionsCompleted = Math.round(100 * subSectionsCompleted / sortedSubSections.length)

    {subSectionsCompleted, percentSubSectionsCompleted}


    # dom.div null,
    #   dom.pre null, JSON.stringify @inferCurrentSubSection(), null, 2
    #   dom.pre null, JSON.stringify {studentCurrentIndex,percentSubSectionsCompleted, count: sortedSubSections.length}, null, 2
    #   dom.pre null, JSON.stringify {studentCurrentIndex, sortedSubSections}, null, 2
    # {lastProblemCompletedByDate, lastProblemCompletedByCourseSequence} = @inferCurrentSubSection()

    # dom.section { style: styles.section },
    #   dom.span null, "You've worked on " + student.problemsCompleted + " problems in this course."
    #   dom.div {
    #     style:
    #       width: '95%'
    #       margin: '2%'
    #       border: '1px solid #ccc'
    #       background: 'rgb(213, 237, 213)'
    #   },
    #     dom.div {
    #       style:
    #         fontSize: 10
    #         padding: 4
    #         color: 'white'
    #         textAlign: 'right'
    #         width: percentCompleted + '%'
    #         background: colors.darkGreen
    #     }, percentCompleted + '%'

  # Really, we don't care about this.
  # We care about completed problems.
  # If there are any problems not completed, then the videos can be a possible next step.
  renderVideoProgress: ->
    videoViews = @state.student.value.videoViews
    viewsBySubSection = _.groupBy videoViews, (videoView) -> videoView.section + '_' + videoView.subSection
    viewsList = []
    for compositeKey, views of viewsBySubSection
      [section, subSection] = compositeKey.split '_'
      viewsList.push {section, subSection, views}

    dom.pre null, JSON.stringify viewsList, null, 2

  renderTimeRhythm: ->
    student = @state.student.value
    targetPerDay = 120

    # TODO(kr) this is a mess
    timePerDay = _.sortBy(student.minutesPerDay, (d) -> -1 * Number(d.date.replace(/-/g,'')))
    truncatedTimePerDay = _.first timePerDay, 5

    # for showing gaps between practice days
    # timePerDayMap = {}
    # timePerDay.forEach (tpd) -> timePerDayMap[Number(tpd.date.replace(/-/g,''))] = tpd
    # filledInTimePerDay = [Number(_.first(timePerDay).date.replace(/-/g,''))..Number(_.last(timePerDay).date.replace(/-/g,''))].map (dateNumber) ->
    #   merge(timePerDayMap[dateNumber], dateNumber: dateNumber)

    # last two weeks, with holes?  or last n sessions?  probably last n sessions to remind them of successes
    # TODO(kr) need date math here
    # filteredFilledInTimePerDay = filledInTimePerDay.filter (d) =>
    #   new Date(@props.date - d.dateNumber <= 14


    dom.section { style: styles.section },
      dom.h4 { style: marginTop: 10, marginBottom: 15 }, 'Keeping a regular rhythm works better than cramming.'
      dom.table { style: width: '100%', fontSize: 14 },
        dom.thead null,
          dom.tr null,
            dom.th { style: textAlign: 'left', borderBottom: '1px solid #333', fontWeight: 'normal' }, 'You worked'
            dom.th { style: textAlign: 'left', borderBottom: '1px solid #333', fontWeight: 'normal' }, 'for'
        dom.tbody null, truncatedTimePerDay.map (timePerDay) =>
          percentCompleted = Math.round(100 * timePerDay.minutesOnSite / targetPerDay)
          if timePerDay.minutesOnSite?
            dom.tr { key: timePerDay.date },
              dom.td { style: textAlign: 'left', width: '60%', padding: 2 }, @timeAgoString(moment.utc(timePerDay.date))
              dom.td { style: textAlign: 'left', width: '40%', padding: 2 },
                dom.span { style: width: '30%', display: 'inline-block', textAlign: 'right' }, timePerDay.minutesOnSite + 'm'
                dom.div {
                  style:
                    display: 'inline-block'
                    verticalAlign: 'middle'
                    width: '60%'
                    margin: '2%'
                    background: 'rgb(213, 237, 213)'
                },
                  dom.div {
                    style:
                      fontSize: 10
                      padding: 4
                      color: 'white'
                      textAlign: 'right'
                      width: if percentCompleted > 100 then '100%' else percentCompleted + '%'
                      borderRight: if percentCompleted > 100 then '2px solid darkgreen' else null
                      background: colors.darkGreen
                  }
          else
            dom.tr { style: height: 10, fontSize: 6 },
              dom.td { colspan: 2, fontSize: 6 }, '.'

  renderFellowLearners: ->
    return dom.section null, 'loading...' unless @state.classmates?

    dom.section { style: styles.section },
      dom.div { style: paddingBottom: 5 }, 'Some hard working classmates:'
      dom.ul { style: styles.plainList }, @state.classmates.map (classmate) ->
        dom.li { key: classmate.name },
          dom.a {
            href: "mailto://#{classmate.email}"
            style:
              fontSize: 14
              padding: 2
              paddingRight: 0
          }, classmate.name
          dom.span null, ', ' + classmate.tease
      dom.button {
        href: 'mailto://'
        style: styles.button
      }, 'Study group!'

  bucketIntoPercentile: (aggregatePercentiles, studentValue) ->
    percentiles = ([key, value] for key, value of aggregatePercentiles)
    _.last _.first percentiles, ([key, value]) ->
      value < studentValue

  renderRanks: ->
    student = @state.student.value
    aggregates = @state.studentAggregates.value

    attemptedPercentile = @bucketIntoPercentile aggregates.attempted.percentiles, student.problemsAttempted
    completedPercentile = @bucketIntoPercentile aggregates.completed.percentiles, student.problemsCompleted

    dom.section { style: styles.section },
      dom.div { style: paddingBottom: 5 }, 'My percentile rankings:'
      dom.div null,
        dom.span { style: padding: 5, display: 'inline-block', width: '45%', fontSize: 12 }, 'Problems attempted'
        dom.span null, student.problemsAttempted + ' (' + attemptedPercentile[0] + ')'
      dom.div null,
        dom.span { style: padding: 5, display: 'inline-block', width: '45%', fontSize: 12 }, 'Problems completed'
        dom.span null, student.problemsCompleted + ' (' + completedPercentile[0] + ')'

  # TODO(kr) redo as table
  renderCompareMe: ->
    dom.section { style: styles.section },
      dom.div { style: paddingBottom: 5 }, 'Compared to other students this week:'
      dom.div null,
        dom.span { style: padding: 5, display: 'inline-block', width: '45%', fontSize: 12 }, 'Time on edX'
        @renderComparisonBar 60, 0.34, 0.2
      dom.div null,
        dom.span { style: padding: 5, display: 'inline-block', width: '45%', fontSize: 12 }, 'Videos watched'
        @renderComparisonBar 60, 0.53, 0.2
      dom.div null,
        dom.span { style: padding: 5, display: 'inline-block', width: '45%', fontSize: 12 }, 'Problems attempted'
        @renderComparisonBar 60, -0.12, 0.2
      dom.div null,
        dom.span { style: padding: 5, display: 'inline-block', width: '45%', fontSize: 12 }, 'Problems completed'
        @renderComparisonBar 60, 0.02, 0.2

  # TODO(kr) deprecated
  renderInlineBar: (fractionDelta, options = {}) ->
    maxWidthPercent = 0.30
    dom.div { style: display: 'inline-block', width: (100 * maxWidthPercent) + '%', border: '1px solid #333' },
      dom.div { style: display: 'inline-block', background: options.color ? 'red', width: (fractionDelta * 100) + '%' }, 'x'

  # TODO(kr) this code is a mess
  # TODO(kr) gutters, etc.
  # overflows for text
  renderComparisonBar: (width, delta, maxDelta) ->
    cappedDelta = Math.min Math.abs(delta), maxDelta
    isCapped = cappedDelta < Math.abs(delta)

    textWidth = 40
    barWidth = (width / 2) * (cappedDelta  / maxDelta)
    # left = [textWidth + filler + barWidth]
    # right = [textWidth + maxBarWidth + barWidth]
    pieces = if delta < 0
      [
        dom.div {
          style:
            display: 'inline-block'
            width: textWidth + ((width / 2) - barWidth)
            marginRight: 5
            textAlign: 'right'
        }, delta.toFixed 2
        dom.div {
          dangerouslySetInnerHTML: __html: '&nbsp;'
          style:
            display: 'inline-block'
            borderLeft: if isCapped then '2px solid #333' else ''
            borderRight: '1px solid #666'
            color: '#333'
            background: if Math.abs(delta) > 0.10 then colors.darkRed else '#ccc'
            width: barWidth
            height: '100%'
        }
      ]
    else
      [
        dom.div {
          dangerouslySetInnerHTML: __html: '&nbsp;'
          style:
            display: 'inline-block'
            marginLeft: 5
            width: textWidth + (width / 2)
        }
        dom.div {
          dangerouslySetInnerHTML: __html: '&nbsp;'
          style:
            display: 'inline-block'
            borderLeft: '1px solid #666'
            borderRight: if isCapped then '2px solid #333' else ''
            color: '#333'
            background: if Math.abs(delta) > 0.10 then colors.darkGreen else '#ccc'
            width: barWidth
            height: '100%'
        }
        dom.div {
          style:
            display: 'inline-block'
            width: textWidth
            marginLeft: 5
        }, delta.toFixed 2
      ]

    dom.div {
      style:
        display: 'inline-block'
        height: '100%'
    }, pieces...

  renderAdvice: ->
    adviceStyles = styles.section

    dom.div null,
      # encouraging
      dom.section { style: adviceStyles },
        dom.img { src: '/img/databits50.png', height: 32 }
        dom.div null, "You're working hard!  :)"
        dom.div null, "Based on other students' activity, you're one of the hardest working students!"
        dom.div null, "Effort is one of the best predictors of long-term student success."
      dom.section { style: adviceStyles },
        dom.img { src: '/img/databits50.png', height: 32 }
        dom.div null, "You're really dedicated!  :)"
        dom.div null, "Compared to other students in the same courses, you're one of the students with the most consistent learning routine."
        dom.div null, "Developing and maintaining consistent work habits is one of the best predictors of future success."

      # specific instructional intervention
      dom.section { style: adviceStyles },
        dom.img { src: '/img/databits50.png', height: 32 }
        dom.div null, "These resources have helped other successful students:"
          dom.ul { style: styles.plainList },
            dom.li null, dom.a { href: '/videos/3' }, 'v3'
            dom.li null, dom.a { href: '/problems/1' }, 'p1'

      # corrective
      dom.section { style: adviceStyles },
        dom.img { src: '/img/databits50.png', height: 32 }
        dom.div null, "You're trying to do a lot at once!"
        dom.div null, 'Try limiting what you work on and focus on one at a time.'
        dom.div null, "This helps reduces stress, develop consistent work habits, and allows you to shine in the courses you do focus on."

      # skipping ahead, or not keeping up?

      # identify as leader
      dom.section { style: adviceStyles },
        dom.img { src: '/img/databits50.png', height: 32 }
        dom.div null, "You're learning really effectively!"
        dom.div null, "You've been successful in these course despite spending less time on the site than other students."
        dom.div null, "If you're studying other resources, share them with other classmates so they can learn too."
        dom.div null, "You'd also make a great tutor, and could help others transform their lives through education."
      dom.section { style: adviceStyles },
        dom.img { src: '/img/databits50.png', height: 32 }
        dom.div null, "You're one of the top performing students!"
        dom.div null, "You've got a bright future ahead in other courses like {foo}, so check out where else you can take these skills."
        dom.div null, "You'd also make a great tutor, and could help others transform their lives through education."

