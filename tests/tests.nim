import ../cacheme

type
  Bar = object
    name: string
    a, b: int

proc foo(a, b: int): Bar {.cacheMe: "/tmp/test_cache".} =
  result = Bar(a: a, b: b, name: "Hehe")

echo foo(1, 5)
echo foo(5, 3)
echo foo(1, 5)
echo foo(8, 12)
