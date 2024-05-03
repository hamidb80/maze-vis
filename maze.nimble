# Package

version       = "0.1.0"
author        = "hamidb80"
description   = "A* BFS DFS path finding visualization"
license       = "MIT"
srcDir        = "src"
bin           = @[]


# Dependencies

requires "nim >= 2.0.0"
requires "karax <= 1.3.3"


task gen, "builds js code":
    exec "nim js -d:release -o:./public/script.js src/webapp.nim"