# Encoding

Much like WebAssembly core modules, WebAssembly components are encoded in wasm binaries files (`.wasm` files). These binary formats can also be represented 1 to 1 as WebAssembly text format (`.wat` files) which uses s-expressions to represent components. We'll largely be using wat to show examples of how components are constructed.

> For a more formal explanation of this information, checkout the ["Component Model Explainer"](https://github.com/WebAssembly/component-model/blob/main/design/mvp/Explainer.md) from the component model spec repo. This document is inspired by and based off of that document. A big shout out to everyone working on the spec for their amazing work!

## Core WebAssembly modules

WebAssembly components are backwards compatible with WebAssembly modules (often called "core modules") and core modules are embedded inside of WebAssembly components. In order to understand components, you must first understand core modules. We won't be providing a detailed explanation of core modules here. However, a good explainer can be [found on MDN](https://developer.mozilla.org/en-US/docs/WebAssembly/Understanding_the_text_format). Give that a read, and come back when you're done.

## The simplest component

Let's create the simplest component we can (which you can find in `examples/simple/simple.wat`):

```wat
(component)
```

We can validate this component is correct with `wasm-tools validate`:

```bash
# Note: `-f component-model` turns on the component model feature of the validator.
# If we don't turn this on we'll get an error.
wasm-tools validate examples/simple/simple.wat -f component-model
```

We can produce the `.wasm` binary equivalent of this component using `wasm-tools parse`:

```bash
wasm-tools parse examples/simple/simple.wat -o simple.wasm
```

While we can inspect this binary directly, we can also use another tool `wasm-tools dump` to view the binary format with helpful annotations on the side.

```bash
wasm-tools dump examples/simple/simple.wat
```

Which produces the following output:

```
 0x0 | 00 61 73 6d | version 12 (Component)
     | 0c 00 01 00
```

The binary consists of three parts:

* `00 61 73 6d` is the WebAssembly magic number which tells tooling we're looking at a WebAssembly binary. It spells "\0asm" in ASCII.
* `0c 00` is the binary version. Before the component model is standardized this will keep increasing (to ensure that it's easy to coordinate which pre-standard version the binary is). This will eventually be `01 00` when the standard is finalized.
* `01 00` is the "layer" which indicates that this is a WebAssembly component (as opposed to a core module).

## Recursive components

Components contain a sequence of definitions of various kinds. In the case of our simple component, the sequence contained no items. We'll discover over time what these items are. The first one we'll take a look at is: `component`. That's right, components can contain components.

Take the following component for example (which you can find in `examples/recursive/recursive.wat`):

```wat
(component
  (component
    (component)
  )
  (component)
)
```

We can do the same thing we did before with `wasm-tools validate`, `wasm-tools parse`, and `wasm-tools dump`.

It's important to note that components definitions are acyclic: definitions can only refer to preceding definitions. However, unlike core modules, components can arbitrarily interleave different kinds of definitions.

## Indices and identifiers

We notice something interesting when we parse our recursive example into a WebAssembly binary and then print it *back* out as wat:

```bash
wasm-tools parse examples/recursive/recursive.wat -o recursive.wasm` 
wasm-tools print recursive.wasm`
```

This gives us:

```wat
(component
  (component (;0;)
    (component (;0;))
  )
  (component (;1;))
)
```

Each component (except for the top-level one) has a `(;N;)`. These are there to indicate the *index* of that definition. Definitions that come after a given definition can refer to that definition using its index. 

Indices are not global meaning that for each nested level a new index space starts. This explains why the first two nested components both have index 0. They are the first components at their respective nesting level. These indices are also separated by which *kind* of definition being referred to. We only have component definitions right now, so everything at the same nesting level lives in the same index space, but as we introduce new definition types, definitions will have different index spaces that they occupy depending on what type they are. If this is unclear, wait until the next section when we'll introduce our next definition type: core modules.

However, to make reading `wat` files easier, `wasm-tools print` uses block comments (i.e., either between a "(;" and a ";)" which is ignored as a comment) to explicitly show what the index is.

When writing wat ourselves, we can use identifiers (in the form of `$example-id`) instead to give these indices descriptive names.

Let's modify our example to use identifiers (which you can find in `examples/recursive-ids/recursive-ids.wat`):

```wat
(component
  (component $foo
    (component $bar)
  )
  (component $baz)
)
```

If we do the same conversion as before (turning our component into a binary wasm file and then back to wat file), we can see that the identifiers are kept!

This is done through a wasm custom section which encodes the name so that the `wasm-tools` tooling suite can use the more descriptive identifier names. However, these names are just for human consumption. At the end of the day, the identifiers are equivalent to the index numbers they refer to (i.e., $foo == 0, $bar == 0, and $baz == 1). This becomes clear when we use `wasm-tools dump` to dump the recursive-ids binary and see the custom sections:

```
# ...
 0x89 | 00 03 66 6f | Naming { index: 0, name: "foo" }
      | 6f
 0x8e | 01 03 62 61 | Naming { index: 1, name: "baz" }
      | 7a
```

## Embedding core modules

Besides recursively containing components, components can also contain core WebAssembly modules. For example (which you can find in `examples/core-module/core-module.wat`):

```wat
(component
  (component
    (core module
      (import "console" "log" (func $log (param i32)))
      (func (export "logIt")
        i32.const 13
        call $log)
    )
  )
  (core module (func (export "two") (result f32) (f32.const 2)))
)
```

The wat above uses the short hand way of defining a core function type, the function definition, *and* exporting that function all at the same type. 

If we turn this wat into a WebAssembly binary and then back into wat, the tooling will use the more verbose syntax:

```wat
(component
  (component (;0;)
    (core module (;0;)
      (type (;0;) (func (param i32)))
      (type (;1;) (func))
      (import "console" "log" (func $log (;0;) (type 0)))
      (func (;1;) (type 1)
        i32.const 13
        call $log
      )
      (export "logIt" (func 1))
    )
  )
  (core module (;0;)
    (type (;0;) (func (result f32)))
    (func (;0;) (type 0) (result f32)
      f32.const 0x1p+1 (;=2;)
    )
    (export "two" (func 0))
  )
)
```

In this equivalent version, we *first* define the function type, then the function definition, and *finally* we export it. Take your time to ensure you are comfortable with both equivalent styles and can convince yourself that these two are equivalent.

It's important to note that there are two top-level definitions that this component has: the nested component which includes the core module *and* another core module that is not nested in a component. Because these definitions are of two different kinds (i.e., component and core module) they occupy two different index spaces and as such both have index 0.

## Instances

Everything we've defined so far has been immutable dead code. We can also define "instances" which represent components or core modules which have had the imports they define satisfied. For example, a core module may import `memory` to use a mutable state needed during its execution. An instance can be used to supply that core module with the memory it requires. Of course, imports can be many other things besides memory including functions.

Instances can allow us to "link" modules and components together with other modules and components by specifying that the imports one component or core module expects are satisfied by the exports of another component or core module.

Let's take a look at an example (which you can find in `examples/instance/instance.wat`):

```wat
(component
  (core module $numbers
    (func (export "one") (result i32) (i32.const 1))
  )
  (core module $doSomething
    (func (import "myNamespace" "one") (result i32))
  )
  (core instance $firstInstance (instantiate $numbers))
  (core instance $secondInstance (instantiate $doSomething (with "myNamespace" (instance $firstInstance))))
)
```

> *Note*: you may have noticed that instances have a `core` prefix associated with them. This is because, while instances are not a part of the existing ratified WebAssembly spec like core modules, they were a proposed extension to the core WebAssembly spec outside of components (i.e., they would also be useable in core modules). Instances were originally proposed as part of the [module linking](https://github.com/WebAssembly/module-linking) proposal, but that has been subsumed by the component model work.

This component consists of 4 definitions:
* Two core modules
* Two core instances

The first core module `$numbers` exports a function called "one". The second core module `$doSomething` wants to import a function called "one" in the namespace "myNamespace". 

The first core instance `$firstInstance` instantiates the `$numbers` core module. Since the `$numbers` core module expects no imports, we do not need to supply any. The second core instance `$secondInstance` instantiates the core module `$doSomething` with an instance that we're supplying under the namespace "myNamespace"). Since `$doSomething` is expecting an imported namespace "myNamespace" which contains a function named "one" and we're supplying `$firstInstance` under the namespace "myNamespace" and $firstInstance exports a function named "one", everything lines up and we form a valid component.

## Renaming with aliases

At times it might be desireable to take an export that has been exported under a certain name and import into another component or core module as a different name. This eliminates the need for exports from one module to exactly match the imports another module is expecting. To accomplish this we'll use "aliases". There are a few kind of aliases so we'll look them in turn.

### Out of line aliases

First, let's take a look at out of line aliases. Let's take a look at an example (which you can find at `examples/out-alias/out-alias.wat`):

```wat
(component
  (core module $numbers
    (func (export "one") (result i32) (i32.const 1))
    (func (export "two") (result i32) (i32.const 2))
  )
  (core module $doSomething
    (func (import "theNumbers" "myNumber") (result i32))
  )
  (core instance $firstInstance (instantiate $numbers))

  ;; Here's where things get interesting...
  (core func $two (alias core export $firstInstance "two"))
  (core instance $secondInstance (instantiate $doSomething
    (with "theNumbers" (instance
      (export "myNumber" (func $two))
    ))
  ))
)
```

We start much like our previous example by defining two core modules: `$numbers` which exports two functions and `$doSomething` which expects an import called "myNumber" under the namespace "theNumbers". We then instantiate `$numbers` as an instance called `$firstInstance`.

After that is where things get interesting. Using an `alias export` we effectively reach into `$firstInstance` and grab the export named "two" and bind that export to the name `$two`. Without this alias function we had no way to refer to that export. Now we can refer to that export as the function `$two` as if it had been defined at the top level (even when in reality it was defined inside a nested core module).

That by itself is not too interesting, but next we instantiate the core module `$doSomething` with an *inline* instance instead of providing `$firstInstance`. This inline instance exports a function called "myNumber" which is defined using the function definition `$two`. Effectively we now have a mechanism for supplying imports to an core module where we decide *at instantiation* which import to provide.

> Out of line aliases are called such since they are not defined *in-line* with the inline instance. We'll see another type of alias that allows declaring aliases inline inside of inline instance definitions.

This allows us to instantiate `$doSomething` many times where we supply the important "theNumber" "myNumber" with different definitions for each instantiation.

There is also a second syntax for declaring an out of line alias:

```wat
;; This is equivalent to `(core func $two (alias core export $firstInstance "two"))`
(alias core export $firstInstance "two" (core func $two))
```

### Inline aliases

Instead of first declaring an alias any then using that alias within an inline instance definition, you can also just declare the alias directly. The following is equivalent to the example above just using an inline alias:

```wat
(component
  (core module $numbers
    (func (export "one") (result i32) (i32.const 1))
    (func (export "two") (result i32) (i32.const 2))
  )
  (core module $doSomething
    (func (import "theNumbers" "myNumber") (result i32))
  )
  (core instance $firstInstance (instantiate $numbers))

  ;; Here's where things are different...
  (core instance $secondInstance (instantiate $doSomething
    (with "theNumbers" (instance
      (export "myNumber" (func $firstInstance "two"))
    ))
  ))
)
```

You'll notice that we are no longer first declaring an alias before instantiating `$secondInstance`. Instead we declare the alias in the same line as declaring the export of our inline instance with `(func $firstInstance "two")`. Just like before, this reaches into `$firstInstance` and brings the "two" function into scope for our use.

> *Note*: We're only showing linking of *core modules*, because we need to introduce component-level type and function definitions before we can do that.

**TODO**: Continue [here](https://github.com/WebAssembly/component-model/blob/main/design/mvp/Explainer.md#type-definitions)
