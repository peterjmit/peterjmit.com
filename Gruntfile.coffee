# Create a new configuration function that Grunt can
# consume.
module.exports = ->

  # Initialize the configuration.
  @initConfig
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

  # Default task.
  @registerTask 'default', ['compass']
