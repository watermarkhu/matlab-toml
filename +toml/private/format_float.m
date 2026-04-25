% FORMAT_FLOAT Format a floating-point number for TOML serialization
%
%   STR = FORMAT_FLOAT(X) returns a string representation of the floating-point
%   number X suitable for TOML encoding. Uses scientific notation for very
%   large or very small numbers, otherwise uses fixed-point notation with
%   unnecessary trailing zeros removed.
%
%   See also TOML.ENCODE, TOML.TESTING.JSONIFY

function str = format_float(x)
  % Handle special cases
  if isnan(x)
    str = 'nan';
  elseif isinf(x)
    if x > 0
      str = 'inf';
    else
      str = '-inf';
    end
  else
    % Use %g format with 15 significant figures
    % %g automatically chooses between fixed and exponential notation,
    % removes trailing zeros, and avoids unnecessary decimal points
    str = sprintf('%.15g', x);
    
    % Ensure lowercase 'e' for scientific notation (TOML convention)
    str = lower(str);
  end
end
