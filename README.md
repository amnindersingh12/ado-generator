# paths


Index:
   <%= link_to "Index", posts_path %>

Create:
   <%= link_to "Create", posts_path, method: 'POST' %>

New:
   <%= link_to "New", new_post_path %>

Edit:
   <%= link_to "Edit", edit_post_path(post_id) %>

Show:
   <%= link_to "Show", post_path(post_id) %>

Update:
   <%= link_to "Update", post_path(post_id), method: 'POST' %>
   <%= link_to "Update", post_path(post_id), method: 'PATCH' %>

Destroy:
   <%= link_to "Destroy", post_path(post_id), method: 'DELETE' %>