Let’s start with the views.

```
<!-- app/views/show.html.erb-->

<div class="my-16">
  <h2 class="text-3xl font-extrabold text-slate-900 dark:text-slate-100 tracking-tight mb-3">
      <%= turbo_frame_tag "post_#{@post.id}_comment_count" do %>
        <%= pluralize(@post.comments.size, 'comment') %>
    <% end %>
  </h2>

  <%= turbo_frame_tag "post_comment_form" do %>
    <%= render "comments/form", post: @post, comment: @comment %>
  <% end %>

  <hr class="my-6">

  <%= turbo_frame_tag "post_#{@post.id}_comments" do %>
    <%= render partial: "comments/comment", collection: @post.comments %>
  <% end %>
</div>
```

In the form’s case, we must ensure a matching turbo frame tag in the comments/\_form.html.erb partial. I called mine post_comment_form but you could make this anything so long as it matches what’s over on posts/show.html.erb.

```

<!-- app/views/comments/_form.html.erb-->
<%= turbo_frame_tag "post_comment_form" do %>
  <%= form_with(model: [post, comment]) do |form| %>
    <%= render "shared/error_messages", resource: form.object %>

    <div class="form-group">
      <%= form.label :content, "Reply", class: "form-label" %>
      <%= form.text_area :content, class: "form-input", placeholder: "Type a response" %>
    </div>

    <%= form.submit class: "btn btn-primary" %>

  <% end %>
<% end %>
```

In the app/views/\_comment.html.erb partial, we need to add a unique ID attribute to target comments individually. I reached for the dom_id view helper to aid in this. It outputs comment_1 based on the class and ID. The main thing we need is for each ID to be unique.

```

<!-- app/views/comments/_comment.html.erb-->
<%= turbo_frame_tag dom_id(comment) do %>
  <div class="p-6 bg-slate-50 rounded-xl mb-6">
    <p class="font-semibold"><%= comment.user.name %></p>
    <div class="prose prose-slate">
      <%= comment.content %>
    </div>
  </div>
<% end %>
```

With the views out of the way, we can focus on the controller. I’ll update the response to include turbo_stream.

```
def create
  @comment = @post.comments.new(comment_params.merge(user: current_user))

  respond_to do |format|
    if @comment.save
      format.turbo_stream
      format.html { redirect_to post_url(@post), notice: "Comment was successfully created." }
      format.json { render :show, status: :created, location: @comment }
    else
      format.turbo_stream
      format.html { render :new, status: :unprocessable_entity }
      format.json { render json: @comment.errors, status: :unprocessable_entity }
    end
  end
end
```

The only difference from before is the format.turbo_stream lines.

From here, you could append the turbo stream logic directly in the controller, but I prefer to extract it to a create.turbo_stream.erb file in the app/views/comments folder. The @post and @comment instance variables are available in that file. The file's name should coincide with the specific action on your controller.

```
# app/views/comments/create.turbo_stream.erb
<%= turbo_stream.replace "post_comment_form" do %>
  <%= render partial: "comments/form", locals: { post: @post, comment: Comment.new } %>
<% end %>

<%= turbo_stream.update "post_#{@post.id}_comment_count" do %>
  <%= pluralize(@post.comments.size, 'comment') %>
<% end %>

<%= turbo_stream.append "post_#{@post.id}_comments" do %>
  <%= render partial: "comments/comment", locals: { comment: @comment } %>
<% end %>
```
