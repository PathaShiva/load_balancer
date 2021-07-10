class Policy

  RECALC_WEIGHT_INTERVAL = 5
  attr_reader :databases

  def initialize(dbs)
    @databases = dbs || {}
  end

  def reduce_traffic database
    @databases[database][:traffic] -= 1
  end

  def refresh dbs
    @databases = dbs
  end

end