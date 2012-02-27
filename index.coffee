path=require 'path'; fs=require 'fs'
dep_registry={}
exports.dependency=(target,dependencies,build,auto)-> new Dependency target,dependencies,build,auto
exports.flush= -> dep_registry={}
unknown=0
#target is a string, dependencies is an array of strings, which may match keys in dep_registry, and build is a function with no arguments returning a string if @auto is set or doing the file io it's self otherwise, or not doing file io at all
#call process() on the top level target
#call process({force:true}) to build regardless of modification times
class Dependency
  constructor:(@target,@dependencies=[],@build,@auto)->
    @processed=no
    dep_registry[@target]=@
  mod_time:->
    if path.existsSync @target
      Number fs.statSync(@target).mtime
    else
      (@_mod_time or unknown)
  process:(p={})->#write if neccesary
    @processed=yes
    if @build_deps_and_check_for_newer() or p.force
      if @build#otherwise this dependency is only a placeholder
        if @auto
          fs.writeFileSync @target,@build()
        else
          @build()
      console.log if @build then @build.toString() else @target
  build_deps_and_check_for_newer:->#invoke process on dependencies, return yes if any are newer
    mod_time=@mod_time()
    largest_dep_mod_time=0
    build=if mod_time is 0 then yes else no
    for d in @dependencies
      d=(dep_registry[d] or new Dependency d)#wrap implicitly declared dependencies(source files)
      d.process() if not d.processed#dont process the same dependency more then once
      d_mod_time=d.mod_time()
      if d_mod_time>largest_dep_mod_time
        largest_dep_mod_time=d_mod_time
    if @build
      largest_dep_mod_time>mod_time or mod_time is unknown
    else
      @_mod_time=largest_dep_mod_time or Number Date.now()
      no
