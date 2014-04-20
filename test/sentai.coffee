should = require('chai').should()
Sentai = require '../lib/sentai'

describe 'Sentai.componentize', ->
  it 'should create a new Component class from a class', ->
    Component = Sentai.componentize(class Component)

    Clas = Sentai.entity(Component)
    entity = new Clas()

    component = entity._components[Component.name]
    component._entity.should.equal entity

  it 'should sync the entity with the component variables', ->
    Component = Sentai.componentize(
      class Component
        position:
          x: 1
          y: 1
        a: 2
        b: 3)
      .sync('position', {from: 'a', to: 'aa'}, {from: 'b', to: (val)-> @b = val+1})

    Clas = Sentai.entity(Component)
    entity = new Clas()

    component = entity._components[Component.name]
    entity.position.should.equal component.position
    should.not.exist(entity.a)
    entity.aa.should.equal component.a
    entity.b.should.equal component.b+1

    position = component.position =
      x: 2
      y: 2
    component.a = 22
    component.b = 33

    entity.position.should.equal position
    component.__position.should.equal position
    should.not.exist(entity.a)
    entity.aa.should.equal component.a
    entity.b.should.equal component.b+1

  it 'should chain properly', ->
    Component = Sentai.componentize(
      class Component
        position:
          x: 1
          y: 1)
    Component1 = Component
      .sync('position')
      .observes('a', 'b')
      .listensTo('tick')

    Component.should.equal Component1

describe 'Sentai.entity', ->
  it 'should create a new componentless Sentai which builds correctly', ->
    Clas = Sentai.entity()

    entity = new Clas()
    entity.context.should.equal entity

  it 'should create a new Sentai with a dummy component', ->
    Component = Sentai.componentize(class Component)

    Clas = Sentai.entity(Component)
    entity = new Clas()

    entity._components[Component.name]._entity.should.equal entity
    entity._components[Component.name].should.be.instanceof Component

  it 'should correctly bind events defined using listensTo', ->
    ticked = false

    Component = Sentai.componentize(
      class Component
        tick: ()->
          ticked = true)
      .listensTo('tick')

    Clas = Sentai.entity(Component)

    entity = new Clas()

    Clas.prototype.tick.should.exist
    entity.tick()

    ticked.should.be.true

  it 'should correctly used extended values', ->
    ticked = false

    Component = Sentai.componentize(
      class Component
      tick: ()->
        ticked = true)
      .listensTo('tick')

    Clas = Sentai.entity(Component)

    entity = new Clas()

    Clas.prototype.tick.should.exist
    entity.tick()

    ticked.should.be.true

  it 'should be reactive to observed values', ->
    varChanges = 0
    aValue = 0
    bValue = 0

    Component = Sentai.componentize(
      class Component
        change: (a, b)->
          varChanges++
          aValue = a
          bValue = b)
      .observes(change: ['a', 'b'])

    Clas = Sentai.entity(Component)

    entity = new Clas()

    entity.a = 100

    aValue.should.equal 100
    #bValue.should.equal -1
    entity.__a.should.equal 100
    entity.a.should.equal 100
    varChanges.should.equal 1

    entity.b = 200

    aValue.should.equal 100
    bValue.should.equal 200
    entity.__b.should.equal 200
    entity.b.should.equal 200
    varChanges.should.equal 2

  it 'should be reactive to synced values', ->
    varChanges = 0
    aValue = 0

    Component1 = Sentai.componentize(
      class Component1
        a: -1
        change: (a)->
          @a = a
          aValue = a
          varChanges++)
      .observes(change: 'a')

    Component2 = Sentai.componentize(
      class Component2
        a: 100)
      .sync('a')

    Clas = Sentai.entity(Component1, Component2)

    entity = new Clas()
    component1 = entity._components[Component1.name]
    component2 = entity._components[Component2.name]

    aValue.should.equal 100
    component1.a.should.equal 100
    component2.__a.should.equal 100
    component2.a.should.equal 100
    entity.__a.should.equal 100
    entity.a.should.equal 100
    varChanges.should.equal 1

    component2.a = 200

    aValue.should.equal 200
    component1.a.should.equal 200
    component2.__a.should.equal 200
    component2.a.should.equal 200
    entity.__a.should.equal 200
    entity.a.should.equal 200
    varChanges.should.equal 2

  it 'should not infinite loop if the same value is set', ->
    varChanges = 0
    aValue = 0

    Component1 = Sentai.componentize(
      class Component1
        a: 100
        change: (a)->
          @a = a
          aValue = a
          varChanges++)
      .observes(change: 'a')
      .sync('a')

    Clas = Sentai.entity(Component1)

    entity = new Clas()
    component1 = entity._components[Component1.name]

    aValue.should.equal 100
    component1.a.should.equal 100
    entity.__a.should.equal 100
    entity.a.should.equal 100
    varChanges.should.equal 1

    entity.a = 100
    varChanges.should.equal 1

    entity.a = 200
    aValue.should.equal 200
    component1.a.should.equal 200
    entity.__a.should.equal 200
    entity.a.should.equal 200
    varChanges.should.equal 2

    component1.a = 200
    varChanges.should.equal 2

    component1.a = 300
    aValue.should.equal 300
    component1.a.should.equal 300
    entity.__a.should.equal 300
    entity.a.should.equal 300
    varChanges.should.equal 3
