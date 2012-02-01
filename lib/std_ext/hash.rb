class Hash
  def symbolize
    inject({}) do |hash, (key, value)|
      hash[key.to_sym] = case value
                           when String then value.to_sym
                           when Hash   then value.symbolize
                           else value
                         end

      hash
    end
  end
end