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

addSyncs = (sync)->
  if sync?
    prototype = @prototype
    sync = Array.prototype.slice.call(arguments)
    if !prototype._sync?
      prototype._sync = sync
    else
      prototype._sync = prototype._sync.concat(sync)
    for v in sync
      config = (__v) ->
        prototype[__v] = prototype[v]
        return {
          get: ()->
            return @[__v]
          set: (val)->
            @[__v] = val
            @_entity[v] = val
        }
      Object.defineProperty(prototype, v, config('__' + v))
  return @

addListensTo = (listensTo)->
  if listensTo
    prototype = @prototype
    listensTo = Array.prototype.slice.call(arguments)
    if !prototype._listensTo?
      prototype._listensTo = listensTo
    else
      prototype._listensTo = prototype._listensTo.concat(listensTo)
  return @

addObserves = (observes)->
  if observes
    prototype = @prototype
    if !prototype._observes?
      prototype._observes = {}
    for key, val of observes
      prototype._observes[key] = val
  return @

componentId = 0
componentize = (component, extensions)->
  id = componentId++
  class NewComponent extends component
    @type: id
    _type: id
    _sync: null
    _listensTo: null
    _observes: null
    constructor: (entity, options)->
      @_entity = entity
      super(options) 

  if extensions?
    for name, extension of extensions
      NewComponent.prototype[name] = extension
  
  NewComponent.sync = addSyncs
  NewComponent.listensTo = addListensTo
  NewComponent.observes = addObserves
  return NewComponent

entity = ()->
  # Principle member of this closure
  getSets = {}
  components =  Array.prototype.slice.call(arguments)
  for component in components
    if component? && component.prototype?
      id = component.type
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
    _options: null
    constructor: (options)->
      super
      options = _options = {} if !options?
      @_components = {}
      for component in components
        # check for special ids
        componentId = component.type
        componentInstance = @_components[componentId] = new component(@, options[componentId] || options)
        events = component.prototype._listensTo
        if events?
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
          if @[__v] != val
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

Sentai = 
  entity: entity
  componentize: componentize

module.exports = Sentai if module