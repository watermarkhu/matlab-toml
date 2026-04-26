% MAP_SET assign a value in a map object
%
%   MAP_SET(m, key, val) stores val under key in a containers.Map or
%   dictionary, and returns the (possibly updated) map.  For dictionary,
%   values are wrapped in a cell to allow heterogeneous types.

function m = map_set(m, key, val)
  if isa(m, 'dictionary')
    m(string(key)) = {val};
  else
    m(key) = val;
  end
end
