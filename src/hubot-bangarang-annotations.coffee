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

deployment_event = (msg, deployment) -> 
  text = msg.message.text
  msg.reply "#{deployment}: #{text}"

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
