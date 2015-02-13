fs = require 'fs'
_ = require 'lodash'
stats = require 'stats-lite'

merge = (objs...) -> _.extend {}, objs...

fixtureStudentNames = [
  'Kevin'
  'Melissa'
  'Dan'
  'Chris'
  'Debra'
  'Becky'
]

module.exports = self =
  # TODO(kr) not a real parser
  readProblems: (filename) ->
    rawFile = fs.readFileSync(filename).toString()
    _.compact rawFile.split("\n").slice(1).map (line) ->
      [id, section, subSection, maxPoints] = line.trim().split(',')
      return null unless section?
      {id, section, subSection, maxPoints}

  ###
  problem_attempts.csv
  student_id
  section
  subsection
  problem_id
  date_attempted
  max_points -- same as the max_points column in problems.csv. Copied for convenience.
  score -- the student's score
  ###
  readProblemAttempts: (filename) ->
    rawFile = fs.readFileSync(filename).toString()
    _.compact rawFile.split("\n").slice(1).map (line) ->
      [studentId, section, subSection, problemId, dateAttempted, maxPoints, score] = line.trim().split(',')
      return null unless section?
      {studentId, section, subSection, problemId, dateAttempted, maxPoints, score}

  # There's no central definition of students, so join the observed data sources to infer that, and then add names
  # to make demoing easier.
  readStudents: (problemAttempts, fixtureStudentNames) ->
    studentIds = _.uniq _.pluck problemAttempts, 'studentId'
    studentIds.map (studentId) ->
      name = fixtureStudentNames[studentId % fixtureStudentNames.length] + '_' + studentId
      email = name + '@foo.com'
      {studentId, name, email}

  readMinutesPerDay: (filename) ->
    rawFile = fs.readFileSync(filename).toString()
    _.compact rawFile.split("\n").slice(1).map (line) ->
      [studentId, date, minutesOnSite] = line.trim().split(',')
      return null unless date?
      {studentId, date, minutesOnSite}

  # student_id,section,subsection,video_id,date_viewed,duration_seconds,watched_seconds
  readVideoViews: (filename) ->
    rawFile = fs.readFileSync(filename).toString()
    _.compact rawFile.split("\n").slice(1).map (line) ->
      [studentId, section, subSection, videoId, dateViewed, durationSeconds, watchedSeconds] = line.trim().split(',')
      return null unless section?
      {studentId, section, subSection, videoId, dateViewed, durationSeconds, watchedSeconds}

  mergeStudentStats: (students, problemAttempts, asOfDateNumber) ->
    students.map (student) ->
      attemptsByStudent = problemAttempts.filter (attempt) ->
        return false if attempt.studentId isnt student.studentId
        return false if Number(attempt.dateAttempted.replace(/-/g, '')) > asOfDateNumber
        true

      problemsAttempted = attemptsByStudent.length
      problemsCompleted = attemptsByStudent.filter((attempt) -> Number(attempt.score) >= Number(attempt.maxPoints)).length
      totalProblems =
      completionPercentage = if problemsAttempted > 0 then Math.round(100 * problemsCompleted / problemsAttempted) else 0
      merge student, {problemsAttempted, problemsCompleted, completionPercentage}

  load: ->
    problems = @readProblems 'edx-dataset/problems.csv'
    problemAttempts = @readProblemAttempts 'edx-dataset/problem_attempts.csv'
    minutesPerDay = @readMinutesPerDay 'edx-dataset/minutes_per_day.csv'
    videoViews = @readVideoViews 'edx-dataset/video_views.csv'
    students = @readStudents problemAttempts, fixtureStudentNames
    {problems, problemAttempts, students, minutesPerDay, videoViews}

  main: ->
    {problems, problemAttempts, students} = @load()

    # console.log JSON.stringify problems
    # studentAttempts = problemAttempts.filter (attempt) ->
    #   attempt.studentId is '499'

    # TODO(kr) no real way to know what the student is on next, you should encode that in the course.
    # TODO(kr) the problem attempts have only binary scores!
    # TODO(kr) there are a lot of incomplete problems here.  so how do we know where they should be?
    # is this a fully self-directed class, or timed with a cohort?


    # console.log studentFailures problemAttempts, '499'
    # console.log _.uniq _.pluck studentAttempts, 'section'
    # console.log _.uniq _.pluck studentAttempts, 'subSection'

    # console.log studentActiveFailedProblemIds problemAttempts, '460'
    # console.log JSON.stringify @studentsCompletingAllProblems problemAttempts, problems
    console.log JSON.stringify _.first @studentsAttempingMostProblems(problemAttempts), 10

  studentsCompletingAllProblems: (problemAttempts, problems) ->
    allProblemsId = _.pluck problems, 'id'
    studentsByProblems = _.groupBy problemAttempts, (d) -> d.studentId
    perfectStudents = []
    for studentId, problems of studentsByProblems
      if _.isEmpty _.difference allProblemsId, _.pluck problems, 'id'
        perfectStudents.push studentId

    perfectStudents

  studentsAttempingMostProblems: (problemAttempts) ->
    studentsByProblems = _.groupBy problemAttempts, (d) -> d.studentId
    studentsWithAttempts = []
    for studentId, problems of studentsByProblems
      studentsWithAttempts.push
        studentId: studentId
        problemCount: problems.length
    _.sortBy studentsWithAttempts, (d) -> -1 * d.problemCount

  studentActiveFailedProblemIds: (problemAttempts, studentId) ->
    studentAttempts = problemAttempts.filter (attempt) ->
      attempt.studentId.toString() is studentId.toString()
    studentProblemMap = _.groupBy studentAttempts, (attempt) ->
      attempt.problemId

    activeFailedProblemIds = []
    for problemId, attempts of studentProblemMap
      sortedAttempts = _.sortBy attempts, (attempt) -> attempt.dateAttempted.replace(/-/g, '')
      if parseFloat(_.last(sortedAttempts).score) < 1
        activeFailedProblemIds.push problemId

    activeFailedProblemIds

  studentAggregates: (studentsWithStats) ->
    attempted: @computeStats(_.pluck studentsWithStats, 'problemsAttempted')
    completed: @computeStats(_.pluck studentsWithStats, 'problemsCompleted')
    completionPercentage: @computeStats(_.pluck studentsWithStats, 'completionPercentage')

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