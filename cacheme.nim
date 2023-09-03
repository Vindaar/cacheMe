import std/[tables, os, macros]
import nimhdf5
export nimhdf5
export tables

proc inCache*[K; V](args: K, cache: var Table[K, V], path: string): bool =
  if args in cache:
    result = true
  else:
    if fileExists(path):
      let tab = tryDeserializeH5[Table[K, V]](path)
      # merge `tab` and `CacheTab`
      for k, v in tab:
        cache[k] = v # overwrite possible existing keys in table
      # write merged file
      cache.tryToH5(path)
    result = args in cache # still not in: not available

proc getFromCache*[K; V](args: K, cache: Table[K, V]): V =
  result = cache[args]

proc addToCache*[K; V](val: V, args: K, cache: var Table[K, V], path: string) =
  cache[args] = val
  cache.tryToH5(path)

proc initCache*[K; V](path: string): Table[K, V] =
  if fileExists(path):
    result = tryDeserializeH5[Table[K, V]](path)
  else:
    result = initTable[K, V]()

template injectOldBody(args, retTyp, path, body: untyped): untyped {.dirty.} =
  var theCache {.global.} = initCache[typeof args, retTyp](path)
  if args.inCache(theCache, path):
    result = args.getFromCache(theCache)
  else:
    body
    result.addToCache(args, theCache, path)

proc makeTuple(args: NimNode): NimNode =
  result = nnkTupleConstr.newTree()
  for i in 1 ..< args.len: # skip return type
    let arg = args[i]
    case arg.kind
    of nnkIdentDefs:
      for j in 0 ..< arg.len - 2: # skip last child and return type
        result.add arg[j] # get the values, type will be constructed from `typeof`
    else:
      doAssert false, "Unsupported node kind so far: " & $args[i].kind

macro cacheMe*(path: string, fn: untyped): untyped =
  ## WARNING: This may have unintended side effects if your procedure has explicit `return`
  ## statements, as we do not scan the body for those!
  doAssert path.kind == nnkStrLit
  # 1. Construct valid filename
  let h5name = path.strVal & ".h5"
  # 2. Construct a tuple from the proc arguments
  let argsTup = makeTuple(fn[3])
  # 3. Get the return type of the proc
  let retTyp = fn[3][0]
  # 4. Inject the old body into our caching template
  let body = getAst(injectOldBody(argsTup, retTyp, h5name, fn[6]))
  # 5. replace the old body by the new and emit the new procedure
  result = fn
  result[6] = body
  when defined(debug):
    echo result.repr
