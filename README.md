#Introduction

This is a Reactive Component Entity System

It is pretty experimental.  I'm mostly trying find a cute API.

#SENTAI
**noun**

1. In Japanese, sentai (戦隊?) is a military unit and may be literally translated as "squadron", "task force", "group" or "wing". The terms "regiment" and "flotilla", while sometimes used as translations of Sentai, are also used to refer to larger formations.

2. The **Super Sentai Series** (スーパー戦隊シリーズ **Sūpā Sentai Shirīzu?**) is a franchise of Japanese tokusatsu television dramas that uses the word sentai to describe a **group of three or more costumed superheroes who often pilot fictional robotic vehicles.**

#Features
* This is a variant of a Component Entity System.
* Entity is a dictionary of values synchronized from components.
* Components self contained classe are aware of only the entity they are attached to.
* Functionality is driven by reactivity.

#Usage

####Component = sentai.componetize(Class[, extends])
Create a new class with componentization that extends class and contains the properties on extends.  The returned Component will contain the following chainable functions.

####Component = Component.syncs(prop1 [, prop2]...)
Pass in a list of strings corresponding to properties on the component that will be pushed to the server on update.  You can also supply an object specifying a mapping between component and entity properties:

```coffeescript
{ 
  from: 'component prop', 
  to: 'entity prop' 
}
```
or you can bind to a function that executes with this set to the entity:

```coffeescript
{ 
  from: 'component prop', 
  to: (val)->
    @entityProperty = val
}
```

####Component = Component.listensTo(event1 [, event2]...)
Pass in a list of events corresponding to methods on the component that will be triggered by events issued on the parent entity.  Event1, event2... can either be strings or:

```coffeescript
{ 
  on: 'event from entity', 
  do: 'method on component' 
}
```

Events can be fired by calling methods by registered event names on the entity (entity['new form event']() in the above case).

####Component = Component.observes(dependencyMap)
Pass in a dictionary in the form of:

```coffeescript
{
  methodOnComponent : ['property on parent entity 1', 'property on parent entity 2']
}
```
where:
```coffeescript
  methodOnComponent: (prop1, prop2) ->
```

Any updates to those properties on the entity will cause the method to trigger.  This is really useful when combined with syncs from a separate components.

####Entity = sentai.entity(component1 [, component2]...)
The passed in components are bound to the Entity.

####Entity.constructor(options)
An options object which is pass to the components.  Components can have specific options which can be set by initializing a options object on options[component1.type].

#Example

Require sentai.
```coffeescript
sentai = require sentai
```
Componentize some classes.
```coffeescript
# Use requisite (https://www.npmjs.org/package/requisite) to make this work in the browser
$ = require 'jquery'

class DomTextRenderer
  element: null
  constructor: (options)->
    @element = $('<div>#{ options.text }</div>')
    $('body').append(@element)
  updatePosition: (x, y)->
    @element.css(
      left: x
      top: y)

class RandomPosition
  x: 0
  y: 0
  constructor: (options)->
    @x = options.x if options.x?
    @y = options.y if options.y?
  tick: ()->
    @x = Math.random() * $('body').width()
    @y = Math.random() * $('body').height()
```

Configure their reactivity.  
```coffeescript
DomTextRendererComponent = sentai.componentize(DomTextRenderer)
  .observes(updatePosition: ['x','y'])
  
RandomPositionComponent = sentai.componentize(RandomPosition)
  .syncs('x','y')
  .listensTo('tick')
```

Add them to entities and trigger events on entity defined by component listenTo's
```coffeescript
JumpingText = sentai.entity(DomTextRenderer, RandomPosition)

jumpingHelloWorld = new JumpingText(
  x: 100
  y: 100
  text: 'HelloWorld')

setInterval(()->
  jumpingHelloWorld.tick()
  , 1)
```

#License
Copyright (c) 2014 David Tai

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
