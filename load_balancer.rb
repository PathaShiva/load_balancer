require "./database_monitor"

class LoadBalancer
  include DatabaseMonitor

  DATABASE_MONITOR_INTERVAL = 10

  POLICY_NAME = {
    'dynamic_weight' => DynamicWeight
  } 

  attr_reader :workers,:databases,:priority_queue,:current_requests,:policy

  def initialize()
    @databases = {}
    database_monitor
    @workers = 120
    @priority_queue = SizedQueue.new
    @traffic = 0
    @policy = nil
    queue_thread
  end

  def request params
    begin
      if @policy.should_perform? params[:database]
        if @traffic >= 120
          @priority_queue.push params
        else
          connect_to_server params
        end
      else
        raise "Server is down"
      end
    rescue
      sleep(5)
      retry
    end
  end

  def connect_to_server params
    @traffic += 1
    Thread.new {
      Server.new.execute params
      @traffic -= 1
      @policy.reduce_traffic params[:database]
    }
  end

  def add_database db
    @databases[db[:database]] = {
      state: "enabled",
      host: db[:host],
      database: db[:database],
      username: db[:username],
      password: db[:password],
      status: {
        state: "online",
        respond_time: 0
      } 
    }
  end

  def remove_database database
    @databases.delete(database)
  end

  # Set settings for databases
    #
    # @param args [Hash]
    # @option args :databases, :no_of_workers
    # @return
  def configure(args)
    args[:databases].each do |db|
      @databases[db[:database]] = {
        state: "enabled",
        host: db[:host],
        database: db[:database],
        username: db[:username],
        password: db[:password],
        status: {
            state: "online",
            respond_time: 0
        } 
     }
    end
    @workers = args[:no_of_workers]
    @policy = POLICY_NAME[args[:policy]].new(@databases)
    monitor
  end

  
  private

  def database_monitor
    Thread.new {
        while(true)
          monitor
          sleep(DATABASE_MONITOR_INTERVAL)
        end
    }
    rescue
      false
  end

  def queue_thread
    Thread.new {
      while(true)
        while(@priority_queue.size > 0 && @traffic < 120)
          connect_to_server(@priority_queue.pop)
        end
        sleep(@priority_queue.size > 0 ? 1 : 5)
      end
  }
  rescue
    false
  end

end