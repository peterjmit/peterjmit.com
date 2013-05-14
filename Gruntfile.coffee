module.exports = ->

  # Initialize the configuration.
  @initConfig
    compass:
      main:
        options:
          require: 'compass-normalize'
          cssDir: 'web/css'
          sassDir: 'src/sass'
          imagesDir: 'web/img'
          javascriptsDir: 'web/js'
          outputStyle: 'compressed'
          raw: 'http_path = "/"\n relative_assets = true\n'

  # Load external Grunt task plugins.
  @loadNpmTasks 'grunt-contrib-compass'

  # Default task.
  @registerTask 'default', ['compass']
