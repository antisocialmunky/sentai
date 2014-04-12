class Events
  context: null
  events: null
  constructor: (options)->
    @context = options.context
    @events = {}
  on: (eventName, callback, ctx, constructor)->
    ctx = @context if !ctx?
    eventCtxs = @events[eventName]
    if eventCtxs
      eventCtxs.push(
        ctx: ctx || @context
        cb: callback)
    else
      @events[eventName] = [{ctx: ctx || ctx, cb: callback}]
    if constructor? && !constructor.prototype[eventName]?
      constructor.prototype[eventName] = (payload) -> @fire(eventName, payload)
  fire: (eventName, payload)->
    eventCtxs = @events[eventName]
    if eventCtxs
      for eventCtx in eventCtxs
        if eventCtx.cb.call(eventCtxs.ctx, payload) == false
          return false
    return true

class Entity extends Events
  constructor: ()->
    super(context: @)

componentId = 0

addSyncs = (component, sync)->
  if sync?
    for v in sync
      config = (__v) ->
        component.prototype[__v] = component.prototype[v]
        return {
          get: ()->
            return @[__v]
          set: (val)->
            @[__v] = val
            @entity[v] = val
        }
      Object.defineProperty(component.prototype, v, config('__' + v))

Entity.Componentize = (component, config)->
  if config?
    sync = config.sync
    if !(sync instanceof Array)
      sync = [sync]
  else
    config = {}
  class NewComponent extends component
    _id: componentId++
    _sync: sync
    _listenTo: config.listenTo
    _observes: config.observes
    constructor: (entity, options)->
      @entity = entity
      super(options)

  addSyncs(component, sync)
  
  return NewComponent

Entity.Class = Class = (components)->
  # Principle member of this closure
  getSets = {}
  if !(components instanceof Array)
    components = [components]
  for component in components
    if component? && component.prototype?
      id = component._id
      # loop through all the observables
      observes = component.prototype._observes
      if observes?
        for func, vars of observes
          cb = component.prototype[func]
          if cb?
            # register reactivity config with getSet
            if !(vars instanceof Array)
              vars = [vars]
            for v in vars
              getSet = getSets[v]
              if !getSet?
                getSets[v] = getSet = []
              # id will be looked up with actual component instance
              getSet.push(
                ctx: id
                cb: cb
                vars: vars)

  class NewClass extends Entity
    _components: null
    constructor: (options)->
      super
      options = {} if !options?
      @_components = {}
      for component in components
        # check for special ids
        componentId = component._id
        componentInstance = @_components[componentId] = new component(@, options[componentId] || options)
        events = component.prototype._listenTo
        if events?
          if !(events instanceof Array)
            events = [events]
          for event in events
            if event instanceof Object
              event = event.on
              eventName = event.do
              if typeof eventName == 'function'
                cb = eventName
              else
                cb = component.prototype[eventName]                
            else
              cb = component.prototype[event]
            if cb?
              @on(event, cb, componentInstance, NewClass)

      for component in components
        sync = component.prototype._sync
        if sync?
          for v in sync
            @[v] = component.prototype['__' + v]


  for v, getSet of getSets
    config = (__v) ->
      return {
        get: ()->
          return @[__v]
        set: (val)->
          @[__v] = val
          # execute the reactive stuff based on the getSet config.
          for getSetConfig in getSet
            args = []
            for arg in getSetConfig.vars
              args.push(@[arg])  
            getSetConfig.cb.apply(@_components[getSetConfig.ctx], args)
      }
    Object.defineProperty(NewClass.prototype, v, config('__' + v))

  return NewClass

module.exports = Entity