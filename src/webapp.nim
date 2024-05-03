import std/[strutils, sequtils, options, random, tables]
import ./algos

import std/jscore
include karax/prelude

# 00000 -----

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

# 00000 -----

randomize()

proc randomLocation(rows, cols: Positive, offset = 1): Location = 
  (rand offset ..< rows-offset, rand offset ..< cols-offset)

const 
  C = 10
  R = 10
  sizeLimit = 100

var app = AppStates(
  selectedAlgo: "DFS",
  rows:         R,
  cols:         C,
  map:          initMap(R, C, free),
  tool:         putWall, 
  start:        randomLocation(R, C), 
  goal:         randomLocation(R, C),
  clicked:      false,
)

template `%`(a): untyped = cstring $a

let pathFindingAlgos = toOrderedTable {
  %"DFS": dfs,
  %"BFS": bfs,
  %"A*":  aStar}

# ???? -----

template timeit(res, body): untyped = 
  let t1 = Date.now
  body
  let t2 = Date.now
  let res = t2 - t1

# UI -----

proc slider(rng: Slice[int], init: int, setter: proc(a: int)): Vnode = 
  buildHtml tdiv(class="col-sm-10"):
    input(type= "number", class= "form-control", 
      min=    %rng.a,
      max=    %rng.b,
      step=   %1, 
      value = %init
    ):
      proc onInput(ev: Event, n: VNode) =
        setter parseInt n.value

proc pairlog(lbl: cstring, val: cstring): Vnode = 
  buildHtml span:
    text lbl
    text ": "
    text val

proc spann(lbl: cstring): Vnode = 
  buildHtml:
    span(class="me-2"):
      text lbl

proc genCell(row, col: int, cls, lbl: cstring, action: proc(loc: Location)): VNode = 
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

proc resetPath = 
    reset app.visits
    reset app.path

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
          slider 1..sizeLimit, app.cols, proc(val: int) = 
            app.cols = val
            app.map = initMap(app.rows, app.cols, free)

        tdiv(class="w-100 d-flex align-items-center"):
          spann "rows"
          slider 1..sizeLimit, app.rows, proc(val: int) = 
            app.rows = val
            app.map = initMap(app.rows, app.cols, free)

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
        
        else:
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
            timeit res:
              let pack = algo(app.map, app.start .. app.goal)
            
            app.benchmark = res
            app.visits    = pack.visits
            app.path      = pack.finalPath
        
        button(class = "btn btn-danger w-100 mx-3"):
          text "Random"

          proc onclick = 
            resetPath()

            let treshold = rand 0.0 .. 0.3
            for y, row in app.map:
              for x, _ in row:

                app.map[y][x] = 
                  if   y in [0, app.map.height-1] or x in [0, row.len-1]: wall
                  elif treshold < rand 0.0 .. 1.0:                        free
                  else:                                                   wall

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

              genCell y, x, %cls, lbl, action

# entry point -----

when isMainModule:
  setRenderer createDom
