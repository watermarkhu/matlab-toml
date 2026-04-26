% MAKE_MAP create an empty map object
%
%   MAKE_MAP() returns an empty containers.Map.
%   MAKE_MAP(true) returns an empty dictionary (requires MATLAB R2022b+).

function m = make_map(use_dict)
  if nargin < 1
    use_dict = false;
  end
  if use_dict
    m = dict_make();
  else
    m = containers.Map();
  end
end
