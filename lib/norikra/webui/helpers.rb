
module Norikra::WebUI::Helpers
  def url_for(ref)
    "#{request.script_name}#{ref}"
  end
end
