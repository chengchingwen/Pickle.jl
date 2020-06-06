function default_methods!(mt)
  mt["builtins.set"] = Set
  mt["__julia__.Set"] = "builtins.set"
  mt["__julia__.Base.CodeUnits"] = "codecs.encode"
  mt["__julia__.__py__.bytes"] = "builtins.bytes"
  mt
end
