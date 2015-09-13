nconf = require("nconf")
deployments = require './data/deployments.json'
graphite = require("graphite-udp")

cwd = process.cwd()
DEFAULTS_FILE = "#{__dirname}/data/defaults.json"

nconf.argv()
    .env()
    .file('defaults', DEFAULTS_FILE)

sanity_check_args = (msg) ->
  required_args = [
    "HUBOT-GRAPHITE-SEND-HOST"
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

get_graphite_client = () ->
  options = get_graphite_options()
  client = graphite.createClient(options)

get_graphite_options = () ->
  options = 
    host: nconf.get("HUBOT-GRAPHITE-SEND-HOST")
    port: nconf.get("HUBOT-GRAPHITE-SEND-PORT")
    interval: 10
    type: 'udp4'

get_graphite_metric = (msg, deployment) ->
  prefix = nconf.get("HUBOT-GRAPHITE-SEND-NAMESPACE")
  msg = msg.replace /\s/, "_"
  metric = "#{prefix}.#{deployment}.#{msg}"

get_graphite_metric_value = () ->
  metric = 0

deployment_event = (msg, deployment) ->
  text = msg.message.text
  msg.reply "#{deployment}: #{text}"
  client = get_graphite_client()
  metric = get_graphite_metric text, deployment
  value = get_graphite_metric_value()
  client.addMetric(metric, value, (err, bytes) ->
    if err
      console.log "Error adding metric #{err}"
    else
      msg.reply "added metric #{metric}"
  )

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
