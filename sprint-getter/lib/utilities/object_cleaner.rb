
def hashify(o)
  # convert objects to a plain hash using its to_json method
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
  # hashify and recursively remove fields set to nil and return the 
  # resulting hash
  
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

