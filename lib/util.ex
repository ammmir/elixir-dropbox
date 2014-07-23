defmodule Dropbox.Util do
  def atomize_map(nil, binmap) do
    binmap
  end

  def atomize_map(module, binmap) when is_list(binmap) do
    Enum.map binmap, fn(x) -> atomize_map(module, x) end
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
      if Map.has_key? binmap, Atom.to_string(k) do
        v = binmap[Atom.to_string k]
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

  # TODO: run all dates through this function first
  def parse_date(date) do
    # Fri, 02 May 2014 01:33:30 +0000
    date = Regex.named_captures ~r/^.+, (?<day>\d{2}) (?<month>.{3}) (?<year>\d{4}) (?<hour>\d{2}):(?<minute>\d{2}):(?<second>\d{2}) \+0000$/, date

    {year, _} = Integer.parse date["year"]
    month = case date["month"] do
      "Jan" -> 1
      "Feb" -> 2
      "Mar" -> 3
      "Apr" -> 4
      "May" -> 5
      "Jun" -> 6
      "Jul" -> 7
      "Aug" -> 8
      "Sep" -> 9
      "Oct" -> 10
      "Nov" -> 11
      "Dec" -> 12
    end
    {day, _} = Integer.parse date["day"]
    {hour, _} = Integer.parse date["hour"]
    {minute, _} = Integer.parse date["minute"]
    {second, _} = Integer.parse date["second"]
    {{year, month, day}, {hour, minute, second}}
  end
end
