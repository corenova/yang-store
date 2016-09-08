Yang = require('yang-js').register()
uuid = require 'node-uuid'
url  = require 'url'

module.exports = require('../schema/yang-store.yang').bind {

  '{datasync-list}/link/link-id': -> @content ?= uuid.v4(); return @content
  
  dataset: ->
    data = {}
    for name, module of Yang.Model.Store
      data[k] = v for k, v of module.__.valueOf()
    return data

  import: (input, resolve, reject) ->
    dataroot = @get '../data'
    model = switch
      when typeof input is 'string'    then Yang.parse(input).eval dataroot
      when input instanceof Yang       then input.eval dataroot
      when input instanceof Yang.Model then input
      #else Yang.compose(input).eval input
    console.info "importing '#{model.name}' to the store"
    model.join @get('../store')
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
