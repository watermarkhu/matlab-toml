% DECODE convert TOML to native MATLAB datatypes
%
%   DECODE(toml_str) returns the MATLAB representation of the
%   TOML-formatted data in `toml_str`. If it is invalid TOML, an
%   appropriate exception will be raised.
%
%   See also TOML.READ

function obj_out = decode(toml_str)
  obj_out = containers.Map();
  location_stack = {};
  array_locations = {};
  table_locations = {};
  implicit_table_locations = {};
  immutable_locations = {};

  while true
    toml_str = consume_comment(toml_str);
    if isempty(toml_str)
      break
    end

    if startsWith(toml_str, '[[') % array
      toml_str = toml_str(3:end);
      [location_stack, toml_str] = consume_key(toml_str, ']]');
      location_stack = adjust_key_stack(obj_out, location_stack);

      % Check conflicts at immutable locations only
      check_stack_for_conflict(immutable_locations, location_stack, 1);
      
      % Allow implicit parent tables for arrays
      % Don't fail if parent doesn't exist - it will be created
      try
        existing_val = get_nested_field(obj_out, location_stack);
        % Parent exists, append to array
        if ~iscell(existing_val)
          error('toml:NameCollision', ...
            ['Cannot redefine table as array: ' strjoin(cellfun(@num2str, location_stack, 'uniformoutput', false), '.')]);
        end
        location_stack{end+1} = length(existing_val) + 1;
        obj_out = set_nested_field(obj_out, location_stack, containers.Map());
      catch e
        % Parent doesn't exist - create it implicitly
        if contains(e.identifier, 'NoSuchIndex')
          % Mark this as an implicit table created by array-of-tables
          implicit_table_locations{end+1} = location_stack;
          array_locations{end+1} = location_stack;
          location_stack{end+1} = 1;
          obj_out = set_nested_field(obj_out, location_stack, containers.Map());
        else
          rethrow(e);
        end
      end

      toml_str = expect_line_break_or_comment_or_eof(toml_str);

    elseif startsWith(toml_str, '[') % table
      toml_str = toml_str(2:end);
      [location_stack, toml_str] = consume_key(toml_str, ']');
      location_stack = adjust_key_stack(obj_out, location_stack);

      % Check for immutable conflicts only
      check_stack_for_conflict(immutable_locations, location_stack, 1);
      
      % Check if this is an explicit redefinition of an explicit table
      check_explicit_table_redefinition(table_locations, location_stack);
      
      % Check if this conflicts with direct array definitions
      % (an array cannot be redefined as a table at its exact location)
      if is_exact_match(array_locations, location_stack)
        error('toml:NameCollision', ...
          ['Cannot redefine array as table: ' strjoin(cellfun(@num2str, location_stack, 'uniformoutput', false), '.')]);
      end
      
      % Mark this as an explicit table definition
      table_locations{end+1} = location_stack;
      
      % If this table already exists implicitly, that's fine - we're just making it explicit
      % set_nested_field handles this correctly
      obj_out = set_nested_field(obj_out, location_stack, containers.Map());
      toml_str = expect_line_break_or_comment_or_eof(toml_str);

    elseif startsWith(toml_str, '"') || startsWith(toml_str, "'") || is_key_char(toml_str(1)) % key / value pair
      [key_seq, toml_str] = consume_key(toml_str, '=');
      [value_fix, toml_str] = consume_value(toml_str);
      this_location = [location_stack key_seq];

      % Check immutable conflicts
      check_stack_for_conflict(immutable_locations, this_location);
      
      % Check if we're trying to redefine an array
      check_stack_for_conflict(array_locations, this_location, numel(location_stack) + 1);
      
      % Mark all intermediate paths as immutable (they're now locked as tables/values)
      for depth = 1:numel(key_seq)
        immutable_locations{end+1} = [location_stack, key_seq(1:depth)];
      end

      obj_out = set_nested_field(obj_out, this_location, value_fix);
      toml_str = expect_line_break_or_comment_or_eof(toml_str);
      
    elseif ~startsWith(toml_str, '#')
      error('toml:UnexpectedStatement', ...
        ['Found unrecognized statement: ' toml_str]);
    end
  end
end

% Check conflicts with immutable locations (values and their dotted key paths)
function check_stack_for_conflict(stacks, current, min_depth)
  if nargin < 3
    min_depth = numel(current);
  end

  for idx = 1:numel(stacks)
    for depth = min_depth:numel(current)
      if isequal(stacks{idx}, current(1:depth))
        error('toml:NameCollision', ...
          ['Assigning to existing location `' strjoin(cellfun(@num2str, current, 'uniformoutput', false), '.') '`']);
      end
    end
  end
end

% Check if explicitly-defined table is being redefined
% This is only an error if trying to redefine at the exact same location
function check_explicit_table_redefinition(explicit_tables, current)
  for idx = 1:numel(explicit_tables)
    if isequal(explicit_tables{idx}, current)
      error('toml:NameCollision', ...
        ['Table `' strjoin(cellfun(@num2str, current, 'uniformoutput', false), '.') '` already defined']);
    end
  end
end

% Check if a location exactly matches any in a list
function result = is_exact_match(locations, target)
  result = false;
  for idx = 1:numel(locations)
    if isequal(locations{idx}, target)
      result = true;
      return;
    end
  end
end
