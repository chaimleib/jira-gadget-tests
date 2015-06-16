
def hashify(o)
  return o if [
    Bignum,
    Fixnum,
    Float,
    Symbol,
    String,
    TrueClass,
    FalseClass,
    NilClass,
  ].include? o.class
    
  j = o.to_json
  h = JSON.parse(j)
end

def clean_recurse(obj)
  def _clean_recurse(h)
    return h if h.class != Hash
    result = {}
    h.each do |k, v|
      next if v.nil?
      result[k] = clean_recurse(v)
    end
    result
  end
  
  h = hashify(obj)
  _clean_recurse(h)
end

