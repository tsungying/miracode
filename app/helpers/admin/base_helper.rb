module Admin::BaseHelper

	def nav_link(link_text, link_path)
  	class_name = request.original_url.include?(link_path) ? 'active' : nil
	  content_tag(:li, :class => class_name) do
	    link_to link_text, link_path
	  end
	end
	
end