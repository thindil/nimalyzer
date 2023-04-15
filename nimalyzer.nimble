import std/os

# Package

version = "0.3.0"
author = "Bartek thindil Jasicki"
description = "A static code analyzer for Nim"
license = "BSD-3-Clause"
srcDir = "src"
bin = @["nimalyzer"]
binDir = "bin"


# Dependencies

requires "nim >= 1.6.10"
requires "contracts >= 0.2.2"
requires "compiler == " & $NimMajor & "." & $NimMinor & "." & $NimPatch

# Tasks

# Disable checking BareExcept warning for Nim 1.6.12
const warningFlags = (when (NimMajor, NimMinor, NimPatch) == (1, 6,
    12): "--warning:BareExcept:off " else: "")

task debug, "builds the project in debug mode":
  exec "nim c -d:debug --styleCheck:hint --spellSuggest:auto --errorMax:0 " &
      warningFlags & "--outdir:" & binDir & " " & srcDir & DirSep & "nimalyzer.nim"

task release, "builds the project in release mode":
  exec "nimble install -d -y"
  exec "nim c -d:release --passc:-flto --passl:-s " & warningFlags &
      "--outdir:" & binDir & " " & srcDir & DirSep & "nimalyzer.nim"

task test, "run the project unit tests":
  exec "testament all"

task releasewindows, "builds the project in release mode for Windows 64-bit":
  exec "nimble install -d -y"
  exec "nim c -d:mingw --os:windows --cpu:amd64 --amd64.windows.gcc.exe:x86_64-w64-mingw32-gcc --amd64.windows.gcc.linkerexe=x86_64-w64-mingw32-gcc  -d:release --passc:-flto --passl:-s " &
      warningFlags & "--outdir:" & binDir & " " & srcDir & DirSep & "nimalyzer.nim"

task tools, "builds the project's tools":
  exec "nim c -d:release --passc:-flto --passl:-s --styleCheck:hint --spellSuggest:auto --errorMax:0 " &
      warningFlags & "--outdir:" & binDir & " tools" & DirSep & "gendoc.nim"

task docs, "builds the project's documentation":
  for file in ["configuration", "index", "available_rules"]:
    exec "nim rst2html --index:on --outdir:htmldocs doc" & DirSep & file & ".rst"
  exec "nim doc --project --outdir:htmldocs src/nimalyzer.nim"
