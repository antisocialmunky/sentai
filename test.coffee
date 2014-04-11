should = require('chai').should()
Entity = require './Entity'

describe 'Entity.Class', ->
  it 'should create a new componentless Entity which builds correctly', ->
    Clas = Entity.Class([])

    entity = new Clas()
    entity.context.should.equal entity

  it 'should create a new Entity with a dummy component', ->
    class Component1 extends Entity.Component

    Clas = Entity.Class([Component1])

    entity = new Clas()

    entity._components['Component1'].entity.should.equal entity
    entity._components['Component1'].should.be.instanceof Component1

  it 'should correctly bind events defined using on', ->
    ticked = false
    class Component1 extends Entity.Component
      on: ['tick']
      tick: ()->
        ticked = true

    Clas = Entity.Class([Component1])

    entity = new Clas()

    entity.tick.should.exist
    entity.tick()

    ticked.should.be.true

  it 'should be reactive to observed values values', ->
    varChanges = 0
    class Component1 extends Entity.Component
      on: ['tick']
      obs: 
        change: ['a', 'b']
      change: ()->
        varChanges++

    Clas = Entity.Class([Component1])

    entity = new Clas()

    entity.a = 100

    entity.__a.should.equal 100
    entity.a.should.equal 100
    varChanges.should.equal 1

    entity.b = 200

    entity.__b.should.equal 200
    entity.b.should.equal 200
    varChanges.should.equal 2