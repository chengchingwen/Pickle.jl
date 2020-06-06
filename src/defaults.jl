function default_methods!(mt)
  mt["builtins.set"] = Set
  mt["builtins.bytes"] = () -> b""
  mt["codecs.encode"] = (s, c) -> codeunits(s)
  _setentry!(mt.head, mt["builtins"], "__builtin__")
  _setentry!(mt.head, mt["codecs"], "_codecs")
  mt["__julia__.Set"] = "builtins.set"
  mt["__julia__.Base.CodeUnits"] = "codecs.encode"
  mt["__julia__.__py__.bytes"] = "builtins.bytes"
  mt
end
