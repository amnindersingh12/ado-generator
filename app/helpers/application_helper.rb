module ApplicationHelper
  def format_datetime(time)
    time.strftime("%m/%d/%Y at %H:%M:%S")
  end
  def is_admin(user)
    user.role=="admin"
  end
  def webcam_capture(form, field)
    render partial: "shared/webcam_capture", locals: { form: form, field: field }
  end
end
