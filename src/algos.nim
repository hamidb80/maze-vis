import std/options

type
    Cell* = enum
        free
        wall

    Map*[T] = seq[seq[T]]

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


# https://github.com/Nycto/AStarNim

proc dfs*(map: Map[Cell], start, goal: Location): ResultPack = 
    discard

proc bfs*(map: Map[Cell], start, goal: Location): ResultPack = 
    discard

proc aStar*(map: Map[Cell], start, goal: Location): ResultPack = 
    discard
