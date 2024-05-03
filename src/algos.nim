import std/[options, sequtils, sets, hashes, deques, tables, algorithm, math, sugar, strutils, heapqueue]

# structures ------

type
    Cell* = enum
        free
        wall

    Map*[T] = seq[seq[T]]

    Vector2 = tuple
        x, y: int

    Location* = tuple
        row, col: int

    Trip = object 
        map: Map[Cell]
        journey: Journey

    Path* = seq[Location]
    Journey* = Slice[Location]

    ResultPack = object
        visits*: seq[Location]
        finalPath*: Option[Path]

    PathFindingFnWithStep* = proc(
        map: Map[Cell], 
        journey: Journey,
    ): ResultPack

    Frontier = tuple
        loc: Location
        cost, priority: float

# utils ------

func popd(s: var seq) = 
    ## delete the last index
    del s, s.high

func empty[T](s: T): bool = 
    let z = 
        when compiles(len s): len  s
        else:                 size s
    0 == z

func `+`(loc: Location, vec: Vector2): Location = 
    (loc.row + vec.y, loc.col + vec.x)


func initMap*[T](rows, cols: Positive, init: T): Map[T] =
  newSeqWith rows:
    newSeqWith cols, init

func width(map: Map): Natural = 
    len map[0]

func height(map: Map): Natural = 
    len map

func contains(map: Map, loc: Location): bool = 
    loc.row in 0 ..< map.height and
    loc.col in 0 ..< map.width 

func `[]`*[T](map: Map[T], loc: Location): T = 
    map[loc.row][loc.col]


template unnamed(path): untyped =
    cast[seq[(int, int)]](path)

# helpers ------

const moves = [
    ( 0, -1).Vector2,
    (+1,  0),
    ( 0, +1),
    (-1,  0),
]

func canGo(
    loc:  Location, 
    map:  Map[Cell], 
): bool =
    loc      in    map  and 
    map[loc] !=    wall    

iterator neighbors(loc: Location, map: Map[Cell]): Location = 
    for m in moves:
        let n = loc + m
        if n.canGo map:
            yield n


func manhattan*(node, goal: Location): int =
    abs(node.col - goal.col) + abs(node.row - goal.row)

func asTheCrowFlies*(node, goal: Location): float =
    sqrt(
        pow(float(node.col) - float(goal.col), 2) +
        pow(float(node.row) - float(goal.row), 2) )

func chebyshev*(node, goal: Location): int =
    max(
        abs(node.col - goal.col), 
        abs(node.row - goal.row))

# debug -----

func initTrip(grid: string): Trip = 
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

proc plot(trip: Trip, rp: ResultPack): string = 
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

# impl ------

func dfsImpl(
    map: Map[Cell], 
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
    else:
        for loc in current.neighbors map:
            if  loc notin seen:
                add     path, loc
                dfsImpl map, loc, goal, seen, path, result
                if issome result.finalPath: return
                popd    path
    
func dfs*(map: Map[Cell], journey: Journey): ResultPack = 
    var
        seen: HashSet[Location]
        path: Path = @[journey.a]
    dfsImpl map, journey.a, journey.b, seen, path, result


func follow(tail, head: Location, 
            track: proc(loc: Location): Location): Path {.effectsOf: track.} = 
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
            result.finalPath = some follow(journey.b, journey.a, l => track[l])
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
            result.finalPath = some follow(journey.b, journey.a, l => track[l].loc)
            return
        else:
            for next in curr.loc.neighbors map:
                let newCost = track[curr.loc].cost + 1 # graph.cost(current, next)
                if  next notin track or newCost < track[next].cost:
                    push queue, (next, newCost, newCost + asTheCrowFlies(next, journey.b))
                    track[next] = curr


when isMainModule:
    let trip = initTrip """
        ..#......E..
        .....#...##.
        ..........#.
        ..........#.
        ..........#.
        .S..E######.
        ............
    """
    echo trip.journey

    let  
        d = dfs(  trip.map, trip.journey)
        b = bfs(  trip.map, trip.journey)
        a = aStar(trip.map, trip.journey)

    echo "DFS\n", trip.plot d, unnamed d.visits
    echo "BFS\n", trip.plot b, unnamed b.visits
    echo "A* \n", trip.plot a, unnamed a.visits
