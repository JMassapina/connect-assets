app = require('connect').createServer()
assets = require('../lib/assets.js')
request = require('request')
path = require('path')

one = {}
two = {}

app.use(assets(
    build: false
    buildDir: false
    helperContext: one
    src: path.join(__dirname, 'assets')
))

app.use(assets(
    build: false
    buildDir: false
    servePath: 'http://mycdn.net'
    helperContext: two
    src: path.join(__dirname, 'assets')
))

app.listen(4995)

exports['Requests for local paths are served correctly'] = (test) ->
    one.css('images')
    request('http://localhost:4995/css/images.css', (err, res, body) ->
        throw err if err
        expectedBody = '''
        #test {
          background: url("/img/foobar.png");
        }\n
        '''
        test.equals(body, expectedBody)
        test.done()
        
    )

exports['Local takes precedence over cdn'] = (test) ->
    two.css('images')
    one.css('images')
    request('http://localhost:4995/css/images.css', (err, res, body) ->
        throw err if err
        expectedBody = '''
        #test {
          background: url("/img/foobar.png");
        }\n
        '''
        test.equals(body, expectedBody)
        test.done()

    )

exports['Invocations of helper functions share no global state'] = (test) ->
    test.equals(one.js('a'), '<script src=\'/js/a.js\'></script>')
    test.equals(two.js('a'), '<script src=\'http://mycdn.net/js/a.js\'></script>')
    test.done()
    app.close()
    