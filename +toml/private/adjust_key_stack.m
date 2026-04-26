% ADJUST_KEY_STACK fix inconsistencies in a pointer into a Map
%
%   ADJUST_KEY_STACK(obj, key_stack) follows the elements of `key_stack`
%   through the structure of `obj`. If an element is missing from the
%   pointer, it is inserted in the appropriate order. The (potentially)
%   corrected pointer is returned.

function key_stack = adjust_key_stack(obj, key_stack, use_dict)
  if nargin < 3
    use_dict = false;
  end

  if ~isempty(key_stack)
    % see if another one is there
    if iscell(obj)
      % insert missing numeric index
      if ischar(key_stack{1})
        key_stack = [{length(obj)}, key_stack];
      end
      nested_obj = obj{key_stack{1}};
    elseif is_map(obj)
      try
        nested_obj = map_get(obj, key_stack{1});
      catch
        if numel(key_stack) > 1
          if ischar(key_stack{2})
            nested_obj = make_map(use_dict);
          else
            nested_obj = {};
          end
        else
          nested_obj = [];
        end
      end
    end

    % go down another level
    key_stack = [key_stack(1), adjust_key_stack(nested_obj, key_stack(2:end), use_dict)];
  end
end
