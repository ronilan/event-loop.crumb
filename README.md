# event-loop.crumb

`event-loop.crumb` is a [Crumb](https://github.com/liam-ilan/crumb) usable providing a basic event loop.

The event loop builds on Crumbs native `until` and `event` functions, providing the user with an abstracted way to interact with keypress and mouse events. Current implementation supports five events: **state**, **loop**, **keypress**, mouse **move** and mouse **click**.

## Usage

1. Download https://github.com/ronilan/event-loop.crumb/blob/main/event-loop.crumb
2. Place it in your Crumb project
3. Use it.

## Basics

The `event-loop` function expects two parameters `state` and `listeners`
- `state` is a data structure of the user choice that will persist between loops.
- `listeners`: `list` - a list of "entities" listening to events. Each "entity" is by itself a `list` containing exactly five event functions. Each of those functions will be called when each of the currently supported events happens. Listeners are proccessed in the order in which they are listed and the functions are called in the following order: 1 (loop), 2 (keypress), 3 (mouse move), 4 (mouse click) and finally 0 (state changed).

A minimal example that prints a never ending progress bar will look like this:
```
listeners = (list 
  (list void {(print "=")} void void void) // state loop keypress move click
)
state = void

// event loop
(use "./event-loop.crumb" {
  <- (start state listeners)
})
```

With Crumb's dynamic scoping, event functions are executed in `event-loop` scope. This allows event functions to "magically" access parameters defined within the event loop.

By virtue of being called from inside the `until` event loop, all event functions have access to:
- `state`: `any` - the current state.
- `loop-count`: `integer` - the number of loops since the event loop started.

The current implementation also exposes the following:
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

Each event function, if defined, is expected to return a state (modified or unmodified).

A minimal reactive example that prints bars of increasing length whenever the state changes will look like this:

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

## Examples

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

WIP

###### Fabriqué au Canada : Made in Canada 🇨🇦
