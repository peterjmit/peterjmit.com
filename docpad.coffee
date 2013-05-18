moment = require "moment"

docpadConfig =
  port: 9001

  templateData:
    # Site data
    site:
      url: "http://peterjmit.com"
      title: "Peter Mitchell :: Website and application developer"
      description: """
        Peter Mitchell helps build online businesses and is interested in working
        with start-ups, small companies and individuals
      """
      author: "Peter Mitchell"
      email: "pete@peterjmit.com"
      keywords: "peterjmit, web development, web applications, web developer, php developer, javascript developer, ecommerce"


    # Helper data
    getPageTitle: ->
      if @document.title
        "#{@document.title} :: #{@site.title}"
      else
        @site.title

    getMetaDescription: -> @document.description or @site.description

    getMetaKeywords: -> @site.keywords.concat(@document.tags or []).join(", ")

    formatDate: (date,format = "MMM Do, YYYY") ->
      moment(date).format(format)

  collections:
    # add some default meta data
    all: ->
      @getCollection("html").findAllLive().on "add", (model) ->
        model.setMetaDefaults({ layout: "default", isPage: false })

    pages: ->
      @getCollection("html").findAllLive({ isPage: true })

    posts: ->
      @getFilesAtPath("blog").findAllLive({ isPage: false }, [ date: -1 ])


  events:
    writeAfter: (opts,next) ->
      # Prepare
      balUtil = require("bal-util")
      docpad = @docpad
      rootPath = docpad.config.rootPath

      command = ["grunt", "default"]

      # Execute
      balUtil.spawn(command, { cwd: rootPath, output: true }, next)

      # Chain
      return @

  # Need to work out if we can set environments in grunt for this
  # environments:
  #   static:
  #     outPath: "web"


module.exports = docpadConfig
