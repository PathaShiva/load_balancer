class DynamicWeight < Policy
    RECALC_WEIGHT_INTERVAL = 5

  def initialize(dbs)
    super(dbs)
    set_weights
  end

  def should_perform? database
    db = @databases[database]
    return false if db[:state] == "disabled" || db[:status][:state] == "offline"
    if db[:status][:respond_time] < 5 || db[:traffic] < 10 || db[:weight] >= 80
        db[:traffic] ||= 0
        db[:traffic] += 1
        true
    else
        false
    end
  end
  
  # Calc Database weight
    #
  def calc_weigth
      sum = sum_respond_time
      @databases.each do |k,db|
          db[:weight] = 100 - ((db[:status][:respond_time] / sum) * 100).to_i if db[:status][:state] == 'online' && db[:state] == 'enable'
      end unless sum.zero?
  end

  private 

  def sum_respond_time
      sum = 0
      @databases.each do |k,db|
          sum += db[:status][:respond_time] if db[:status][:state] == 'online' && db[:state] == 'enable'
      end
      sum
  end

  def set_weights
    Thread.new{
      while(true)
        sleep(RECALC_WEIGHT_INTERVAL)
        calc_weigth
      end
    }
  rescue => e
    puts "Exception: #{e.inspect}"
  end
end