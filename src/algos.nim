import std/[options, sets, hashes, deques, tables, algorithm, math, sugar, strutils, heapqueue]

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
        loc: Location
        cost, priority: float

# utils ------------------------------------------

func popd(s: var seq) = 
    ## delete the last index
    del s, s.high

func empty*[T](s: T): bool = 
    let z = 
        when compiles(len s): len  s
        else:                 size s
    0 == z

func `+`(loc: Location, vec: Vector2): Location = 
    (loc.row + vec.y, loc.col + vec.x)


func resize*(m: var Map, rows, cols: Positive) = 
    setlen m, rows
    for r in mitems m:
        setlen r, cols

func initMap*[T](rows, cols: Positive, init: proc(row, col: int): T): Map[T] {.effectsOf: init.} =
    resize result, rows, cols

    for y in 0 ..< rows:
        for x in 0 ..< cols:
            result[y][x] = init(y, x)

func initMap*[T: not proc](rows, cols: Positive, init: T): Map[T] {.effectsOf: init.} =
    initMap rows, cols, (row, col) => init 


func width*(map: Map): Natural = 
    len map[0]

func height*(map: Map): Natural = 
    len map

func contains*(map: Map, loc: Location): bool = 
    loc.row in 0 ..< map.height and
    loc.col in 0 ..< map.width 

func `[]`*[T](map: Map[T], loc: Location): T = 
    map[loc.row][loc.col]

func `[]=`*[T](map: var Map[T], loc: Location, val: T) = 
    map[loc.row][loc.col] = val

# helpers ------------------------------------------

const moves = [
    ( 0, -1).Vector2,
    (+1,  0),
    ( 0, +1),
    (-1,  0),
]

func canGo(loc:  Location, map:  Map[Cell]): bool =
    loc      in map  and
    map[loc] != wall

iterator neighbors(loc: Location, map: Map[Cell]): Location = 
    for m in moves:
        let n = loc + m
        if n.canGo map:
            yield n


func euclideanDistance*(node, goal: Location): float =
    sqrt(
        pow(float(node.col) - float(goal.col), 2) +
        pow(float(node.row) - float(goal.row), 2) )

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

proc plot*(trip: Trip, rp: ResultPack): string = 
    result = newStringOfCap trip.map.height * (trip.map.width + 1)
    
    for y, row in trip.map:
        for x, cell in row:
            let p = (y, x)
            add result:
                if   p == trip.journey.a:     'S'
                elif p == trip.journey.b:     'E'
                elif p in rp.visits: 
                    if p in rp.finalPath.get: '*'
                    else:                     'v'
                elif cell == wall:            '#'
                else:                         '.'
        add result, '\n'

proc plot*(trip: Trip): string = 
    plot trip, ResultPack()

template unnamed(locs): untyped =
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
                add     path, loc
                dfsImpl map, remainingSteps - 1, loc, goal, seen, path, result
                if issome result.finalPath: return
                popd    path

func dfsImpl(map: Map[Cell], maxDepth: int, journey: Journey): ResultPack = 
    var
        seen: HashSet[Location]
        path: Path = @[journey.a]
    dfsImpl map, maxDepth, journey.a, journey.b, seen, path, result

func dfs*(map: Map[Cell], journey: Journey): ResultPack = 
    dfsImpl map, map.width * map.height, journey

func iddfs*(map: Map[Cell], journey: Journey): ResultPack =
    for d in 1 .. map.width * map.height:
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
        track: Table[Location, Frontier]
        queue = initHeapQueue[Frontier]()
        curr: Frontier = (journey.a, 0, 0)

    track[journey.a] = curr 
    push queue,        curr

    while not empty queue: 
        curr = pop queue
        add result.visits, curr.loc

        if  curr.loc == journey.b:
            result.finalPath = some backtrack(journey.b, journey.a, l => track[l].loc)
            return
        else:
            for next in curr.loc.neighbors map:
                let newCost = track[curr.loc].cost + 1 # graph.cost(current, next)
                if  next notin track or newCost < track[next].cost:
                    push queue, (next, newCost, newCost + euclideanDistance(next, journey.b))
                    track[next] = curr

# test -------------------------------------------- 

when isMainModule:
    let trip = initTrip """
        ..#......E..
        .....#...##.
        ..........#.
        ..........#.
        ..........#.
        .S...######.
        ............
    """
    echo trip.journey

    let  
        d = dfs(  trip.map, trip.journey)
        b = bfs(  trip.map, trip.journey)
        a = aStar(trip.map, trip.journey)
        i = iddfs(trip.map, trip.journey)

    echo "DFS   \n", trip.plot d, unnamed d.visits
    echo "BFS   \n", trip.plot b, unnamed b.visits
    echo "A*    \n", trip.plot a, unnamed a.visits
    echo "IDDFS \n", trip.plot i, unnamed i.visits
