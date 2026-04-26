% ENCODE serialize MATLAB data as a TOML string
%
%   ENCODE(some_struct) returns the TOML representation of the data in
%   `some_struct`.
%
%   See also TOML.DECODE, TOML.WRITE

function toml_str = encode(m_strct)
  if isstruct(m_strct)
    if isscalar(m_strct)
      % order fields so nothing gets nested wrong
      tmp = struct2cell(m_strct);
      sub_structs = find(cellfun(@isstruct, tmp));
      cell_of_struct = @(cell_in) iscell(cell_in) && all(cellfun(@isstruct, cell_in));
      sub_cellstructs = find(cellfun(cell_of_struct, tmp));
      sub_structs = [sub_structs; sub_cellstructs];
      new_order = [setdiff(1:numel(tmp), sub_structs), sub_structs.'];
      m_strct = orderfields(m_strct, new_order);
      % serialize it recursively
      toml_str = repr(m_strct);
    else
      error('toml:NonScalarStruct', ...
            'TOML base table must be scalar.')
    end
  elseif isa(m_strct, 'containers.Map') || isa(m_strct, 'dictionary')
    use_dict = isa(m_strct, 'dictionary');
    top_level = make_map(use_dict);
    rest = make_map(use_dict);

    % first, deal with all the top-level stuff that's not a table or array of tables
    key_list = map_keys(m_strct);
    for idx = 1:numel(key_list)
      key = key_list{idx};
      val = map_get(m_strct, key);

      if is_map(val) || (iscell(val) && all(cellfun(@is_map, val)))
        rest = map_set(rest, key, val);
      else
        top_level = map_set(top_level, key, val);
      end
    end

    % serialize it recursively
    toml_str = [repr(top_level) newline repr(rest)];
  else
    error('toml:InvalidBaseType', ...
          'TOML base variable must be a struct.')
  end
end