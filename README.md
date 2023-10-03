# event-loop.crumb

`event-loop.crumb` is a [Crumb](https://github.com/liam-ilan/crumb) usable providing a basic event loop.

The event loop builds on Crumbs native `until` and `event` functions, providing the user with an abstracted way to interact with keypress and mouse events and to react to state changes. Current implementation supports five events: **state**, **loop**, **keypress**, mouse **move** and mouse **click**.

## Usage

1. Download https://github.com/ronilan/colors.crumb/blob/main/colors.crumb
2. Place it in your Crumb project. (see: [Crumb Template](https://github.com/liam-ilan/crumb-template) for an easy starter.)
3. Use it.

## Basics

The `event-loop` function expects two parameters `state` and `listeners`
- `state` is a data structure of the user choice that will persist between loops.
- `listeners`: `list` - a list of "entities" listening to events. Each "entity" is by itself a `list` containing exactly five event functions (a.k.a call back functions). Each of those functions will be called when each of the currently supported events happens.

A minimal example that prints a never ending progress bar will look like this:
```
listeners = (list 
  (list void {
    (print "=")
    // must return state
    <- state
  } void void void)
)

// state needs to be anything other than void for loop to run
state = 0

// event loop
(use "./event-loop.crumb" {
  <- (start state listeners)
})
```

Functions are called in the following order: 1 (loop), 2 (keypress), 3 (mouse move), 4 (mouse click) and finally 0 (state changed). Listeners are processed in the order in which they are listed. This means that if there are, for example three listeners, than the first function called will be the event function of the first listener and the second function called will be the loop function of the second listener and so on.

With Crumb's dynamic scoping, event functions are executed in loop scope. This allows event functions to "magically" access variables defined within the `until` event loop. This includes `state` and `loop_count` that are used by the native `until` loop as well as several variables originating from event capturing. See [In Scope Variables](#in-scope-variables) reference for more.

When an event function is not needed, it can be listed as `void`, however, if defined it is required to return a state (modified or unmodified).

The event loop will terminate when the state value is changed to `void`. It will then return the last state before being voided.

## Examples

The following example prints a never ending stream of `1` and `2`. Whenever a key is pressed it will add `key1` and `key2` to the stream.

```
listener_1 =   (list void {
    (print "1")
    <- state
  } {
    (print "key1")
    <- state
  } void void)

listener_2 = (list void {
    (print "2")
    <- state
  } {
    (print "key2")
    <- state
  } void void)

listeners = (list 
  listener_1
  listener_2
)

// event loop
(use "./event-loop.crumb" {
  <- (start 0 listeners)
})
```

The following reactive example prints bars of increasing length whenever the state changes will look like this:

```
on_loop = { 
  <- (add state 1)
}

on_state = {
  (print (reduce (map (range state) {_ _ -> <- "="}) {accum item _ -> <- (join accum item)} "") "\n")
  <- state
}

listeners = (list 
  (list on_state on_loop void void void) // state loop keypress move click
)

state = 1

// event loop
(use "./event-loop.crumb" {
  <- (start state listeners)
})
```

The following example shows how to capture all event events and use the state event for rendering
```
on_state = {
  (print "\e[2J\e[H")
  (print
    (join
      (join "loop: " (string (get state 0))) "\n"
      (join "key: " (get state 1)) "\n"
      (join "mouse xy: " (string (get (get state 2) 0)) ":" (string (get (get state 2) 1))) "         \n"
      (join "click: " (get state 3)) "\n"
      "\n"
    )
  )

  <- state
}

on_loop = {
  state = (set state "" 1)
  state = (set state "" 3)
  state = (set state loop_count 0)
  <- state
}

on_keypress = {
  <- (set state keypress_name 1)
}

on_move = {
  <- (set state mouse_xy 2)
}

on_click = {
  <- (set state (string mouse_code) 3)
}

listeners = (list 
  (list
    on_state
    on_loop
    on_keypress
    on_move
    on_click
  ) 
)

state = (list 0 "" (list 0 0) "")

// set up: hide cursor and clear
(print "\e[?25l\e[2J\e[H")
// initial render
(on_state)

// event loop
(use "./event-loop.crumb" {
  <- (start state listeners)
})

// tear down: show cursor and clear
(print "\e[?25h\e[2J\e[H")
```

## Running Examples

### With Docker:

Build: 
```
docker build -t event-loop.crumb git@github.com:ronilan/event-loop.crumb.git#main
```
Run: 
```
docker run --rm -it event-loop.crumb
```

Or "all in one": 
```
docker run --rm -it $(docker build -q git@github.com:ronilan/event-loop.crumb.git#main)
```

Then in the shell: 
```
./crumb examples/10-print.crumb
```

### Locally

Clone the repo: 
```
git clone git@github.com:ronilan/event-loop.crumb.git
```

CD into directory: 
```
cd event-loop.crumb
```

Build Crumb interpreter: 
```
chmod +x build-crumb.sh && ./build-crumb.sh
```

Run:
```
./crumb examples/demo.crumb
```

## Reference 

### Functions
- `(start state listeners)`
  - Returns last state before exit.
  - `state` is a data structure of the user choice that will persist between loops.
  - `listeners`: `list` - a list of "entities" listening to events. Each "entity" is by itself a `list` containing exactly five event functions: 0 (state changed), 1 (loop), 2 (keypress), 3 (mouse move), 4 (mouse click). Functions can be void. If defined they must return `state`.

### In Scope Variables

- `state`: `any` - the current state.
- `loop-count`: `integer` - the number of loops since the event loop started.

- `keypress_name`: `string` - the name of the key pressed detected (e.g `a`, `A` `up`). Available to the keypress event function (third in list).

- `mouse_xy`: `list` - the x (`number`) and y (`number`) coordinates  of the mouse with top left being `0 0`. Available to the mouse event functions (fourth and fifth in list).

- `mouse_code`: `number` - the code of the mouse event captured. Available to the mouse event functions (fourth and fifth in list). Codes are as follows:
  * `0` - left mouse click
  * `4` - `shift` left mouse click
  * `8` - `meta` left mouse click
  * `16` - `control` left mouse click
  * `32` - left click and move ("drag")
  * `36` - `shift` left click and move ("drag")
  * `40` - `meta` left click and move ("drag")
  * `48` - `control` left click and move ("drag")

###### Fabriqué au Canada : Made in Canada 🇨🇦
