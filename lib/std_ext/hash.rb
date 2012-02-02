class Hash
  def symbolize
    each_with_object({}) do |(key, value), hash|
      hash[key.to_sym] = case value
                           when String
                             if value =~ /^[a-z0-9_]+$/
                               value.to_sym
                             else
                               value
                             end
                           when Hash, Array
                             value.symbolize
                           else
                             value
                         end
    end
  end
end