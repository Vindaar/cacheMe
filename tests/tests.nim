import std/os
import ../cacheme

type Bar = object
  name: string
  a, b: int

proc foo(a, b: int): Bar {.cacheMe: "test_cache".} =
  let log = open("calls", fmAppend)
  log.writeLine($a & "," & $b)
  log.close()
  result = Bar(name: "computed", a: a, b: b)

doAssert foo(1, 5) == Bar(name: "computed", a: 1, b: 5)
case paramStr(1)
of "populate":
  doAssert foo(1, 5) == Bar(name: "computed", a: 1, b: 5)
  doAssert readFile("calls") == "1,5\n"
of "reuse":
  doAssert readFile("calls") == "1,5\n"
  doAssert foo(5, 3) == Bar(name: "computed", a: 5, b: 3)
  doAssert readFile("calls") == "1,5\n5,3\n"
else:
  quit("expected populate or reuse", 1)
