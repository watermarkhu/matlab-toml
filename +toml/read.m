% READ parse TOML data from a file
%
%   READ('file.toml') loads the contents of `file.toml` and parses
%   that data into a MATLAB Map.
%
%   See also FILEREAD, TOML.DECODE

function toml_data = read(filename)
  if is_octave()
    raw_text = read_utf8(filename);
  else
    fid = fopen(filename, 'r', 'n', 'UTF-8');
    try
      raw_text = fread(fid, [1 inf], '*char');
    finally
      fclose(fid);
    end
  end

  toml_data = toml.decode(raw_text);
end

function raw_text = read_utf8(filename)
  % Properly decodes UTF-8 bytes into Unicode characters
  raw_text = '';
  fid = fopen(filename, 'r');
  
  try
    while ~feof(fid)
      byte1 = fread(fid, 1, 'uint8');
      if isempty(byte1)
        break;
      end
      
      if byte1 < 128
        % Single byte (ASCII): 0xxxxxxx
        raw_text = [raw_text, char(byte1)];
      elseif byte1 < 192
        % Invalid UTF-8 (continuation byte without leading byte)
        error('toml:InvalidUTF8', ...
          ['Bad UTF-8 in file ' filename ': unexpected continuation byte at position ' num2str(ftell(fid))]);
      elseif byte1 < 224
        % 2-byte sequence: 110xxxxx 10xxxxxx
        byte2 = get_continuation_byte(fid, filename);
        % Decode: ((byte1 & 0x1F) << 6) | (byte2 & 0x3F)
        code_point = bitor(bitshift(bitand(byte1, 0x1F), 6), bitand(byte2, 0x3F));
        raw_text = [raw_text, char(uint32(code_point))];
      elseif byte1 < 240
        % 3-byte sequence: 1110xxxx 10xxxxxx 10xxxxxx
        byte2 = get_continuation_byte(fid, filename);
        byte3 = get_continuation_byte(fid, filename);
        % Decode: ((byte1 & 0x0F) << 12) | ((byte2 & 0x3F) << 6) | (byte3 & 0x3F)
        code_point = bitor(bitshift(bitand(byte1, 0x0F), 12), ...
          bitor(bitshift(bitand(byte2, 0x3F), 6), bitand(byte3, 0x3F)));
        raw_text = [raw_text, char(uint32(code_point))];
      elseif byte1 < 248
        % 4-byte sequence: 11110xxx 10xxxxxx 10xxxxxx 10xxxxxx
        byte2 = get_continuation_byte(fid, filename);
        byte3 = get_continuation_byte(fid, filename);
        byte4 = get_continuation_byte(fid, filename);
        % Decode: ((byte1 & 0x07) << 18) | ((byte2 & 0x3F) << 12) | ((byte3 & 0x3F) << 6) | (byte4 & 0x3F)
        code_point = bitor(bitshift(bitand(byte1, 0x07), 18), ...
          bitor(bitshift(bitand(byte2, 0x3F), 12), ...
          bitor(bitshift(bitand(byte3, 0x3F), 6), bitand(byte4, 0x3F))));
        raw_text = [raw_text, char(uint32(code_point))];
      else
        % Invalid leading byte (5-byte sequences and beyond are not valid in UTF-8)
        error('toml:InvalidUTF8', ...
          ['Bad UTF-8 in file ' filename ': invalid leading byte ' sprintf('%d', byte1)]);
      end
    end
  finally
    fclose(fid);
  end
end

function b = get_continuation_byte(fid, filename)
  b = fread(fid, 1, 'uint8');
  
  if isempty(b)
    error('toml:InvalidUTF8', ...
      ['Incomplete UTF-8 sequence in file ' filename]);
  elseif b < 128 || b > 191
    error('toml:InvalidUTF8', ...
      ['Bad UTF-8 in file ' filename ': expected continuation byte, found ' sprintf('%d', b)]);
  end
end