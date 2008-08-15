module UsersHelper
  
  def requested_role_name()
    id = @requested_role.to_i
    begin
      @role = Role[id]
      if(@role)
        return @role.name();
      end
    rescue
    end

    "Player/Fan"
  end

  def random_greeting(user)
    greetings = ['Hello', 'Hola', 'Hi ', 'Yo', 'Welcome back,', 'Greetings',
        'Wassup', 'Aloha', 'Halloo']
    "#{greetings.sort_by {rand}.first} #{user.full_name}!"
  end
  
  def profile_comment_form(commentable, &block)
    form_remote_for(:comment, 
      :loading => "$$('div#comments div.errors')[0].innerHTML = ''; $('comment_spinner').show();", 
      :before => "tinyMCE.activeEditor.save();", 
      :url => comments_url(Inflector.underscore(commentable.class), commentable.id ), 500 => "$$('div#comments div.errors')[0].innerHTML = request.responseText; return false;", 
      :success => "new Insertion.#{commentable.class.to_s.eql?('User') ? 'After': 'After' }('newest_comment', request.responseText); tinyMCE.activeEditor.setContent(\'\'); scrollToNewestComment();", 
      :complete => "$('comment_spinner').hide();", 
      :html => {:class => "MainForm"},
      &block
    )
  end
  
  def team_posts()
    Post.find(:all,
      :joins=>"JOIN users ON user_id = users.id",
      :conditions=>["users.team_id = ?", @user.team_id],
      :limit=>10
      )
  end
  
end
