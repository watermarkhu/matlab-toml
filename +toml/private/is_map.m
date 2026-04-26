% IS_MAP return true if obj is a map type (containers.Map or dictionary)
%
%   IS_MAP(obj) returns true if obj is a containers.Map or a dictionary.

function result = is_map(obj)
  result = isa(obj, 'containers.Map') || isa(obj, 'dictionary');
end
