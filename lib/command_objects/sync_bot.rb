module FBPi
  # Was once called ScheduleFactory
  class SyncBot < Mutations::Command
    required do
      duck :bot, methods: [:rest_client]
    end

    def execute
      api = bot.rest_client
      ActiveRecord::Base.transaction do
        JoinSequenceSchedules
          .run!(schedules: api.schedules.fetch,
                sequences: api.sequences.fetch)
          .tap { Schedule.destroy_all }
          .map { |s| CreateSchedule.run!(s) }
      end
      {schedules: Schedule.count,
       sequences: Sequence.count,
       steps:     Step.count}
    rescue FbResource::FetchError => e
      add_error :web_server, :fetch_error, e.message
    end
  end
end
