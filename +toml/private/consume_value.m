function [val, str] = consume_value(str)
  str = trimstart(str);
  
  if isempty(str)
    error('toml:MissingValue', ...
      'Expected a value, found end of input.');

  elseif startsWith(str, '[')
    str = str(2:end);
    val = {};
    expecting_comma = false;
    while ~isempty(str)
      str = consume_comment(str);

      if startsWith(str, ']')
        break
      elseif expecting_comma
        str = expect(str, ',');
        expecting_comma = false;
      elseif startsWith(str, ',')
        error('toml:LeadingComma', ...
          'Comma found before in array without an element before it.');
      elseif ~startsWith(str, '#')
        [item, str] = consume_value(str);
        val{end+1} = item;
        expecting_comma = true;
      end
    end

    str = expect(str, ']');
    
    if numel(val) > 1 && ...
      (all(cellfun(@(e) isa(e, 'int64'), val)) || ...
        all(cellfun(@(e) isa(e, 'uint64'), val)) || ...
        all(cellfun(@(e) isa(e, 'double'), val))) && ...
        all(cellfun(@isscalar, val))
      val = cell2mat(val);
    end
    
  elseif startsWith(str, '{')
    str = str(2:end);
    val = containers.Map();
    inline_immutable = {};
    while true
      str = trimstart(str, true);
      str = consume_comment(str);
      % consume_comment may leave us at another # or whitespace (consecutive comments)
      if ~isempty(str) && (str(1) == '#' || isspace(str(1)))
        continue
      end
      if isempty(str)
        error('toml:EndOfInput', 'Did not expect input to end inside inline table.');
      end
      if startsWith(str, '}')
        break
      end
      [key_seq, str] = consume_key(str, '=');
      [item, str] = consume_value(str);
      % Check: reject if new key_seq exactly matches or is an extension of an existing key,
      % or if an existing key is an extension of the new key_seq.
      for ii = 1:numel(inline_immutable)
        existing = inline_immutable{ii};
        n = min(numel(existing), numel(key_seq));
        if isequal(existing(1:n), key_seq(1:n))
          error('toml:InlineTableImmutable', ...
            'Inline tables are immutable; key already defined.');
        end
      end
      % Mark this full key path as immutable (leaf only)
      inline_immutable{end+1} = key_seq;
      val = set_nested_field(val, key_seq, item);
      while true
        str = trimstart(str, true);
        str = consume_comment(str);
        if startsWith(str, ',')
          str = str(2:end);  % consume optional comma (trailing comma allowed in TOML 1.1)
          break
        elseif startsWith(str, '}')
          break
        elseif ~isempty(str) && (str(1) == '#' || isspace(str(1)))
          continue  % consecutive comments/whitespace
        elseif isempty(str)
          error('toml:EndOfInput', 'Did not expect input to end inside inline table.');
        else
          error('toml:MissingComma', ...
            'Expected comma or closing brace in inline table.');
        end
      end
    end
    str = expect(str, '}');

  elseif startsWith(str, 'true')
    val = true;
    str = str(5:end);
  elseif startsWith(str, 'false')
    val = false;
    str = str(6:end);
    
  elseif startsWith(str, "'")
    [val, str] = consume_literal_string(str, true);
  elseif startsWith(str, '"')
    [val, str] = consume_basic_string(str, true);

  elseif startsWith(str, '+')
    [val, str] = consume_signed_value(str(2:end), 1);
  elseif startsWith(str, '-')
    [val, str] = consume_signed_value(str(2:end), -1);
    
  elseif startsWith(str, "inf")
    val = Inf;
    str = str(4:end);
  elseif startsWith(str, "nan")
    val = NaN;
    str = str(4:end);
    
  elseif startsWith(str, "0b")
    [digits, str] = consume_integer(str(3:end), 2);
    val = uint64(bin2dec(strrep(digits, '_', '')));
  elseif startsWith(str, "0o")
    [digits, str] = consume_integer(str(3:end), 8);
    val = uint64(base2dec(strrep(digits, '_', ''), 8));
  elseif startsWith(str, "0x")
    [digits, str] = consume_integer(str(3:end), 16);
    val = uint64(hex2dec(strrep(digits, '_', '')));
    
  elseif isstrprop(str(1), 'digit')
    [digits, str] = consume_integer(str, 10);
    
    % date
    if numel(digits) == 4 && startsWith(str, '-')
      [month, str] = consume_integer(str(2:end), 10);
  
      if numel(month) ~= 2 || month(1) > '1' || (month(1) == '1' && month(2) > '2') || all(month == '00')
        error('toml:InvalidMonth', 'Invalid month in date object.');
      end

      str = expect(str, '-');
      [day, str] = consume_integer(str, 10);
  
      if numel(day) ~= 2 || day(1) > '3' || (day(1) == '3' && day(2) > '1') || all(day == '00')
        error('toml:InvalidDay', 'Invalid day in date object.');
      end

      val = [digits '-' month '-' day];
      
      % Validate day against month (including leap year for February)
      year_n  = str2double(digits);
      month_n = str2double(month);
      day_n   = str2double(day);
      days_in_month = [31 28 31 30 31 30 31 31 30 31 30 31];
      if mod(year_n, 400) == 0 || (mod(year_n, 4) == 0 && mod(year_n, 100) ~= 0)
        days_in_month(2) = 29;
      end
      if day_n > days_in_month(month_n)
        error('toml:InvalidDay', 'Day out of range for the given month.');
      end
      
      if startsWith(str, 'T') || startsWith(str, 't') || ...
         (strncmp(str, ' ', 1) && numel(str) > 1 && isstrprop(str(2), 'digit'))
        [time_str, str] = consume_time(str(2:end));
        val = [val 'T' time_str];
        
        if startsWith(str, 'Z') || startsWith(str, 'z')
          val = [val 'Z'];
          str = str(2:end);
        elseif startsWith(str, '+') || startsWith(str, '-')
          sign = str(1);
          [hour, str] = consume_integer(str(2:end), 10);
          if numel(hour) ~= 2 || hour(1) > '2' || (hour(1) == '2' && hour(2) > '3')
            error('toml:InvalidOffsetHour', 'Invalid hour in timezone offset.');
          end
          str = expect(str, ':');
          [minute, str] = consume_integer(str, 10);
          if numel(minute) ~= 2 || minute(1) > '5'
            error('toml:InvalidOffsetMinute', 'Invalid minute in timezone offset.');
          end
          val = [val sign hour ':' minute];
        end
      end

    % time
    elseif numel(digits) == 2 && startsWith(str, ':')
      [val, str] = consume_time(str, digits);

    % number
    else
      [val, str] = terminate_number(digits, str, 1);
    end

  else
    error('toml:UnexpectedValue', ...
      ['Encountered an unknown value: ', str]);
  end
end

function [num, str] = consume_signed_value(str, signum)
  if isempty(str)
    error('toml:SignWithNoValue', ...
      'Sign operator was found without a value.');
  elseif startsWith(str, '0b') || startsWith(str, '0o') || startsWith(str, '0x')
    error('toml:SignOnNonBase10', ...
      'Encountered a plus/minus sign on an unsigned int value.');
  elseif startsWith(str, '+') || startsWith(str, '-')
    error('toml:MultipleSigns', ...
      'Encountered multiple plus/minus signs in a row.');

  elseif startsWith(str, 'inf')
    num = Inf * signum;
    str = str(4:end);
  elseif startsWith(str, 'nan')
    num = NaN * signum;
    str = str(4:end);
  elseif isstrprop(str(1), 'digit')
    [digits, str] = consume_integer(str, 10);
    [num, str] = terminate_number(digits, str, signum);

  else
    error('toml:InvalidSign', ...
      'Encountered a plus/minus sign on a non-numeric value.');
  end
end

function [digits, str] = consume_integer(str, base)
  switch base
    case 2
      c_valid = @(c) c == '0' || c == '1';
    case 8
      c_valid = @(c) c >= '0' && c <= '7';
    case 10
      c_valid = @(c) c >= '0' && c <= '9';
    case 16
      c_valid = @(c) (c >= '0' && c <= '9') || (c >= 'a' && c <= 'f') || (c >= 'A' && c <= 'F');
  end

  digits = str;
  for idx = 1:numel(str)
    if startsWith(str(idx:end), '__')
      error('toml:DoubleUnderscore', ...
        'Double underscore encountered in numeric literal.');
    end

    if ~c_valid(str(idx)) && str(idx) ~= '_'
      digits = str(1:idx-1);
      break
    end
  end
  
  if startsWith(digits, '_')
    error('toml:LeadingUnderscore', ...
      'Numbers cannot have a leading underscore.');
  elseif endsWith(digits, '_')
    error('toml:TrailingUnderscore', ...
      'Numbers cannot have a trailing underscore.');
  elseif isempty(digits)
    error('toml:NoDigits', ...
      'Expected at least one digit.');
  end
  
  str = str(numel(digits)+1:end);
end

function [val, str] = consume_time(str, hour)
  if nargin < 2
    [hour, str] = consume_integer(str, 10);
  end
  
  if numel(hour) ~= 2 || hour(1) > '2' || (hour(1) == '2' && hour(2) > '3')
    error('toml:InvalidHour', 'Invalid hour in time object.');
  end

  str = expect(str, ':');
  [minute, str] = consume_integer(str, 10);

  if numel(minute) ~= 2 || minute(1) > '5'
    error('toml:InvalidMinute', 'Invalid minute in time object.');
  end

  if startsWith(str, ':') && numel(str) > 1 && isstrprop(str(2), 'digit')
    str = str(2:end);
    [second, str] = consume_integer(str, 10);

    if numel(second) ~= 2 || second(1) > '6' || (second(1) == '6' && second(2) > '0')
      error('toml:InvalidSecond', 'Invalid second in time object.');
    end

    val = [hour ':' minute ':' second];

    if startsWith(str, '.')
      [sub_second, str] = consume_integer(str(2:end), 10);
      val = [val '.' sub_second(1:min(6, numel(sub_second)))];
    end
  else
    val = [hour ':' minute ':00'];
  end
end

function [val, str] = terminate_number(digits, str, signum)
  if startsWith(digits, '0') && numel(digits) > 1
    error('toml:LeadingZero', ...
      'Encountered a numeric literal with a leading zero.');
  end

  has_fractional = false;
  has_exponent = false;

  % float with fractional
  if startsWith(str, '.')
    has_fractional = true;
    [frac_part, str] = consume_integer(str(2:end), 10);
    digits = [digits '.' frac_part];
  end

  % float with exponential
  if startsWith(str, 'e') || startsWith(str, 'E')
    has_exponent = true;
    str = str(2:end);
    digits = [digits 'e'];

    if startsWith(str, '+')
      str = str(2:end);
    elseif startsWith(str, '-')
      digits = [digits '-'];
      str = str(2:end);
    end

    [exp_part, str] = consume_integer(str, 10);
    digits = [digits exp_part];
  end

  val = str2num(strrep(digits, '_', '')) * signum;

  if ~has_fractional && ~has_exponent
    if numel(digits) > 1 && digits(1) == '0'
      error('toml:LeadingZero', ...
        'Encountered integer value with a leading zero.');
    end
    val = int64(val);
  end
end
