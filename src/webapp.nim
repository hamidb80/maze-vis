import std/[sequtils, options]
import ./algos

include karax/prelude

# 00000 -----

type 
  Tool = enum
    putWall
    putGoal
    putStart
    erase

  AppStates = object
    selectedAlgo: string
    tool: Tool
    map: Map[Cell]
    rows, cols: Positive

    hoverCell: Option[Location]
    clicked: bool

# 00000 -----

var app = AppStates(
  selectedAlgo: "DFS",
  map: initMap(10, 10, free),
  tool: 
  rows: 10,
  cols: 10,
  clicked: false,
)

let pathFindingAlgos = {
  "DFS": dfs,
  "BFS": bfs,
  "A*":  aStar}

# ???? -----

template genSetter(name, typ, expr): untyped = 
  proc name(a: typ) = 
    expr = a

genSetter setCols, int, app.cols
genSetter setRows, int, app.rows

# UI -----

template `%`(a): untyped = cstring $a

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

proc genCell(row, col: int): VNode = 
  buildHtml:
    tdiv(class="map-cell no-select pointer d-inline-block border border-light"):
      span:
        text %col

      proc onmousedown = 
        app.clicked = false

      proc onmousedown = 
        app.clicked = true

      proc onmouseenter() =
        app.hoverCell = some (row, col)

      proc onmousemove = 
        if app.clicked:
          echo (row, col)

proc createDom: VNode =
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


      tdiv(class="map"):
        for y, row in app.map:
          tdiv(class="d-block"):
            for x, cell in row:
              genCell y, x, cell, is

# entry point -----

when isMainModule:
  setRenderer createDom
