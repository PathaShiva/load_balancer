require 'mysql2'
require 'timeout'
module DatabaseMonitor

    CONNECT_TIME_OUT = 10

    # Check database status
    #
    def monitor
        @databases.each do |k,db|
        if db.state == 'enable'
            start = Time.now()
            connect_to_db?(db) ? db_state = 'online' : db_state = 'offline'
            stop  = Time.now() - start
            db.status = {:time => Time.now.to_i, :state => db_state, :respond_time => stop.round(4)}
        end
        end
    end

    private

    # Check response time of database
    #
    def connect_to_db?(db)
        Timeout::timeout(CONNECT_TIME_OUT) do
            begin
                mysql_client = Mysql2::Client.new(
                    host: db[:host],
                    username: db[:username],
                    password: db[:password],
                    database: db[:database],
                    encoding: 'utf8mb4'
                )
                mysql_client.prepare("show tables").execute
                true
            rescue
                false
            end
        end
        rescue Timeout::Error
            false
        end

end