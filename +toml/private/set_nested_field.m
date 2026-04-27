% SET_NESTED_FIELD set a value somewhere in a Map
%
%   SET_NESTED_FIELD(obj, indx, val) sets the location denoted by `indx`
%   (a pointer sequence into `obj`) in `obj` equal to `val`, and returns
%   a modified copy of `obj`.
%
%   SET_NESTED_FIELD(obj, indx, val, use_dict) uses dictionary instead of
%   containers.Map when use_dict is true and intermediate maps need to be
%   created.
%
%   See also GET_NESTED_FIELD

function obj = set_nested_field(obj, indx, val, use_dict)
  if nargin < 4
    use_dict = false;
  end

  if length(indx) == 1
    if is_map(obj)
      if map_iskey(obj, indx{1})
        existing = map_get(obj, indx{1});
        switch class(existing)
          case {'containers.Map', 'dictionary'}
            if ~is_map(val)
              error('toml:RedefinedTable', ...
                    'Tables cannot be redefined.')
            elseif isempty(map_keys(val))
              % val is an empty placeholder (e.g. explicit [super-table] header
              % written after a sub-table already created the implicit map).
              % Keep the existing map intact; nothing to merge.
              return
            end
          case 'cell'
            existing_is_aot = ~isempty(existing) && is_map(existing{1});
            if iscell(val) && ~existing_is_aot && ...
              ( ...
                isempty(val) || ...
                ( ...
                  isempty(val{1}) || ( ...
                    is_map(val{1}) && isempty(map_keys(val{1})) ...
                  ) || ( ...
                    iscell(val{1}) && (isempty(val{1}{1}) || ( ...
                      is_map(val{1}{1}) && isempty(map_keys(val{1}{1})) ...
                    )) ...
                  ) ...
                ) ...
              )
              error('toml:RedefinedArray', ...
                    'Arrays cannot be redefined.')
            elseif is_map(val)
              error('toml:NameCollision', ...
                    'Table definitions cannot override existing arrays.')
            end
          otherwise
            if is_map(val)
              error('toml:RedefinedTable', ...
                    'Tables cannot be redefined.')
            end
            error('toml:RedefinedKey', ...
                  'Keys cannot be redefined.')
        end
      end

      % annoying bug in octave requires assigning empty key twice
      if isempty(indx{1}) && is_octave()
        try
          obj = map_set(obj, indx{1}, val);
        catch
        end
      end

      obj = map_set(obj, indx{1}, val);
    elseif iscell(obj)
      if ischar(indx{1})
        obj{end} = map_set(obj{end}, indx{1}, val);
      else
        obj{indx{1}} = val;
      end
    end
  else
    try
      orig = get_nested_field(obj, indx(1));
    catch
      if ischar(indx{2})
        orig = make_map(use_dict);
      else
        orig = {};
      end
    end
    new = set_nested_field(orig, indx(2:end), val, use_dict);
    obj = set_nested_field(obj, indx(1), new, use_dict);
  end
end
