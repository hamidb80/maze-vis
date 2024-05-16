import std/[random, unittest, options, strformat]
import algos

randomize()

test "optimality":
  
  for i in 1..100:
    echo '#', i

    let 
      n        = rand 70  .. 120
      treshold = rand 0.0 .. 0.3
      trip     = randomTrip(n, n, treshold)
      
      a        = trip ~~> aStar
      b        = trip ~~> bfs
      
      ap       = a.finalPath
      bp       = b.finalPath

      al       = issome ap
      bl       = issome bp
      
      exists   = al or bl

    proc show(alg: string, res: ResultPack) =
      echo fmt"{alg} {n}x{n} :: {res.finalPath.get.len}"
      echo trip.plot res
      echo "\n------------------------------------"

    check al == bl
    
    if exists and ap.get.len != bp.get.len:
      show "A* ", a
      show "BFS", b
      echo "enter to continue ..."
      discard readline stdin