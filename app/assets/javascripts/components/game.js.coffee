# app/assets/javascripts/components/game.js.coffee
@Game = React.createClass
  render: ->
    React.DOM.tr null,
      React.DOM.td null, @props.game.journal_filename
