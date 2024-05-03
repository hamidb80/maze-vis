import std/[strutils, options, random, tables]
import ./algos

import std/jscore
include karax/prelude

# types -----

type 
  Tool = enum
    putWall  = "put wall"
    erase    = "erase"
    putGoal  = "put goal"
    putStart = "put start"

  AppStates = object
    selectedAlgo: cstring
    tool:         Tool

    rows, cols:   Positive
    map:          Map[Cell]

    hoverCell:    Option[Location]
    clicked:      bool

    start, goal:  Location
    visits:       seq[Location]
    path:         Option[Path]
    benchmark:    Natural

# js ------

template `%`(a): untyped = cstring $a

template timeit(res, body): untyped = 
  let t1 = Date.now
  body
  let t2 = Date.now
  let res = t2 - t1

# utils -----

proc randomLocation(rows, cols: Positive, offset = 1): Location = 
  (rand offset ..< rows-offset, rand offset ..< cols-offset)

# globals -----

randomize()

const 
  C = 10
  R = 10
  sizeLimit = 100

let pathFindingAlgos = toOrderedTable {
  %"DFS":   dfs,
  %"IDDFS": iddfs,
  %"BFS":   bfs,
  %"A*":    aStar,
}

# state management -----

var app = AppStates(
  selectedAlgo: "DFS",
  rows:         R,
  cols:         C,
  map:          initMap(R, C, free),
  tool:         putWall, 
  start:        randomLocation(R, C), 
  goal:         randomLocation(R, C),
  clicked:      false)

proc cleanErrors = 
  for loc in [app.start, app.goal]:
    app.map[loc] = free

proc randomJourney = 
  app.start = randomLocation(app.rows, app.cols) 
  app.goal = randomLocation(app.rows, app.cols) 
  cleanErrors()

proc regenerateMap = 
  proc fromPast(row, col: int): Cell = 
    let loc = (row, col)
    if loc in app.map: app.map[loc]
    else:              free

  app.map = initMap[Cell](app.rows, app.cols, fromPast)
  if app.start notin app.map or app.goal notin app.map:
    randomJourney()
    
proc resetPath = 
    reset app.visits
    reset app.path

# UI -----

proc rangedInput(rng: Slice[int], init: int, setter: proc(a: int)): Vnode = 
  buildHtml tdiv(class="col-sm-10"):
    input(type= "number", class= "form-control", 
      min=    %rng.a,
      max=    %rng.b,
      step=   %1, 
      value = %init
    ):
      proc onInput(ev: Event, n: VNode) =
        setter parseInt n.value

proc spann(lbl: cstring): Vnode = 
  buildHtml:
    span(class="me-2"):
      text lbl

proc cellComponent(row, col: int, cls, lbl: cstring, action: proc(loc: Location)): VNode = 
  buildHtml:
    tdiv(class="map-cell d-inline-block border no-select pointer " & cls):
      span:
        text lbl

      proc onmouseup = 
        app.clicked = false

      proc onmousedown = 
        app.clicked = true

      proc onmouseenter =
        app.hoverCell = some (row, col)

      proc onmousemove = 
        if app.clicked:
          action (row, col)

      proc onclick = 
        action (row, col)


proc createDom: VNode =
  proc action(l: Location) = 
    case app.tool
    of putWall:  app.map[l.row][l.col] = wall
    of erase:    app.map[l.row][l.col] = free
    of putStart: app.start             = l
    of putGoal:  app.goal              = l
    resetPath()

  buildHtml tdiv:
    nav(class="navbar navbar-expand-lg bg-dark d-flex justify-content-center py-1"):
      span(class="navbar-brand text-white"):
        text "A*, BFS, DFS, Visualization"

    main(class="p-4"):
      tdiv(class="d-flex justify-content-space-between flex-row"):
        tdiv(class="w-100 d-flex align-items-center"):
          spann "cols"
          rangedInput 3..sizeLimit, app.cols, proc(val: int) = 
            app.cols = val
            regenerateMap()

        tdiv(class="w-100 d-flex align-items-center"):
          spann "rows"
          rangedInput 3..sizeLimit, app.rows, proc(val: int) = 
            app.rows = val
            regenerateMap()

        tdiv(class="w-100 d-flex align-items-center"):
          spann "Algo"
          select(class="form-select", value = app.selectedAlgo):
            for k, _ in pathFindingAlgos:
              option:
                text k

            proc onInput(ev: Event, n: VNode) =
              app.selectedAlgo = n.value
            
        tdiv(class="w-100 d-flex align-items-center"):
          spann "Tool"
          select(class="form-select", value = %app.tool):
            for k in Tool:
              option(value = %k):
                text %k

            proc onInput(ev: Event, n: VNode) =
              app.tool = parseEnum[Tool]($n.value)

    tdiv(class="px-4 py-1"):
      if not empty app.visits:
        if isNone app.path:
          h4(class="text-center text-info"):
            text "No path found!"

        tdiv(class="d-flex justify-content-around"):
          h5(class=""):
            text "opened nodes: "
            text %app.visits.len
          h5(class=""):
            text "time: "
            text %app.benchmark
            text "ms"

    main(class="px-4 py-1"):
      tdiv(class="d-flex justify-content-space-between flex-row"):
        button(class = "btn btn-primary w-100 mx-3"):
          text "Find Path"

          proc onclick = 
            let algo  = pathFindingAlgos[app.selectedAlgo]
            timeit time:
              let pack = algo(app.map, app.start .. app.goal)
            
            app.benchmark = time
            app.visits    = pack.visits
            app.path      = pack.finalPath
        
        button(class = "btn btn-danger w-100 mx-3"):
          text "Random"

          proc onclick = 
            let treshold = rand 0.0 .. 0.3

            proc cellValue(row, col: int): Cell = 
              if   row in [0, app.rows-1]:      wall
              elif col in [0, app.cols-1]:      wall
              elif treshold < rand 0.0 .. 1.0:  free
              else:                             wall

            app.map = initMap(app.rows, app.cols, cellValue)
            randomJourney()
            resetPath()

        button(class = "btn btn-warning w-100 mx-3"):
          text "Clear"

          proc onclick = 
            app.map = initMap(app.rows, app.cols, free)
            resetPath()

    main(class="p-4 d-flex justify-content-center"):
      tdiv(class="overflow-auto"):
        for y, row in app.map:
          tdiv(class="d-flex"):
            for x, cell in row:
              let 
                loc  = (y, x)
                indx = app.path.get(@[]).find loc
                lbl  = 
                  if indx == -1: %""
                  else:          %indx
                cls  = 
                  if   loc  == app.start:   "cell-start"
                  elif loc  == app.goal:    "cell-goal"
                  elif indx != -1:          "cell-path"
                  elif loc  in app.visits:  "cell-visited"
                  elif cell == wall:        "cell-filled"
                  else:                     "cell-empty"

              cellComponent y, x, %cls, lbl, action

# entry point -----

when isMainModule:
  setRenderer createDom
