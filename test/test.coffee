

assert = require 'assert'
scss_vars = require '../index'


it 'should fetch and parse variables', ()->


  scss = """
    $a: 123;

    $b: $a;

    $c: $a + 1;
    $d: ($a + 1);

    $button-colors:
      (
        'name': 'primary',
        'params': (
          'background': $a,
          'background-hover': $aui-primary-button-background-hover,
          'background-selected': $aui-primary-button-background-selected,
          'border-selected': $aui-primary-button-border-selected,
          'color': $aui-primary-button-color,
          'color-hover': $aui-primary-button-color-hover,
          'color-selected': $aui-primary-button-color-selected
        ),
        'last': 888
      )
  """
  actual = scss_vars.getVariables scss

  expected =
    a: 123
    b: 123
    c: 124
    d: 124
    'button-colors':
      name: 'primary'
      params:
        background: 123
        'background-hover': undefined
        'background-selected': undefined
        'border-selected': undefined
        color: undefined
        'color-hover': undefined
        'color-selected': undefined
      last: 888

  assert.deepEqual(actual, expected)

#console.log out
