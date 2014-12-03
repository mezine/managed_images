module IsAssertions

  def assert(pass, msg="Assert Failed", skip=1)
    raise StandardError, msg, caller(skip) if !pass
  end

  def is(value, kind)
    assert(value.is_a?(kind), "#{value} must be a kind of #{kind}", 2)
    value
  end

end