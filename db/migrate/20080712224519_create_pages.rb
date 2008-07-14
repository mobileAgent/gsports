class CreatePages < ActiveRecord::Migration
  def self.up
    create_table :pages do |t|
      t.string :name
      t.string :permalink
      t.text :content
      t.text :html_content
      t.timestamps
    end

    # Create the initial static pages
    about = Page.new :name => 'About Us', :permalink => 'about'
    about.content= "Initial content for the about us page"
    about.save!
    
    tos = Page.new :name => 'Terms of Service', :permalink => 'terms'
    tos.content= "Initial content for the terms of service page"
    tos.save!

    privacy = Page.new :name => 'Privacy Policy', :permalink => 'privacy'
    privacy.content= "Initial content for the privacy policy page"
    privacy.save!
    
    contact = Page.new :name => 'Contact Us', :permalink => 'contact'
    contact.content= "Initial content for the contact us page"
    contact.save!
    
    help = Page.new :name => 'Help', :permalink => 'help'
    help.content= "Initial content for the help page"
    help.save!
    
    advertising = Page.new :name => 'Advertising Opportunities', :permalink => 'advertising'
    advertising.content= "Initial content for the advertising opportunities page"
    advertising.save!

  end
  
  def self.down
    drop_table :pages
  end
end
