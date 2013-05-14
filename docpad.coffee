moment = require 'moment'

docpadConfig =
  port: 9001

  events:
    writeAfter: (opts,next) ->
      # Prepare
      balUtil = require('bal-util')
      docpad = @docpad
      rootPath = docpad.config.rootPath

      command = ['grunt', 'default']

      # Execute
      balUtil.spawn(command, { cwd: rootPath, output: true }, next)

      # Chain
      @

  # Need to work out if we can set environments in grunt for this
  # environments:
  #   static:
  #     outPath: 'web'


module.exports = docpadConfig
