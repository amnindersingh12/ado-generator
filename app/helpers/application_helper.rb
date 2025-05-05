module ApplicationHelper
  def format_datetime(time)
    time.strftime("%m/%d/%Y at %H:%M:%S")
  end
end
