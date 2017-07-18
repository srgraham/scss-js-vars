

gonzales = require('gonzales-pe')

_ = require 'lodash'

module.exports.getVariables = (scss)->

  options =
    syntax: 'scss'

  indent = (depth)->
    return _.repeat '  ', depth

  variables = {}

  ast = gonzales.parse scss, options


  printTree = (node, depth=0)->
    lines = []

    text = _.upperFirst(node.type)

    if not text
      text = JSON.stringify(node)

    lines.push indent(depth) + text
    line_index = lines.length - 1

    if _.isArray node.content

      _.each node.content, (child_node)->

        if _.isObject child_node
          lines.push printTree child_node, depth + 1
        return
    else
      lines[line_index] += " #{JSON.stringify(node.content)}"
    return lines.join('\n')

  reduceValue = (nodes)->

#    if nodes.length is 1
#      return reduceNode nodes[0]

    # determine type
    colon_indices = []
    comma_indices = []

    _.each nodes, (child, i)->
      if child.type not in ['operator', 'delimiter']
        return

      if child.content is ':'
        colon_indices.push i

      if child.content is ','
        comma_indices.push i

      return

    # its an obj
    if colon_indices.length > 0
      out = {}
      # assumed comma at end of stuff
      comma_indices.push nodes.length + 1

      for i in [0...colon_indices.length]

        obj_name_node_start_index = 0
        if i > 0
          obj_name_node_start_index = comma_indices[i - 1] + 1

        obj_name_node_end_index = colon_indices[i] - 1

        obj_value_node_start_index = colon_indices[i] + 1
        obj_value_node_end_index = comma_indices[i] - 1


        nodes_obj_name = nodes.slice obj_name_node_start_index, obj_name_node_end_index + 1
        nodes_obj_value = nodes.slice obj_value_node_start_index, obj_value_node_end_index + 1

        obj_name = reduceValue nodes_obj_name
        obj_value = reduceValue nodes_obj_value

        out[obj_name] = obj_value

      return out

    # its a list
    if comma_indices.length > 0
      out = []

      # assumed comma at end of stuff
      comma_indices.push nodes.length + 1

      for i in [0...comma_indices.length]

        list_value_start_index = 0
        if i > 0
          list_value_start_index = comma_indices[i - 1] + 1

        list_value_end_index = comma_indices[i] - 1

        nodes_list_value = nodes.slice list_value_start_index, list_value_end_index
        list_value = reduceValue nodes_list_value

        out.push list_value

      return out

    # otherwise, its just some random math expressions
    left_value = null
    operator = null

    for node in nodes
      if node.is 'operator'
        operator = node.content
        continue

      if node.is 'space'
        continue

      if node.is 'default'
        continue

      right_value = reduceNode node

      if not left_value
        left_value = right_value
        right_value = null
        continue

      switch operator
        when '+'
          left_value = left_value + right_value
        when '-'
          left_value = left_value - right_value
        when '*'
          left_value = left_value * right_value
        when '/'
          left_value = left_value / right_value

      operator = null
      right_value = null

    return left_value

  reduceNode = (node)->
    if node.is 'number'
      return +node.content

    if node.is 'string'
      return node.content.toString().slice 1, -1

    if node.is 'ident'
      return node.content.toString()

    if node.is 'color'
      color = node.content
      return color

    if node.is 'variable'
      var_name = node.first('ident')
      return variables[var_name]

    # could be an obj
    if node.is 'parentheses'
      return reduceValue(node.content)

    # fixme: this is not accurate
    if node.is 'dimension'
      return node.first('number').content

    # fixme: this is not accurate
    if node.is 'function'
      func_name = node.first('ident').content
      args = reduceValue node.first('arguments').content
      return [func_name, args]

    throw new Error("unhandled reduceNode(#{node.type})", JSON.stringify(node))

  ast.traverseByType 'declaration', (node_declaration, index, parent)->
    var_name = null
    var_value = null

    node_property = node_declaration.first('property')
    var_name = node_property.first('variable').first('ident').content

    node_value = node_declaration.first('value')

    var_value = reduceValue node_value.content

    variables[var_name] = var_value

    return

  return variables

