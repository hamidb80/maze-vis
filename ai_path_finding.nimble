# Package

version       = "0.0.1"
author        = "hamidb80"
description   = "A* BFS DFS path finding visualization"
license       = "MIT"
srcDir        = "src"
bin           = @["ai_path_finding"]


# Dependencies

requires "nim >= 2.0.4"
requires "karax"


task gen, "builds js code":
    exec "nim js -d:release -o:./public/script.js src/webapp.nim"