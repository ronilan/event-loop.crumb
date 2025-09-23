# event-loop.crumb

`event-loop.crumb` is a [Crumb](https://github.com/liam-ilan/crumb) usable providing a basic event loop.

The event loop builds on Crumbs native `until` and `event` functions, providing the user with an abstracted way to interact with keypress and mouse events and to react to state changes. Current implementation supports five events: **state**, **loop**, **keypress**, mouse **move** and mouse **click**.

## Usage

1. Download https://raw.githubusercontent.com/ronilan/event-loop.crumb/main/event-loop.crumb
2. Place it in your Crumb project. (see: [Crumb Template](https://github.com/liam-ilan/crumb-template) for an easy starter.)
3. Use it.

## Basics

The `event-loop` function expects three parameters: `state`, `listeners` and `time`.
- `state` is a data structure of the user choice that will persist between loops.
- `listeners`: `list` - a list of "entities" listening to events. Each "entity" is by itself a `list` containing exactly eight event functions (a.k.a call back functions). Each of those functions will be called when each of the currently supported events happens.
- `time`: integer or float - the time in seconds, rounded up to the nearest 100 ms, to wait for an event before looping. the value is passed to Crumb's native `event` function. If set to `void` the value will be omitted and the loop will block until an event is received. With complex applications, when no loop animation is required, setting to`void` will improve responsiveness.

A minimal example that prints a never ending progress bar will look like this:
```
listeners = (list 
  (list void { (print "=") } void void void void void void)
)

state = 0

// event loop
(use "./event-loop.crumb" {
  <- (start state listeners 0.1)
})
```

Functions are called in the following order: 1 (loop), 2 (keypress), 3 (mouse down), 4 (mouse up), 5 (mouse move), 6 (mouse drag), 7 (mouse scroll) and finally 0 (state changed). Listeners are processed in the order in which they are listed. This means that if there are, for example, three listeners, than the first function called will be the event function of the first listener and the second function called will be the loop function of the second listener and so on.

With Crumb's dynamic scoping, event functions are executed in loop scope. Being executed in that scope allows the functions to "magically" access variables that were not explicitly passed into them. This includes `state` and `loop_count` that are used by the native `until` loop as well as several variables originating from event capturing. See [In Scope Variables](#in-scope-variables) reference for more.

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
  } void void void void void)

listener_2 = (list void {
    (print "2")
    <- state
  } {
    (print "key2")
    <- state
  } void void void void void)

listeners = (list 
  listener_1
  listener_2
)

// event loop
(use "./event-loop.crumb" {
  <- (start 0 listeners 0.1)
})
```

The following reactive example prints bars of increasing length whenever the mouse is moved and the state changes as a result:

```
on_move = { 
  <- (add state 1)
}

on_state = {
  (print (reduce (map (range state) {_ _ -> <- "="}) {accum item _ -> <- (join accum item)} "") "\n")
  <- state
}

listeners = (list 
  (list on_state void void void void on_move void void)
)

state = 1

// event loop
(use "./event-loop.crumb" {
  <- (start state listeners void)
})
```

The following example shows how to capture all events and use the state event for rendering:
```
on_state = {
  (print "\e[2J\e[H")
  (print
    (join
      (join "loop: " (string (get state 0))) "\n"
      (join "key: " (get state 1)) "\n"
      (join "down: " (get state 2)) "\n"
      (join "up: " (get state 3)) "\n"
      (join "move xy: " (string (get (get state 4) 0)) ":" (string (get (get state 4) 1))) "         \n"
      (join "drag xy: " (string (get (get state 5) 0)) ":" (string (get (get state 5) 1))) "         \n"
      (join "scroll: " (get state 6)) "\n"
      "\n"
    )
  )

  <- state
}

on_loop = {
  state = (set state "" 1)
  state = (set state "" 2)
  state = (set state "" 3)
  state = (set state "" 6)
  state = (set state loop_count 0)
  
  <- state
}

on_keypress = {
  <- (set state keypress_name 1)
}

on_down = {
  <- (set state (string mouse_code) 2)
}

on_up = {
  <- (set state (string mouse_code) 3)
}

on_move = {
  <- (set state mouse_xy 4)
}

on_drag = {
  <- (set state mouse_xy 5)
}

on_scroll = {
  <- (set state (string scroll_direction) 6)
}

listeners = (list 
  (list
    on_state      //0
    on_loop       //1
    on_keypress   //2
    on_down       //3
    on_up         //4
    on_move       //5
    on_drag       //6
    on_scroll     //7
  ) 
)

state = (list 0 "" "" "" (list 0 0) (list 0 0) "")

// set up: hide cursor and clear
(print "\e[?25l\e[2J\e[H")
// initial render
(on_state)

// event loop
(use "./event-loop.crumb" {
  <- (start state listeners 0.1)
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

- `scroll_direction`: `string` - the direction of scroll detected either `up`, `down` `left` `right`. Available to the scroll event function (third in list).

###### Fabriqué au Canada : Made in Canada 🇨🇦
