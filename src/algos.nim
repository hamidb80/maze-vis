import std/[options, sequtils, sets, hashes, deques, tables, algorithm]

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

    Path = seq[Location]
    Journey = Slice[Location]

    ResultPack = object
        visits*: seq[Location]
        finalPath*: Option[Path]

    PathFindingFnWithStep* = proc(
        map: Map[Cell], 
        journey: Journey,
    ): ResultPack

# utils ------

func popd(s: var seq) = 
    ## delete the last index
    del s, s.high

func empty[T](s: T): bool = 
    0 == len s

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

func `[]`[T](map: Map[T], loc: Location): T = 
    map[loc.row][loc.col]

# impl ------

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


proc dfsImpl(
    map: Map[Cell], 
    current, goal: Location, 
    seen:   var HashSet[Location],
    path:   var Path,
    result: var ResultPack
) = 
    incl seen, current

    if current == goal:
        result.finalPath = some path 
    else:
        for m in moves:
            let loc = current + m
            if  loc.canGo(map) and 
                loc notin seen:
                add     result.visits, loc
                add     path, loc
                dfsImpl map, loc, goal, seen, path, result
                popd    path
    
proc dfs*(map: Map[Cell], journey: Journey): ResultPack = 
    var
        seen: HashSet[Location]
        path: Path = @[journey.a]
    dfsImpl map, journey.a, journey.b, seen, path, result


proc follow(tail, head: Location, track: Table[Location, Location]): Path = 
    var c   = tail
    add result, c
    while c != head:
        c = track[c]
        add result, c

    reverse result

proc bfs*(map: Map[Cell], journey: Journey): ResultPack = 
    var
        track: Table[Location, Location]
        queue = initDeque[Location]()

    addfirst queue, journey.a
    while not empty queue: 
        let c = popLast queue
        add result.visits, c
        if  c == journey.b:
            result.finalPath = some follow(journey.b, journey.a, track)
            return
        else:
            for m in moves:
                let n = c + m
                if  n.canGo(map) and 
                    n notin track:
                    addlast queue, n
                    track[n] = c


proc aStar*(map: Map[Cell], journey: Journey): ResultPack = 
    # https://github.com/Nycto/AStarNim
    discard


when isMainModule:
    import print

    const 
        W = wall
        F = free
    let map = @[
        @[W,W,W,W,W,W,W],
        @[W,F,F,W,F,F,W],
        @[W,F,F,F,F,F,W],
        @[W,W,W,W,W,W,W],
    ]

    let  
        journey = (2, 1) .. (1, 5)
        d = dfs(  map, journey)
        b = bfs(  map, journey)
        a = aStar(map, journey)

    print journey
    print d
    print b
    print a