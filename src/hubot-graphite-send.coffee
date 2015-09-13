# Description:
#   Send metrics to graphite based on chat messages
#
# Dependencies:
#   "graphite-udp": "*"
#
# Configuration:
#   HUBOT_GRAPHITE_SEND_HOST # host to send metrics to
#   HUBOT_GRAPHITE_SEND_PORT # Port to send metrics to (default: 2003)
#   HUBOT_GRAPHITE_SEND_NAMESPACE # Metric prefix (default: hipchat.annotations)
# Commands:
#   graphite-send deployments
#   graphite-send help
#
#
# Notes:
#   Configuration is done in ./config/hubot-graphite-send-config.json or
#   through environment variables.
#
# Author:
#   amwelch (https://github.com/amwelch)

cwd = process.cwd()
DEFAULTS_FILE = "#{__dirname}/data/defaults.json"
CONFIG_FILE = "#{cwd}/config/hubot-graphite-send-config.json"
DEPLOYMENTS_FILE = "#{cwd}/config/deployments.json"

deployments = require "#{DEPLOYMENTS_FILE}"
nconf = require("nconf")
graphite = require("graphite-udp")
nconf.argv()
    .env()
    .file('config', CONFIG_FILE)
    .file('defaults', DEFAULTS_FILE)

sanity_check_args = (msg) ->
  required_args = [
    "HUBOT_GRAPHITE_SEND_HOST"
  ]

  for arg in required_args
    if !nconf.get(arg)
      buf = "#hubot-graphite-send is not properly configured. #{arg} is not set."
      msg.reply buf
      return false

  return true

help = (msg) ->
  commands = [
    "graphite-send deployments"
    "graphite-send help"
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
    host: nconf.get("HUBOT_GRAPHITE_SEND_HOST")
    port: nconf.get("HUBOT_GRAPHITE_SEND_PORT")
    interval: 10
    type: 'udp4'

get_graphite_metric = (msg, deployment) ->
  prefix = nconf.get("HUBOT_GRAPHITE_SEND_NAMESPACE")
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

  robot.hear /graphite-send help/i, (msg) ->
    help(msg)

  robot.hear /graphite-send/i, (msg) ->
    msg.reply triggers.join('\n')

  for deployment in deployments
    regex = new RegExp "(#{deployment})", 'i'
    robot.hear regex, (msg) ->
      if !sanity_check_args(msg)
        return
      deployment_event(msg, msg.match[1])
