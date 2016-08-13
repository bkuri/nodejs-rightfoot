'use strict'

{get} = require('./http')
{Separator} = require('inquirer')
tools = require('./tools')

URI = 'http://developer.weborama.nl/tools-downloads/'


class Questions
  confirm: (message, name='confirmed', defaultVal=no) ->
    return Object.assign {message, name}, defaut: defaultVal, type: 'confirm'


  firstStage: (choices) =>
    @qType.choices = choices
    # return [@qName, @qLang, @qType, @qImage]
    return [@qName, @qLang, @qType]


  menu: (saved) =>
    if tools.foundFile()
      data = tools.readVars()
      saved = saved.filter (item) -> (item isnt data.meta.name)

    return [ @qMenu(saved.length > 0), @qLoad(saved), @qScrub(), @qSave() ]


  nextStage: (id) =>
    return [@qPreview] if (id is 'preview')
    return [@qWidth, @qHeight, @qSticky, @qOffsetX, @qOffsetY, @qZIndex, @qLibs]


  qLibs:
    choices: []
    message: 'Select the libraries that you would like to use:'
    name: 'libraries'
    type: 'checkbox'


  qLoad: (choices) ->
    return Object.assign {choices},
      message: 'Select the project to load:'
      name: 'name'
      type: 'list'
      when: (answers) -> (answers.choice is 'load')


  qMenu: (existing) ->
    found = tools.foundFile()

    toggle = (item, condition) ->
      return item if condition
      return new Separator(item.name)

    choices = switch
      when (not found and existing)
        [
          { name: 'Start a new project', value: 'begin' }
          { name: 'Load a saved project', value: 'load' }
          new Separator()
          { name: 'Exit and do nothing', value: 'exit' }
        ]

      else
        [
          new Separator()
          { name: 'Start a live development server at http://localhost:3333', value: 'server' }
          { name: 'Render the current state to the public folder', value: 'standard' }
          new Separator()
          toggle { name: 'Load a saved project', value: 'load' }, existing
          toggle { name: 'Save the current project', value: 'backup' }, found
          new Separator()
          { name: 'Zip production version of the current state', value: 'build' }
          { name: 'Zip snapshot of the current state (as is)', value: 'snapshot' }
          new Separator()
          { name: 'Clean up public folder (leave everything else intact)', value: 'clean' }
          { name: 'Start a new project from scratch', value: 'scrub' }
          new Separator()
          { name: 'Run a series of tests on the current state', value: 'test' }
          { name: 'Exit and do nothing', value: 'exit' }
        ]

    return Object.assign {choices},
      message: 'What would you like to do?'
      name: 'choice'
      type: 'list'


  qPreview:
    default: no
    message: 'Would you like to add a preview page?'
    name: 'preview'
    type: 'confirm'


  qSave: ->
    default: yes
    message: 'Back up existing project first?'
    name: 'backup'
    type: 'confirm'
    when: (answers) -> tools.foundFile() and (answers.choice in [ 'load', 'scrub' ])


  qScrub: ->
    defaut: no
    message: 'Are you sure? You will lose all your current work!'
    name: 'scrub'
    type: 'confirm'
    when: (answers) -> (answers.choice is 'scrub')


  qSticky:
    default: yes
    message: 'Sticky?'
    name: 'sticky'
    type: 'confirm'


  qType:
    choices: []
    default: 0
    message: 'Banner type:'
    name: 'type'
    type: 'list'


  constructor: ->
    inputNumber = (name, defaultVal=0, min=defaultVal) ->
      name = name.split(' ')[0].toLowerCase()

      return Object.assign {name},
        default: defaultVal
        filter: (val) -> Number(val)
        message: "#{ name }:"

        validate: (val) ->
          return no if Number.isNaN(val)
          return no if (Number(val) < min) and (name isnt 'x') and (name isnt 'y')
          return yes

    inputText = (name, message, defaultVal=null) ->
      return Object.assign {name, message},
        default: defaultVal
        filter: (val) -> String(val).trim()
        validate: (val) -> (String(val).trim().length > 0)

    libs = []

    get(URI)
      .catch (error) ->
        # @msg.error 'http', error
        throw error

      .then ($) ->
        $('tr', '#content').each (index, item) ->
          return if (index is 0)
          name = ''

          $('td', item).each (i) ->
            value = $(@).text().trim()

            switch
              when (i is 0) then name += "#{ value } v"
              when (i is 1) then name += value
              else libs.push {name, value}

            return

          return

        @qLibs.choices = libs
        return

    @qHeight = inputNumber('Height', 250, 1)
    @qLang = inputText('lang', 'What language will the banner be in?', 'en')
    @qName = inputText('name', 'Please give this project a name:')
    @qOffsetX = inputNumber('X Offset')
    @qOffsetY = inputNumber('Y Offset')
    @qWidth = inputNumber('Width', 300, 1)
    @qZIndex = inputNumber('Z Index', 1)
    return


module.exports = new Questions()
