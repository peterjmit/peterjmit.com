path = require 'path';
lrSnippet = require('grunt-contrib-livereload/lib/utils').livereloadSnippet;

folderMount = (connect, point) -> connect.static path.resolve(point)

module.exports = ->

  # Initialize the configuration.
  @initConfig
    watch:
      sass:
          files: 'sass/*.scss'
          tasks: ['compass']

      css:
        files: 'css/*.css'
        tasks: ['livereload']

      html:
          files: 'index.html'
          tasks: ['livereload']

    livereload:
      port: 35729

    connect:
      livereload:
        options:
          port: 9001,
          middleware: (connect, options) -> [lrSnippet, folderMount connect, '.']

    compass:
      main:
        options:
          require: 'compass-normalize'
          cssDir: 'css'
          sassDir: 'sass'
          imagesDir: 'img'
          javascriptsDir: 'js'
          raw: 'http_path = "/"\n'



  # Load external Grunt task plugins.
  @loadNpmTasks 'grunt-contrib-compass'
  # live reload tasks
  @loadNpmTasks 'grunt-regarde'
  @loadNpmTasks 'grunt-contrib-connect'
  @loadNpmTasks 'grunt-contrib-livereload'

  @renameTask 'regarde', 'watch'

  # Default task.
  @registerTask 'default', ['compass']
  @registerTask 'server', ['livereload-start', 'connect', 'watch']
