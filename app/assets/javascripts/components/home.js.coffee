# app/assets/javascripts/components/home.js.coffee
@Home = React.createClass
  getInitialState: ->
    data: @props.data
  getDefaultProps: ->
    data: {
      games: [],
      fleets: [],
      leagues: [],
      missions: [],
      tournaments: [],
      users: [],
    }
  render: ->
    React.DOM.div
      className: 'home'
      React.DOM.h2
        className: 'title'
        'Home'
      React.DOM.table
        className: 'table table-bordered'
        React.DOM.thead null,
          React.DOM.tr null,
            React.DOM.th null, 'Game Journal'
        React.DOM.tbody null,
          for game in @state.data.games
            React.createElement Game, key: game.id, game: game
