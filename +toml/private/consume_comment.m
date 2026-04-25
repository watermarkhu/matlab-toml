function out = consume_comment(in)
  out = trimstart(in, true);

  if startsWith(out, '#')
    out = out(2:end);

    if ~isempty(out)
      for idx = 1:numel(out)
        c = out(idx);
        if c == newline || (c == char(0xD) && idx < numel(out) && out(idx+1) == newline)
          out = trimstart(out(idx:end), true);
          return
        elseif c == 9
          % tabs are okay
        else
          % Check for control characters by explicit codepoint value
          % This handles multibyte UTF-8 characters correctly
          char_code = double(c);
          if (char_code >= 0 && char_code <= 8) || ...
             (char_code >= 10 && char_code <= 31) || ...
             char_code == 127
            error('toml:ControlCharInComment', ...
              sprintf('Encountered control character %d in comment.', char_code));
          end
        end
      end

      out = '';
    end
  end
end