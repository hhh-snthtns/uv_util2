require 'thread'
require 'timeout'

module UvUtil2
  module QueueTask
    def init
      @queue = make_queue
      @execute_flag = true
      @thread_list = []
      @worker_count.times do
        @thread_list << Thread.new do
          base_execute(@worker_error_sleep_second) do
            data = @queue.pop
            execute_worker(data)
            sleep @worker_sleep_second if !@worker_sleep_second.nil? && @worker_sleep_second > 0
          end
        end
      end
    end

    def make_queue
      SizedQueue.new(@worker_count)
    end

    def stop
      @execute_flag = false
      @thread_list.each do |it|
        it.join
      end
    end

    def get_data
      true
    end

    def get_queue
      @queue
    end

    def base_execute(error_sleep_second)
      error_ts = nil
      while @execute_flag do
        begin
          while @execute_flag do
            yield
          end
        rescue Exception => e
          # エラーが起きたら一定期間ごとにメールを送信する
          error_ts = @mailer.process_error(e, error_ts, subject: "base_execute") if @mailer
          @logger.warn(e) if @logger

          # 一定期間スリープする
          sleep error_sleep_second if !error_sleep_second.nil? && error_sleep_second > 0
        end
      end
    end

    def execute
      base_execute(@task_error_sleep_second) do
        data = get_data
        if data
          @queue.push(data)
        else
          sleep @task_sleep_second if !@task_sleep_second.nil? && @task_sleep_second > 0
        end
      end
    end
  end
end
