% MAP_ISKEY return true if key exists in a map object
%
%   MAP_ISKEY(m, key) returns true if key exists in the containers.Map
%   or dictionary m.

function result = map_iskey(m, key)
  if isa(m, 'dictionary')
    result = dict_iskey(m, key);
  else
    result = isKey(m, key);
  end
end
