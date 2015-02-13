_ = require 'lodash'
React = require 'react/addons'
dom = React.DOM
moment = require '../vendor/moment'

module.exports = Header = React.createClass
  displayName: 'Header'

  propTypes:
    date: React.PropTypes.number.isRequired

  render: ->
    dom.div { style: padding: 5, paddingLeft: 10, background: '#ccc' },
      dom.img { src: '/img/hero-logo-edx.png', height: 24, verticalAlign: 'bottom' }
      dom.span {
        style:
          fontSize: 24
          fontWeight: 'bold'
          paddingLeft: 8
          verticalAlign: 'bottom'
      }, 'advisor'
      dom.span { style: padding: 5 }, @renderDateAsText()
      dom.div { style: fontSize: 10, float: 'right' },
        dom.a { href: '/admin' }, 'admin'

  renderDateAsText: ->
    year = @props.date.toString().slice(0, 4)
    month = @props.date.toString().slice(4, 6)
    day = @props.date.toString().slice(6, 8)
    moment.utc("#{year}-#{month}-#{day}").format 'MM/DD/YY'

