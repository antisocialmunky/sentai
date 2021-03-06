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
        if eventCtx.cb.call(eventCtx.ctx, payload) == false
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
      if v instanceof Object
        #from to syntax
        to = v.to
        v = v.from
        type = typeof to
        if type == 'function'
          config = (__v, v) ->
            prototype[__v] = prototype[v]
            return {
              get: ()->
                return @[__v]
              set: (val)->
                @[__v] = val
                to.call(@_entity, val)
              enumerable:true
            }
        else if type =='string'
          config = (__v, v, to) ->
            prototype[__v] = prototype[v]
            return {
              get: ()->
                return @[__v]
              set: (val)->
                @[__v] = val
                @_entity[to] = val
              enumerable:true
            }
      else
        config = (__v, v) ->
          prototype[__v] = prototype[v]
          return {
            get: ()->
              return @[__v]
            set: (val)->
              @[__v] = val
              @_entity[v] = val
            enumerable:true
          }
      Object.defineProperty(prototype, v, config('__' + v, v, to))
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

componentize = (component, extensions)->
  if extensions?
    for name, extension of extensions
      component.prototype[name] = extension

  component.prototype._entity = null
  
  component.sync = addSyncs
  component.listensTo = addListensTo
  component.observes = addObserves
  return component

entity = ()->
  # Principle member of this closure
  getSets = {}
  components =  Array.prototype.slice.call(arguments)
  for component in components
    if component? && component.prototype?
      name = component.name
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
              # name will be looked up with actual component instance
              getSet.push(
                ctx: name
                cb: cb
                vars: vars)

  class NewClass extends Entity
    _components: null
    _options: null
    constructor: (options)->
      super
      options = _options = {} if !options?
      @_components = {}
      componentInstances = []
      for component in components
        # check for special name
        name = component.name
        component.prototype._entity = @
        componentInstance = @_components[name] = new component(options[name] || options)
        componentInstance._entity = @
        component.prototype._entity = null
        componentInstances.push(componentInstance)
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

      for componentInstance in componentInstances
        sync = componentInstance._sync
        if sync?
          for v in sync
            if v instanceof Object
              #from to syntax
              to = v.to
              v = v.from
              type = typeof to
              if type == 'function'
                to.call(@, componentInstance['__' + v])
              else if type == 'string'
                #clear out the values so we can trigger these correctly
                @['__' + to] = null
                @[to] = componentInstance['__' + v]
            else
              #clear out the values so we can trigger these correctly
              @['__' + v] = null
              @[v] = componentInstance['__' + v]

  for v, getSet of getSets
    config = (__v, getSet) ->
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
        enumerable:true
      }
    Object.defineProperty(NewClass.prototype, v, config('__' + v, getSet))

  return NewClass

Sentai = 
  entity: entity
  componentize: componentize

module.exports = Sentai if module