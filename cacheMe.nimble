# Package

version       = "0.0.1"
author        = "Vindaar"
description   = "A basic procedure caching serialization macro helper"
license       = "MIT"


# Dependencies

requires "nim >= 1.6.0"
requires "nimhdf5"

task test, "Check persistent caching across processes":
  exec "sh tests/persistence.sh"
