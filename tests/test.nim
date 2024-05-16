import std/[random, unittest, options, strformat]
import algos


randomize()


const 
  gobackM = """
    ..##...#.E..
    .....#...##.
    .....#....#.
    .....#....#.
    .....#....#.
    .S...#.####.
    ............
  """
  
  narrowM = """    
    S.
    ..
    ..
    ..
    .#
    .E
  """

  normalM = """
    E...
    ###.
    .#..
    ....
    #.#.
    ..S.
  """


test "example":
  for grid in [gobackM, narrowM, normalM]:
    let 
      t = initTrip grid
      d = dfs(  t.map, t.journey)
      i = iddfs(t.map, t.journey)
      b = bfs(  t.map, t.journey)
      a = aStar(t.map, t.journey)

    echo ""
    echo t.journey
    echo "----------------------------------------"
    echo "\nDFS   \n", t.plot d , unnamed d.visits
    echo "\nIDDFS \n", t.plot i , unnamed i.visits
    echo "\nBFS   \n", t.plot b , unnamed b.visits
    echo "\nA*    \n", t.plot a , unnamed a.visits

test "optimality":
  
  for i in 1..100:
    let 
      n        = rand 100 .. 1000
      treshold = rand 0.0 .. 0.5
      trip     = randomTrip(n, n, treshold)      
      a        = trip ~~> aStar
      b        = trip ~~> bfs
      
      ap       = a.finalPath
      bp       = b.finalPath

      al       = issome ap
      bl       = issome bp
      
      exists   = al or bl

    echo '#', i, ' ', unnamed trip.journey
    check al == bl
    check not exists or ap.get.len == bp.get.len


    # proc show(alg: string, res: ResultPack) =
    #   let  
    #     window  = area res.visits
    #     pin     = window.a
    #     newtrip = Trip(
    #       map:     crop(trip.map, window),
    #       journey: trip.journey - pin)
    #     rpack = ResultPack(
    #       visits: res.visits - pin,
    #       finalPath: some res.finalPath.get - pin)
    #     rows = newtrip.map.rows
    #     cols = newtrip.map.cols

    #   echo fmt"{alg} {n}x{n} ~> {rows}x{cols} :: {res.finalPath.get.len}"
    #   echo newtrip.plot rpack
    #   echo "\n------------------------------------"

    # if exists and ap.get.len != bp.get.len:
    #   show "A* ", a
    #   show "BFS", b
    #   echo "enter to continue ..."
    #   discard readline stdin
  