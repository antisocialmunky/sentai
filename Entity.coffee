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
Entity.Class = Class = (components)->
  # Principle member of this closure
  getSets = {}
  for component in components
    if component? && component.prototype?
      id = component.name
      # loop through all the observables
      obs = component.prototype.obs
      if obs?
        for func, vars of obs
          cb = component.prototype[func]
          if cb?
            # register reactivity config with getSet
            for v in vars
              getSet = getSets[v]
              if !getSet?
                getSets[v] = getSet = []
              # id will be looked up with actual component instance
              getSet.push(
                ctx: id, 
                cb: cb)

  class NewClass extends Entity
    _components: null
    constructor: (options)->
      super
      options = {} if !options?
      @_components = {}
      for component in components
        # check for special ids
        componentId = component.name
        componentInstance = @_components[componentId] = new component(options[componentId] || options)
        events = component.prototype.on
        if events?
          for event in events
            cb = component.prototype[event]
            if cb?
              @on(event, cb, componentInstance, NewClass)


  for v, getSet of getSets
    config = (__v) ->
      return {
        get: ()->
          return @[__v]
        set: (val)->
          @[__v] = val
          # execute the reactive stuff based on the getSet config.
          for getSetConfig in getSet
            getSetConfig.cb.call(@_components[getSetConfig.ctx])
      }
    Object.defineProperty(NewClass.prototype, v, config('__' + v))

  return NewClass

module.exports = Entity