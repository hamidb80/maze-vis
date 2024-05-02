import std/[options, sequtils, sets, hashes]

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

    ResultPack = object
        visits*: seq[Location]
        finalPath*: Option[Path]

    PathFindingFnWithStep* = proc(
        map: Map[Cell], 
        start, goal: Location,
    ): ResultPack

# utils ------

func popd(s: var seq) = 
    ## delete the last index
    del s, s.high


func `+`(loc: Location, vec: Vector2): Location = 
    (loc.row + vec.y, loc.col + vec.x)


func initMap*[T](rows, cols: Positive, init: T): Map[T] =
  let row = newSeqWith(cols, init)
  newSeqWith(rows, row)

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
    (-1,  0)]

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
            if  loc      in    map and 
                map[loc] !=    wall and 
                loc      notin seen:
                
                add result.visits, loc
                add path, loc
                dfsImpl map, loc, goal, seen, path, result
                popd path
    
proc bfsImpl(
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
            if  loc in map and 
                map[loc] != wall and 
                loc notin seen:
                
                add result.visits, loc
                add path, loc
                dfsImpl map, loc, goal, seen, path, result
                popd path


proc dfs*(map: Map[Cell], start, goal: Location): ResultPack = 
    var
        seen: HashSet[Location]
        path: Path
    dfsImpl map, start, goal, seen, path, result

proc bfs*(map: Map[Cell], start, goal: Location): ResultPack = 
    var
        seen: HashSet[Location]
        path: Path
    bfsImpl map, start, goal, seen, path, result

proc aStar*(map: Map[Cell], start, goal: Location): ResultPack = 
    # https://github.com/Nycto/AStarNim
    discard


when isMainModule:
    const 
        W = wall
        F = free
    let map = @[
        @[W,W,W,W,W,W,W],
        @[W,F,F,F,F,F,W],
        @[W,F,F,F,F,F,W],
        @[W,W,W,W,W,W,W],
    ]

    let r = dfs(map, (2, 1), (1, 5))
    echo r