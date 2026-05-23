function str = jsonify(obj)
	if isa(obj, 'containers.Map')
		print_key_value = @(k) ['"' escape_str(k) '":' toml.testing.jsonify(obj(k))];
		keys_and_values = cellfun(print_key_value, keys(obj), 'uniformoutput', false);
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
	out = '';
	idx = 1;
	while idx <= numel(str)
		c = double(str(idx));
		if c == double('"')
			out = [out '\"'];
		elseif c == double('\')
			out = [out '\\'];
		elseif c < 0x20
			out = [out '\u' sprintf('%04X', c)];
		elseif c >= 0xD800 && c <= 0xDBFF
			% MATLAB UTF-16 high surrogate — consume paired low surrogate
			if idx + 1 <= numel(str)
				low = double(str(idx + 1));
				out = [out '\u' sprintf('%04X', c) '\u' sprintf('%04X', low)];
				idx = idx + 1;
			else
				out = [out '\u' sprintf('%04X', c)];
			end
		elseif c >= 0xF0 && c <= 0xF4
			% Octave raw UTF-8 4-byte sequence for supplementary-plane codepoint
			if idx + 3 <= numel(str)
				b2 = double(str(idx+1)); b3 = double(str(idx+2)); b4 = double(str(idx+3));
				cp = bitand(uint32(c), uint32(0x07)) * 262144 + ...
				     bitand(uint32(b2), uint32(0x3F)) * 4096 + ...
				     bitand(uint32(b3), uint32(0x3F)) * 64 + ...
				     bitand(uint32(b4), uint32(0x3F));
				u  = cp - uint32(0x10000);
				w1 = bitor(uint32(0xD800), bitshift(u, -10));
				w2 = bitor(uint32(0xDC00), bitand(u, uint32(0x3FF)));
				out = [out '\u' sprintf('%04X', w1) '\u' sprintf('%04X', w2)];
				idx = idx + 3;
			else
				out = [out str(idx)];
			end
		elseif c > 0xFFFF
			% Large codepoint stored as single value (unusual)
			u = uint32(c) - uint32(0x10000);
			w1 = bitor(uint32(0xD800), bitand(u, uint32(0b11111111110000000000)));
			w2 = bitor(uint32(0xDC00), bitand(u, uint32(0b00000000001111111111)));
			out = [out '\u' sprintf('%04X', w1) '\u' sprintf('%04X', w2)];
		else
			out = [out str(idx)];
		end
		idx = idx + 1;
	end
end
