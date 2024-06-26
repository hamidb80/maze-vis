import std/[options, sets, hashes, deques, tables, algorithm, math, sugar, strutils, heapqueue, random, sequtils]

# structures ------------------------------------

type
    Cell* = enum
        free
        wall

    Map*[T] = seq[seq[T]]

    Vector2 = tuple
        x, y: int

    Location* = tuple
        row, col: int

    Trip* = object 
        map*: Map[Cell]
        journey*: Journey

    Path* = seq[Location]
    Journey* = Slice[Location]

    ResultPack* = object
        visits*: seq[Location]
        finalPath*: Option[Path]

    PathFindingAlgo* = proc(
        map: Map[Cell], 
        journey: Journey,
    ): ResultPack # {.nimcall.}

    Frontier = tuple
        # index: int
        loc: Location
        cost, priority: float

    CellGenerator[T] = proc(row, col, rows, cols: int): T

    Direction = enum
        up
        right
        down
        left


# utils ------------------------------------------

func popd(s: var seq) = 
    ## delete the last index
    del s, s.high

func empty*[T](s: T): bool = 
    let z = 
        when compiles(len s): len  s
        else:                 size s
    0 == z

# func `-`(vec: Vector2): Vector2 =
#     (-vec.x, -vec.y)

func `+`(loc: Location, vec: Vector2): Location = 
    (loc.row + vec.y, loc.col + vec.x)

func `-`(a, b: Location): Location = 
    (a.row - b.row, a.col - b.col)

func `-`*[T](s: seq[T], v: T): seq[T] =
    s.mapIt it - v

func `-`*[T](s: Slice[T], v: T): Slice[T] =
    s.a - v .. s.b - v


func resize*(m: var Map, rows, cols: Positive) = 
    setlen m, rows
    for r in mitems m:
        setlen r, cols

func initMap*[T](rows, cols: int, init: CellGenerator[T]): Map[T] {.effectsOf: init.} =
    resize result, rows, cols

    for y in 0 ..< rows:
        for x in 0 ..< cols:
            result[y][x] = init(y, x, rows, cols)

func cols*(map: Map): Natural = 
    len map[0]

func rows*(map: Map): Natural = 
    len map

func contains*(map: Map, loc: Location): bool = 
    loc.row in 0 ..< map.rows and
    loc.col in 0 ..< map.cols 

func `[]`*[T](map: Map[T], loc: Location): T = 
    map[loc.row][loc.col]

func `[]=`*[T](map: var Map[T], loc: Location, val: T) = 
    map[loc.row][loc.col] = val


proc randomLocation*(rows, cols: Positive, offset = 1): Location = 
  (rand offset ..< rows-offset, rand offset ..< cols-offset)

proc cellGenerator(treshold: float, offset = 0): auto =
  proc (row, col, rows, cols: int): Cell = 
    let r = rand 0.0 .. 1.0
    if   row < offset or row >= rows-offset: wall
    elif col < offset or col >= cols-offset: wall
    elif treshold < r:                       free
    else:                                    wall

proc randomTrip*(rows, cols: int, treshold: float, offset = 0): Trip = 
  Trip(
    journey: randomLocation(rows, cols, offset) .. randomLocation(rows, cols, offset),
    map: initMap(rows, cols, 
                cellGenerator(rand 0.0 .. treshold, offset)))
  

# helpers ------------------------------------------

const moves: array[Direction, Vector2] = [
    ( 0, -1),
    (+1,  0),
    ( 0, +1),
    (-1,  0)]

func canGo(loc:  Location, map:  Map[Cell]): bool =
    loc      in map  and
    map[loc] != wall

iterator neighbors(loc: Location, map: Map[Cell]): Location = 
    for m in moves:
        let n = loc + m
        if n.canGo map:
            yield n

func manhattanDistance*(a, b: Location): float =
    toFloat:
        abs(a.col - b.col) +
        abs(a.row - b.row)

func euclideanDistance*(a, b: Location): float =
    sqrt:
        pow(float(a.col) - float(b.col), 2) +
        pow(float(a.row) - float(b.row), 2)

# conventions ---------------------------------------------

func `~~>`*(t: Trip, f: PathFindingAlgo): ResultPack {.effectsOf: f.} = 
    f t.map, t.journey

# debug --------------------------------------------

func initTrip*(grid: string): Trip = 
    let board = splitLines strip dedent grid
    setLen result.map, len board
    for y, row in board:
        setLen result.map[y], len row
        for x, cell in row:
            case cell
            of '.': 
                discard
            of '#': 
                result.map[y][x] = wall
            of 'S': 
                result.journey.a = (y, x)
            of 'E': 
                result.journey.b = (y, x)
            else: 
                raise newException(ValueError, "invalid char")   


func crop*(p: Path, area: Slice[Location]): Path =
    p.mapIt it - area.a

func crop*(m: Map, area: Slice[Location]): Map =
    let crows = m[area.a.row .. area.b.row]
    crows.mapIt it[area.a.col .. area.b.col]

func area*(points: seq[Location]): Slice[Location] =
    result = points[0] .. points[0]
    for p in points:
        result.a.col = min(result.a.col, p.col)
        result.a.row = min(result.a.row, p.row)
        result.b.col = max(result.b.col, p.col)
        result.b.row = max(result.b.row, p.row)


proc plot*(trip: Trip, rp: ResultPack): string = 
    result = newStringOfCap trip.map.rows * (trip.map.cols + 1)
    
    for y, row in trip.map:
        for x, cell in row:
            let p = (y, x)
            add result:
                if   p == trip.journey.a:     'S'
                elif p == trip.journey.b:     'E'
                elif p in rp.visits: 
                    if p in rp.finalPath.get: '_'
                    else:                     '.'
                elif cell == wall:            '#'
                else:                         ' '
        add result, '\n'

proc plot*(trip: Trip): string = 
    plot trip, ResultPack()


template unnamed*(loc: Location): untyped =
    cast[(int, int)](loc)

template unnamed*(j: Slice[Location]): untyped =
    (unnamed j.a) .. (unnamed j.b)

template unnamed*(locs: seq[Location]): untyped =
    cast[seq[(int, int)]](locs)

# impl ---------------------------------------------

func dfsImpl(
    map: Map[Cell], 
    remainingSteps: int, 
    current, goal: Location, 
    seen:   var HashSet[Location],
    path:   var Path,
    result: var ResultPack
) = 
    add  result.visits, current
    incl seen, current

    if current == goal:
        result.finalPath = some path 
        return
    elif 0 < remainingSteps:
        for loc in current.neighbors map:
            if  loc notin seen:
                add       path, loc
                dfsImpl   map, remainingSteps - 1, loc, goal, seen, path, result
                if issome result.finalPath: return
                popd      path

func dfsImpl(map: Map[Cell], maxDepth: int, journey: Journey): ResultPack = 
    var
        seen: HashSet[Location]
        path: Path = @[journey.a]
    dfsImpl map, maxDepth, journey.a, journey.b, seen, path, result

func dfs*(map: Map[Cell], journey: Journey): ResultPack = 
    dfsImpl map, map.cols * map.rows, journey

func iddfs*(map: Map[Cell], journey: Journey): ResultPack =
    for d in 1 .. map.cols * map.rows:
        result = dfsImpl(map, d, journey)
        if issome result.finalPath:
            return


func backtrack(tail, head: Location, track: proc(loc: Location): Location): Path {.effectsOf: track.} = 
    add result, tail
    while result[^1] != head:
        add result, track result[^1]
    reverse result

func bfs*(map: Map[Cell], journey: Journey): ResultPack = 
    var
        track: Table[Location, Location]
        queue = initDeque[Location]()
        curr  = journey.a

    track[curr] =   curr
    addFirst queue, curr

    while not empty queue: 
        curr = popFirst queue   
        add result.visits, curr

        if  curr == journey.b:
            result.finalPath = some backtrack(journey.b, journey.a, l => track[l])
            return # early exit
        else:
            for n in curr.neighbors map:
                if  n notin track:
                    addLast queue, n
                    track[n] = curr


func `<`(a, b: Frontier): bool = 
    a.priority < b.priority

func aStar*(map: Map[Cell], journey: Journey): ResultPack = 
    var
        # i     = 0
        track: Table[Location, Frontier] # next -> last
        queue = initHeapQueue[Frontier]()
        curr: Frontier = (journey.a, 0, 0)

    track[journey.a] = curr # self 
    push queue,        curr

    while not empty queue: 
        # inc i
        # debugecho ">> ", i, ' ', queue
        curr = pop queue
        add result.visits, curr.loc

        if  curr.loc == journey.b:
            result.finalPath = some backtrack(journey.b, journey.a, l => track[l].loc)
            return
        else:
            for next in curr.loc.neighbors map:
                let 
                    h = manhattanDistance(next, journey.b)
                    g = curr.cost + 1 # graph.cost(current, next)
                    f = h + g

                if  next notin track or g < track[next].cost:
                    push queue, (next, g, f)
                    track[next] = curr
