fs = require 'fs'
path = require 'path'
url = require 'url'
_ = require 'lodash'
buildIndex = require './scripts/build_index.coffee'
merge = (objs...) -> _.extend {}, objs...


# Handler for the server to return the proper HTML files.
handler = (dataset, req, res) ->
  file = path.join(__dirname, 'index.html')
  if req.url.indexOf('dist') isnt -1
    file = path.join(__dirname, req.url)
  else if req.url.indexOf('img') isnt -1
    file = path.join(__dirname, req.url)
  else if req.url.indexOf('/dataset/problems') is 0
    res.write JSON.stringify dataset.problems
    res.end()
  else if req.url.indexOf('/dataset/problem') is 0
    queryParams = url.parse(req.url, true).query
    problemId = queryParams.problemId
    problem = _.find dataset.problems, (d) -> d.id.toString() is problemId.toString()
    if problem?
      res.write JSON.stringify problem
      return res.end()
    else
      res.writeHead 404
      return res.end()
  else if req.url.indexOf('/dataset/students') is 0
    queryParams = url.parse(req.url, true).query
    dateNumber = Number queryParams.date
    studentsWithStats = buildIndex.mergeStudentStats dataset.students, dataset.problemAttempts, dateNumber
    res.write JSON.stringify studentsWithStats
    res.end()
  else if req.url.indexOf('/dataset/student_aggregates') is 0
    queryParams = url.parse(req.url, true).query
    dateNumber = Number queryParams.date
    studentsWithStats = buildIndex.mergeStudentStats dataset.students, dataset.problemAttempts, dateNumber
    studentAggregates = buildIndex.studentAggregates studentsWithStats
    res.write JSON.stringify studentAggregates
    res.end()
  else if req.url.indexOf('/dataset/student') is 0
    # merge in stats based on `date`
    queryParams = url.parse(req.url, true).query
    dateNumber = Number queryParams.date
    studentsWithStats = buildIndex.mergeStudentStats dataset.students, dataset.problemAttempts, dateNumber
    studentWithStats = _.find studentsWithStats, (d) -> d.studentId.toString() is queryParams.studentId.toString()
    if studentWithStats?
      problemAttempts = dataset.problemAttempts.filter (d) ->
        return false if Number(d.dateAttempted.replace(/-/g, '')) > dateNumber
        return false if d.studentId isnt queryParams.studentId
        true
      minutesPerDay = dataset.minutesPerDay.filter (d) ->
        return false if Number(d.date.replace(/-/g, '')) > dateNumber
        return false if d.studentId isnt queryParams.studentId
        true
      videoViews = dataset.videoViews.filter (d) ->
        return false if Number(d.dateViewed.replace(/-/g, '')) > dateNumber
        return false if d.studentId isnt queryParams.studentId
        true
      res.write JSON.stringify merge(studentWithStats, {
        totalProblems: dataset.problems.length
        minutesPerDay: minutesPerDay
        videoViews: videoViews
        problemAttempts: problemAttempts
      })
      return res.end()
    else
      res.writeHead 404
      return res.end()

  console.log "request.url: #{file}"
  fs.createReadStream(file).pipe res

main = ->
  config =
    port: 3004

  console.log 'Building dataset...'
  dataset = buildIndex.load()
  server = require('http').createServer handler.bind null, dataset
  server.listen config.port
  console.log "Listening on port: #{config.port}"

main()