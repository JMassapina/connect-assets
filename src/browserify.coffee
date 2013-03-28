uglify = require('uglify-js')
Browserify = require('browserify')
path = require('path')
_ = require('underscore')

module.exports = class BrowserifyWrapper
    constructor: (@options) ->
        @jsBundles = {}
        @changedPaths = {}
    
    requireBundle: (flags, cb) ->
        requireRoute = 'js/require.js'
        requireBundle = new Browserify(
            cache: @options.browserifyCache
        )
        
        if flags.minify
            requireBundle.register('post', @_minify)
            _.each(requireBundle.files, (file, fileName) =>
                if fileName? then file.body = @_minify(file.body)
            )
        
        requireBundleText = requireBundle.bundle()
        @jsBundles[requireRoute] = requireBundle
        
        changed = !@changedPaths[requireRoute]?
        @changedPaths[requireRoute] = false
        
        cb(null, requireBundleText, changed)
    
    getConcatenation: (filePath, flags, callback) ->
        if filePath == 'js/require.js' then return @requireBundle(flags, callback)
        
        if typeof flags is 'function'
            callback = flags
            flags = {}
        
        flags ?= {}
        flags.async ?= true
        
        if @changedPaths[filePath]?
            bundle = @jsBundles[filePath]
            return callback(null, bundle.bundle(), @changedPaths[filePath])
        
        bundle = Browserify(debug: true, watch: flags.watch, cache: @options.browserifyCache)
        bundle.files = {}
        bundle.prepends = []
        
        if flags.minify
          bundle.register(@_minify)
        
        entryFilePath = path.join(@options.src, filePath)
        bundle.addEntry(entryFilePath)
        bundledSrc = bundle.bundle()
        
        @changedPaths[filePath] = false
        
        bundle.on('bundle', () =>
            @changedPaths[filePath] = true
        )
        
        @jsBundles[filePath] = bundle
        
        callback(null, bundle.bundle(), true)
    
    getCompiledChain: (filePath, flags, callback) ->
        throw new Error('build must be enabled when using browserify')
        
    
    _minify: (js) ->
        jsp = uglify.parser
        pro = uglify.uglify
        ast = jsp.parse js
        ast = pro.ast_mangle ast
        ast = pro.ast_squeeze ast
        pro.gen_code ast
        