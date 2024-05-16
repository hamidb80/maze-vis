import std/[random, sequtils, monotimes, stats, strutils]
import ../src/algos


# random utils ---------------------------------------  

proc transpose[T](matrix: seq[seq[T]]): seq[seq[T]] =
 # Initialize the transposed matrix
 result = newSeqWith(matrix.cols, 
                    newSeqWith(matrix.rows, 
                              0.0))

 # Fill the transposed matrix
 for i in 0 ..< matrix.rows:
    for j in 0 ..< matrix.cols:
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

  for n in 1 .. 200:
    proc tripGen: Trip = 
      randomTrip n, n, rand 0.0 .. 0.3, 0
    
    stderr.write n, "\n"
    echo n, ", ", (benchmark(30, tripgen).transpose.mapit mean it).join ", "
