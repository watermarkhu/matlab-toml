function val = dict_get(m, key)
  val = m(string(key));
  if iscell(val)
    val = val{1};
  end
end
