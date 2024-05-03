import std/[strutils, sequtils, options]
import ./algos

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

    start, goal:   Location
    visited:       seq[Location]
    path:          Option[Path]

# 00000 -----

var app = AppStates(
  selectedAlgo: "DFS",
  map: initMap(10, 10, free),
  tool: putWall, 
  start: (0, 0), 
  goal:  (1, 1),
  rows: 10,
  cols: 10,
  clicked: false,
)

template `%`(a): untyped = cstring $a

let pathFindingAlgos = {
  %"DFS": dfs,
  %"BFS": bfs,
  %"A*":  aStar}

# ???? -----

template genSetter(name, typ, expr): untyped = 
  proc name(a: typ) = 
    expr = a

genSetter setCols, int, app.cols
genSetter setRows, int, app.rows

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
        

proc createDom: VNode =
  proc action(l: Location) = 
    case app.tool
    of putWall : app.map[l.row][l.col] = wall
    of erase   : app.map[l.row][l.col] = free
    of putGoal : app.start             = l
    of putStart: app.goal              = l


  buildHtml tdiv:
    nav(class="navbar navbar-expand-lg bg-dark d-flex justify-content-center py-1"):
      span(class="navbar-brand text-white"):
        text "A*, BFS, DFS, Visualization"

    main(class="p-4"):

      tdiv(class="d-flex justify-content-space-between flex-row"):
        tdiv(class="w-100 d-flex align-items-center"):
          spann "cols"
          slider 1..50, app.cols, setCols

        tdiv(class="w-100 d-flex align-items-center"):
          spann "rows"
          slider 1..50, app.rows, setRows

      tdiv(class="d-flex justify-content-space-between flex-row"):
        tdiv(class="w-100 d-flex align-items-center"):
          spann "Algo"
          select(class="form-select", value = app.selectedAlgo):
            for a in pathFindingAlgos:
              option:
                text a[0]

            proc onInput(ev: Event, n: VNode) =
              app.selectedAlgo = n.value
            

      tdiv(class="d-flex justify-content-space-between flex-row"):
        tdiv(class="w-100 d-flex align-items-center"):
          spann "Tool"
          select(class="form-select", value = %app.tool):
            for k in Tool:
              option(value = %k):
                text %k

            proc onInput(ev: Event, n: VNode) =
              app.tool = parseEnum[Tool]($n.value)
            


      tdiv(class="map"):
        for y, row in app.map:
          tdiv(class="d-block"):
            for x, cell in row:
              let 
                loc  = (y, x)
                indx = app.path.get(@[]).find loc
                lbl  = 
                  if indx == -1: %""
                  else:          %(indx+1)
                cls  = 
                  if   loc  == app.start:   "cell-start"
                  elif loc  == app.goal:    "cell-goal"
                  elif indx != -1:          "cell-path"
                  elif loc  in app.visited: "cell-visited"
                  elif cell == wall:        "cell-filled"
                  else:                     "cell-empty"

              genCell y, x, %cls, lbl, action

# entry point -----

when isMainModule:
  setRenderer createDom
