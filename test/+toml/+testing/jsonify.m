function str = jsonify(obj)
	if isa(obj, 'containers.Map') || isa(obj, 'dictionary')
		if isa(obj, 'dictionary')
			key_list = cellstr(keys(obj));
			get_val = @(k) obj(k); % returns cell-wrapped value
			unwrap  = @(v) v{1};
		else
			key_list = keys(obj);
			get_val  = @(k) obj(k);
			unwrap   = @(v) v;
		end
		print_key_value = @(k) ['"' escape_str(k) '":' toml.testing.jsonify(unwrap(get_val(k)))];
		keys_and_values = cellfun(print_key_value, key_list, 'uniformoutput', false);
		str = ['{', strjoin(keys_and_values, ','), '}'];

	elseif isstruct(obj)
		print_key_value = @(k) ['"' escape_str(k) '":' toml.testing.jsonify(obj.(k))];
		keys_and_values = cellfun(print_key_value, fieldnames(obj), 'uniformoutput', false);
		str = ['{', strjoin(keys_and_values, ','), '}'];

	elseif iscell(obj)
		values = cellfun(@toml.testing.jsonify, obj, 'uniformoutput', false);
		str = ['[', strjoin(values, ','), ']'];

	elseif ischar(obj)
		if regexp(obj, '^\d{4}-\d{2}-\d{2}[T ]\d{2}:\d{2}:\d{2}(\.\d+)?[Z+-]')
			str = ['{"type":"datetime","value":"', obj, '"}'];
		elseif regexp(obj, '^\d{4}-\d{2}-\d{2}[T ]\d{2}:\d{2}:\d{2}')
			str = ['{"type":"datetime-local","value":"', obj, '"}'];
		elseif regexp(obj, '^\d{4}-\d{2}-\d{2}$')
			str = ['{"type":"date-local","value":"', obj, '"}'];
		elseif regexp(obj, '^\d{2}:\d{2}:\d{2}(\.\d+)?$')
			str = ['{"type":"time-local","value":"', obj, '"}'];
		else
			str = ['{"type":"string","value":"', escape_str(obj), '"}'];
		end

	elseif numel(obj) ~= 1 && ndims(obj) == 2 && size(obj, 1) == 1
		values = arrayfun(@toml.testing.jsonify, obj, 'uniformoutput', false);
		str = ['[', strjoin(values, ','), ']'];

	elseif numel(obj) ~= 1
	    cel = cell(1, size(obj, 1));
	    indices = repmat({':'}, 1, ndims(obj));
	    for row = 1:size(obj, 1)
			indices{1} = row;
			cel{row} = toml.testing.jsonify(squeeze(obj(indices{:})));
	    end
	    str = ['[', strjoin(cel, ', '), ']'];		

	elseif islogical(obj)
		if obj
			val = 'true';
		else
			val = 'false';
		end
		str = ['{"type":"bool","value":"', val, '"}'];

	elseif isnumeric(obj)
		if isinteger(obj)
			str = sprintf('{"type":"integer","value":"%d"}', obj);
		elseif isnan(obj)
			str = '{"type":"float","value":"nan"}';
		elseif isinf(obj) && obj > 0
			str = '{"type":"float","value":"inf"}';
		elseif isinf(obj) && obj < 0
			str = '{"type":"float","value":"-inf"}';
		else
			str = sprintf('{"type":"float","value":"%.16g"}', obj);
		end

	else
		error("don't know what this is");
	end
end

function out = escape_str(str)
	% Produce a pure-ASCII JSON string body (no surrounding quotes).
	% All non-ASCII codepoints are emitted as \uXXXX (BMP) or
	% \uXXXX\uXXXX surrogate pairs (supplementary plane), so the result
	% is safe regardless of the caller's locale / fprintf encoding.
	%
	% Handles two char encodings transparently:
	%   MATLAB: chars are UTF-16 code units; surrogates appear as pairs.
	%   Octave:  chars are raw UTF-8 bytes; multi-byte sequences must be
	%            decoded to codepoints before escaping.
	out = '';
	idx = 1;
	is_octave = exist('OCTAVE_VERSION', 'builtin') > 0;
	while idx <= numel(str)
		c = double(str(idx));

		% ---- mandatory JSON escapes ----
		if c == double('"')
			out = [out '\"'];
			idx = idx + 1;
			continue
		elseif c == double('\')
			out = [out '\\'];
			idx = idx + 1;
			continue
		elseif c < 0x20
			out = [out '\u' sprintf('%04X', c)];
			idx = idx + 1;
			continue
		end

		% ---- pure ASCII printable: pass through ----
		if c <= 0x7E
			out = [out str(idx)];
			idx = idx + 1;
			continue
		end

		% ---- non-ASCII: decode to codepoint, then emit \uXXXX ----
		if is_octave
			% Octave stores raw UTF-8 bytes in char arrays.
			if c < 0xC0
				% Unexpected continuation byte – pass raw (shouldn't happen in
				% well-formed UTF-8, but be defensive).
				cp = uint32(c);
				idx = idx + 1;
			elseif c < 0xE0
				% 2-byte sequence: 110xxxxx 10xxxxxx
				b2 = double(str(idx+1));
				cp = uint32(bitand(c, 0x1F)) * 64 + uint32(bitand(b2, 0x3F));
				idx = idx + 2;
			elseif c < 0xF0
				% 3-byte sequence: 1110xxxx 10xxxxxx 10xxxxxx
				b2 = double(str(idx+1)); b3 = double(str(idx+2));
				cp = uint32(bitand(c, 0x0F)) * 4096 + ...
				     uint32(bitand(b2, 0x3F)) * 64 + ...
				     uint32(bitand(b3, 0x3F));
				idx = idx + 3;
			else
				% 4-byte sequence: 11110xxx 10xxxxxx 10xxxxxx 10xxxxxx
				b2 = double(str(idx+1)); b3 = double(str(idx+2)); b4 = double(str(idx+3));
				cp = uint32(bitand(c, 0x07)) * 262144 + ...
				     uint32(bitand(b2, 0x3F)) * 4096 + ...
				     uint32(bitand(b3, 0x3F)) * 64 + ...
				     uint32(bitand(b4, 0x3F));
				idx = idx + 4;
			end
		else
			% MATLAB stores UTF-16 code units.
			if c >= 0xD800 && c <= 0xDBFF && idx + 1 <= numel(str)
				% High surrogate followed by low surrogate → decode to codepoint.
				low = double(str(idx + 1));
				cp  = uint32(0x10000) + (uint32(c) - uint32(0xD800)) * 1024 + ...
				      (uint32(low) - uint32(0xDC00));
				idx = idx + 2;
			else
				cp  = uint32(c);
				idx = idx + 1;
			end
		end

		% ---- emit codepoint as \uXXXX or surrogate pair ----
		if cp <= 0xFFFF
			out = [out '\u' sprintf('%04X', cp)];
		else
			% Supplementary plane → surrogate pair escape
			u  = cp - uint32(0x10000);
			w1 = bitor(uint32(0xD800), bitshift(u, -10));
			w2 = bitor(uint32(0xDC00), bitand(u, uint32(0x3FF)));
			out = [out '\u' sprintf('%04X', w1) '\u' sprintf('%04X', w2)];
		end
	end
end
