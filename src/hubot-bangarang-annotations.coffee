nconf = require("nconf")
deployments = require './data/deployments.json'

cwd = process.cwd()
DEFAULTS_FILE = "#{__dirname}/data/defaults.json"

nconf.argv()
    .env()
    .file('defaults', DEFAULTS_FILE)

sanity_check_args = (msg) ->
  required_args = [
  ]

  for arg in required_args
    if !nconf.get(arg)
      buf = "#hubot-grafana-annotations is not properly configured. #{arg} is not set."
      msg.reply buf
      return false

  return true

help = (msg) ->
  commands = [
    "grafana-annotations show deployments"
    "grafana-annotations help"
  ]
  buf = ""
  for command in commands
    buf += "#{command}\n"

  msg.reply buf

make_url = () ->
  host = nconf.get("HUBOT_BANGARANG_ANNOTATIONS_HOST")
  port = nconf.get("HUBOT_BANGARANG_ANNOTATIONS_PORT")
  protocol = nconf.get("HUBOT_BANGARANG_ANNOTATIONS_PROTOCOL")

  url = "#{protocol}://#{host}:#{port}/api"

probably_unique_id = () ->
  id = Math.random().toString(36).slice(2)

timestamp = () ->
  new Date().getTime()

make_incident = (text) ->
  id = probably_unique_id()
  data =
    event: "foo"
    time: "#{timestamp}"
    id: "#{id}",
    active: true
    escalation: "production-info"
    description: "#{text}"
    status: 0
    metric: 0
    tags: null

  msg = 
    "#{id}": data

create_annotation = (msg deployment, text) ->
  url = make_url()
  data = make_incident()
  robot.http(url).header('Content-Type', 'application/json').post(data) (err, res, body) ->
      if err
        msg.reply "Could not create annotation #{err}"

deployment_event = (msg, deployment) -> 
  text = msg.message.text
  msg.reply "Adding annotation to #{deployment}"

module.exports = (robot) ->

  robot.hear /grafana-annotations help/i, (msg) ->
    help(msg)

  robot.hear /grafana-annotations show deployments/i, (msg) ->
    msg.reply triggers.join('\n')

  for deployment in deployments
    regex = new RegExp "(#{deployment})", 'i'
    robot.hear regex, (msg) ->
      if !sanity_check_args(msg)
        return
      deployment_event(msg, msg.match[1])
