defmodule Dropbox.Util do
  def atomize_map(nil, binmap) do
    binmap
  end

  def atomize_map(module, binmap) do
    if is_map module do
      map = module
      keys = Map.keys map
    else
      map = struct module, %{}
      [_ | keys] = Map.keys map
    end

    {_, map} = Enum.map_reduce keys, map, fn(k, acc) ->
      if Map.has_key? binmap, atom_to_binary(k) do
        v = binmap[atom_to_binary k]
        if is_map v do
          {k, Map.put(acc, k, atomize_map(Map.get(map, k), v))}
        else
          {k, Map.put(acc, k, v)}
        end
      else
        {k, acc}
      end
    end
    map
  end
end
