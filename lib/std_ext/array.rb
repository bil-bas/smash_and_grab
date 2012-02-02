class Array
  def symbolize
    map do |value|
      case value
        when String
          if value =~ /^[a-z0-9_]+$/
            value.to_sym
          else
            value
          end
        when Array, Hash
          value.symbolize
        else
          value
      end
    end
  end
end