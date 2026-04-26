% MAP_GET retrieve a value from a map object
%
%   MAP_GET(m, key) retrieves the value stored under key in a
%   containers.Map or dictionary.  For dictionary, the stored value is
%   wrapped in a cell (to allow heterogeneous types), so MAP_GET
%   unwraps it automatically.

function val = map_get(m, key)
  if isa(m, 'dictionary')
    val = dict_get(m, key);
  else
    val = m(key);
  end
end
