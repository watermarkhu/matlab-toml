% MAP_KEYS return the keys of a map as a cell array of char
%
%   MAP_KEYS(m) returns a cell array of char keys from a containers.Map
%   or dictionary object.

function k = map_keys(m)
  if isa(m, 'dictionary')
    k = cellstr(keys(m));
  else
    k = keys(m);
  end
end
