path = require 'path';
lrSnippet = require('grunt-contrib-livereload/lib/utils').livereloadSnippet;

folderMount = (connect, point) -> connect.static path.resolve(point)

module.exports = ->

  # Initialize the configuration.
  @initConfig
    markdown:
      blog:
        template: 'markdown/blog/index.html.jst'
        files: ['markdown/blog/*.md']
        dest: 'web/blog/'
        options:
            gfm: true
            highlight: 'manual'

    watch:
      markdown:
        files: ['markdown/**/*.md', 'markdown/**/*.jst']
        tasks: ['markdown']

      sass:
        files: 'web/sass/*.scss'
        tasks: ['compass']

      css:
        files: 'web/css/*.css'
        tasks: ['livereload']

      html:
        files: 'web/**/*.html'
        tasks: ['livereload']

    livereload:
      port: 35729

    connect:
      livereload:
        options:
          port: 9001,
          middleware: (connect, options) -> [lrSnippet, folderMount connect, 'web']

    compass:
      main:
        options:
          require: 'compass-normalize'
          cssDir: 'web/css'
          sassDir: 'web/sass'
          imagesDir: 'web/img'
          javascriptsDir: 'web/js'
          outputStyle: 'compressed'
          raw: 'http_path = "/"\n relative_assets = true\n'



  # Load external Grunt task plugins.
  @loadNpmTasks 'grunt-contrib-compass'
  # live reload tasks
  @loadNpmTasks 'grunt-regarde'
  @loadNpmTasks 'grunt-contrib-connect'
  @loadNpmTasks 'grunt-contrib-livereload'
  @loadNpmTasks 'grunt-markdown'

  @renameTask 'regarde', 'watch'

  # Default task.
  @registerTask 'default', ['compass']
  @registerTask 'server', ['livereload-start', 'connect', 'watch']
