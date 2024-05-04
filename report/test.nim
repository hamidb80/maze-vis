import std/[random, sequtils, monotimes, stats, strutils]
import ../src/algos


# random utils ---------------------------------------  

proc randomLocation(rows, cols: int): Location = 
  (rand 0 ..< rows, rand 0 ..< cols)

proc randomCell(row, col: int): Cell = 
  if rand bool: free
  else:         wall

proc transpose(matrix: seq[seq[float]]): seq[seq[float]] =
 let 
  rows = matrix.len
  cols = matrix[0].len

 # Initialize the transposed matrix
 result = newSeqWith(cols, newSeqWith(rows, 0.0))

 # Fill the transposed matrix
 for i in 0 ..< rows:
    for j in 0 ..< cols:
      result[j][i] = matrix[i][j]

# time utils ---------------------------------------  

proc nowMs(): float64 =
  ## Gets current milliseconds.
  getMonoTime().ticks.float64 / 1000000.0

template timeit(body): untyped =
  let t1 = nowMs()
  body
  let t2 = nowMs()
  t2 - t1

# go ---------------------------------------  

proc benchmark(times: Positive, tripGenerator: proc(): Trip): seq[seq[float]] = 
  let fns = [iddfs, dfs, bfs, aStar]

  for n in 1..times:
    let t = tripGenerator()
    add result, fns.mapit timeit (discard it(t.map, t.journey))

when isMainModule:
  echo "matrix size, IDDFS, DFS, BFS, A*"

  for n in 3 .. 200:
    proc tripGen: Trip = 
      let 
        rows  = n
        cols  = n
        start = randomLocation(rows, cols)
        goal  = randomLocation(rows, cols)
      
      result.journey = start .. goal
      result.map     = initMap(rows, cols, randomCell)

    stderr.write n, "\n"
    echo n, ", ", (benchmark(3, tripgen).transpose.mapit mean it).join ", "
