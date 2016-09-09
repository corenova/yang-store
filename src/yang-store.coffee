Yang = require('yang-js').register()
uuid = require 'node-uuid'
url  = require 'url'

module.exports = require('../schema/yang-store.yang').bind {

  # dependency grouping bindings
  '{yanglib:module-list}/module/schema': ->

  # local grouping bindings
  '{datasync-list}/link/link-id': -> @content ?= uuid.v4(); return @content

  # local data tree bindings
  '/data/store': -> @content ?= Yang.Model.Store; return @content
    
  '/data/root': ->
    @find('../store/*').reduce ((a,b) ->
      a[k] = v for k, v of b.valueOf()
      return a
    ), {}

  # local rpc bindings
  import: (input, resolve, reject) ->
    dataroot = @get '../data/root'
    model = switch
      when typeof input is 'string'    then Yang.parse(input).eval dataroot
      when input instanceof Yang       then input.eval dataroot
      when input instanceof Yang.Model then input
      #else Yang.compose(input).eval input
    console.info "importing '#{model.name}' to the store"
    model.join @get('../data/store')
    @emit 'import', model
    resolve
      name: model.name
      properties: model.props.map (x) -> x.name

  sync: (input, resolve, reject) ->
    # implicitly assume inet:uri for now...
    from = url.parse input.source
    unless from.protocol?
      try data = require from.path
      catch then return reject "unable to fetch '#{from.path}' from local filesystem"

      # implicitly assume input.destination is 'store' for now
      # need to merge 'data' into the 'store'
      @find('/data/*').forEach (prop) -> prop.merge data
      return resolve input

    reject "alternative protocols not yet supported for sync"

  link: (input, resolve, reject) ->
    return reject "link facility work-in-progress"
    client = @find("/#{to.protocol}client")
    unless client?
      throw new Error "unable to locate '/#{to.protocol}client' in the Store"
    client.connect to
    .then (data) =>
      prop.merge data for prop in @in('/')
      return data
    
}
