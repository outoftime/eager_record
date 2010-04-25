module EagerRecord
  module SpecHelpers
    private

    def fail_on_select
      ActiveRecord::Base.connection.should_not_receive :select_all
    end
  end
end
