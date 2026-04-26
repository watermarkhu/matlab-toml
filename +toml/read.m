% READ parse TOML data from a file
%
%   READ('file.toml') loads the contents of `file.toml` and parses
%   that data into a MATLAB Map.
%
%   READ('file.toml', 'UseDictionary', true) uses the dictionary type
%   (requires MATLAB R2022b+) instead of containers.Map.
%
%   See also FILEREAD, TOML.DECODE

function toml_data = read(filename, varargin)
  if is_octave()
    raw_text = read_utf8_octave(filename);
  else
    raw_text = read_utf8_matlab(filename);
  end

  toml_data = toml.decode(raw_text, varargin{:});
end

function raw_text = read_utf8_matlab(filename)
  % Read raw bytes and decode UTF-8 manually to a MATLAB char array.
  % Supplementary-plane chars (U+10000+) become UTF-16 surrogate pairs.
  % Invalid UTF-8 (including CESU-8 surrogates) raises toml:InvalidUTF8.
  fid = fopen(filename, 'rb');
  if fid == -1
    error('toml:FileNotFound', 'Cannot open file: %s', filename);
  end
  bytes = fread(fid, [1 inf], '*uint8');
  fclose(fid);

  n = numel(bytes);
  buf = zeros(1, n * 2, 'uint32');
  out_pos = 0;
  i = 1;

  while i <= n
    b = uint32(bytes(i));

    if b < 0x80
      out_pos = out_pos + 1;
      buf(out_pos) = b;
      i = i + 1;

    elseif b < 0xC0
      error('toml:InvalidUTF8', 'Invalid UTF-8 in file %s at byte %d', filename, i);

    elseif b < 0xE0
      if i + 1 > n, error('toml:InvalidUTF8', 'Truncated UTF-8 in file %s', filename); end
      b2 = uint32(bytes(i+1));
      if b2 < 0x80 || b2 > 0xBF
        error('toml:InvalidUTF8', 'Invalid UTF-8 continuation in file %s at byte %d', filename, i+1);
      end
      cp = bitand(b, uint32(0x1F)) * 64 + bitand(b2, uint32(0x3F));
      if cp < 0x80
        error('toml:InvalidUTF8', 'Overlong UTF-8 encoding in file %s at byte %d', filename, i);
      end
      out_pos = out_pos + 1;
      buf(out_pos) = cp;
      i = i + 2;

    elseif b < 0xF0
      if i + 2 > n, error('toml:InvalidUTF8', 'Truncated UTF-8 in file %s', filename); end
      b2 = uint32(bytes(i+1)); b3 = uint32(bytes(i+2));
      if b2 < 0x80 || b2 > 0xBF || b3 < 0x80 || b3 > 0xBF
        error('toml:InvalidUTF8', 'Invalid UTF-8 continuation in file %s at byte %d', filename, i+1);
      end
      cp = bitand(b, uint32(0x0F)) * 4096 + bitand(b2, uint32(0x3F)) * 64 + bitand(b3, uint32(0x3F));
      if cp < 0x800
        error('toml:InvalidUTF8', 'Overlong UTF-8 encoding in file %s at byte %d', filename, i);
      end
      if cp >= 0xD800 && cp <= 0xDFFF
        error('toml:InvalidUTF8', 'Surrogate codepoint U+%04X in file %s', cp, filename);
      end
      out_pos = out_pos + 1;
      buf(out_pos) = cp;
      i = i + 3;

    elseif b < 0xF8
      if i + 3 > n, error('toml:InvalidUTF8', 'Truncated UTF-8 in file %s', filename); end
      b2 = uint32(bytes(i+1)); b3 = uint32(bytes(i+2)); b4 = uint32(bytes(i+3));
      if b2 < 0x80 || b2 > 0xBF || b3 < 0x80 || b3 > 0xBF || b4 < 0x80 || b4 > 0xBF
        error('toml:InvalidUTF8', 'Invalid UTF-8 continuation in file %s at byte %d', filename, i+1);
      end
      cp = bitand(b, uint32(0x07)) * 262144 + bitand(b2, uint32(0x3F)) * 4096 + ...
           bitand(b3, uint32(0x3F)) * 64 + bitand(b4, uint32(0x3F));
      if cp < 0x10000
        error('toml:InvalidUTF8', 'Overlong UTF-8 encoding in file %s at byte %d', filename, i);
      end
      if cp > 0x10FFFF
        error('toml:InvalidUTF8', 'Codepoint U+%X out of range in file %s', cp, filename);
      end
      % Encode as UTF-16 surrogate pair
      u = cp - uint32(0x10000);
      buf(out_pos+1) = bitor(uint32(0xD800), bitshift(u, -10));
      buf(out_pos+2) = bitor(uint32(0xDC00), bitand(u, uint32(0x3FF)));
      out_pos = out_pos + 2;
      i = i + 4;

    else
      error('toml:InvalidUTF8', 'Invalid UTF-8 leading byte 0x%02X in file %s', b, filename);
    end
  end

  raw_text = char(buf(1:out_pos));
end

function raw_text = read_utf8_octave(filename)
  % In Octave, chars are 8-bit. Pass raw UTF-8 bytes as chars.
  raw_text = '';
  fid = fopen(filename, 'r');
  while ~feof(fid)
    c = fread(fid, 1);
    if c < 128
      raw_text = [raw_text, char(c)];
    elseif c < 192
      error('toml:InvalidUTF8', 'Bad UTF-8 in file %s', filename);
    else
      b2 = fread(fid, 1);
      if b2 < 128 || b2 > 191
        error('toml:InvalidUTF8', 'Bad UTF-8 continuation in file %s', filename);
      end
      % Detect CESU-8 surrogate: leading byte 0xED, continuation 0xA0-0xBF
      if c == 0xED && b2 >= 0xA0 && b2 <= 0xBF
        error('toml:InvalidUTF8', 'Surrogate codepoint in UTF-8 in file %s', filename);
      end
      raw_text = [raw_text, char(c), char(b2)];
      if c >= 0xE0
        b3 = fread(fid, 1);
        if b3 < 128 || b3 > 191
          error('toml:InvalidUTF8', 'Bad UTF-8 continuation in file %s', filename);
        end
        raw_text = [raw_text, char(b3)];
        if c >= 0xF0
          b4 = fread(fid, 1);
          if b4 < 128 || b4 > 191
            error('toml:InvalidUTF8', 'Bad UTF-8 continuation in file %s', filename);
          end
          raw_text = [raw_text, char(b4)];
        end
      end
    end
  end
  fclose(fid);
end