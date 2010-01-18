class MessageThreadsData < ActiveRecord::Migration
  def self.up
      
    add_column :sent_messages_obsolete, :new_thread_id, :integer, :limit => 11
    add_column :message_threads, :old_thread_id, :integer, :limit => 11
        
    execute "insert into message_threads (title,from_id,created_at,to_ids,to_emails,to_access_group_ids) 
      select title,from_id,created_at,to_ids,to_emails,to_access_group_ids from sent_messages_obsolete where thread_id is null"
    execute "update sent_messages_obsolete set new_thread_id=(select min(t.id) from message_threads t where t.title=sent_messages_obsolete.title and t.from_id=sent_messages_obsolete.from_id and t.created_at=sent_messages_obsolete.created_at) where thread_id is null and new_thread_id is null"

    execute "insert into message_threads (title,from_id,created_at,to_ids,to_emails,to_access_group_ids,old_thread_id) 
      select s.title, s.from_id, s.created_at, s.to_ids, s.to_emails, s.to_access_group_ids, s.thread_id 
      from sent_messages_obsolete s, (select thread_id, min(id) as id from sent_messages_obsolete where thread_id is not null group by thread_id) x where s.id=x.id"
    execute "update sent_messages_obsolete set new_thread_id=(select min(t.id) from message_threads t where t.title=sent_messages_obsolete.title and t.from_id=sent_messages_obsolete.from_id and t.created_at=sent_messages_obsolete.created_at) where thread_id is not null and new_thread_id is null"        
    execute "update sent_messages_obsolete set new_thread_id=(select min(t.id) from message_threads t where t.old_thread_id=sent_messages_obsolete.thread_id) where thread_id is not null and new_thread_id is null"
    
    add_column :sent_messages, :old_id, :integer, :limit => 11
    
    execute "insert into sent_messages (thread_id,from_id,body,created_at,old_id) 
      select new_thread_id,from_id,body,created_at,id from sent_messages_obsolete"

    add_column :messages, :old_id, :integer, :limit => 11

    execute "insert into messages (sent_message_id,thread_id,to_id,created_at,old_id) 
      select distinct s.id as sent_message_id, s.thread_id, m.to_id, m.created_at, m.id as old_id
      from sent_messages s, messages_obsolete m, message_threads t, sent_messages_obsolete o 
     where s.thread_id=t.id
       and t.title=m.title 
       and m.from_id=s.from_id 
       and m.created_at between s.created_at-interval 1 minute and s.created_at+interval 1 minute
       and s.old_id=o.id and (o.to_ids is null or o.to_ids = '' or locate(m.to_id,o.to_ids) > 0)"

    add_column :message_threads, :old_message_id, :integer, :limit => 11

    # need to set to_ids string...
    execute "insert into message_threads (title, from_id, created_at, old_message_id, to_ids) 
      select o.title, o.from_id, min(o.created_at), min(o.id),
        group_concat(distinct o.to_id separator '/') as to_ids
      from messages_obsolete o 
      where o.id not in (select old_id from messages) group by o.title, o.from_id"    

    execute "insert into sent_messages (thread_id, from_id, body, created_at)
      select distinct t.id, m.from_id, m.body, m.created_at
      from messages_obsolete m, message_threads t
      where t.title=m.title and t.old_message_id is not null
        and m.id not in (select old_id from messages)"
     
    execute "insert into messages (sent_message_id,thread_id,to_id,created_at,old_id)
      select s.id as sent_message_id, s.thread_id, m.to_id, m.created_at, m.id as old_id
      from messages_obsolete m, sent_messages s, message_threads t
      where m.body=s.body and s.thread_id=t.id and m.title=t.title
        and m.created_at = s.created_at
        and m.id not in (select old_id from messages)
        and m.from_id=s.from_id and t.from_id=s.from_id
        and t.old_message_id is not null and s.old_id is null"
      
    # the read flag is tricky since it is a reserved word, so I couldn't get it to work in the insert statement
    execute "update messages set messages.read=(select o.read from messages_obsolete o where o.id=messages.old_id)"
    
    execute "delete from sent_messages where id not in (select distinct sent_message_id from messages)"
      
    remove_column :sent_messages_obsolete, :new_thread_id
    remove_column :message_threads, :old_thread_id
    remove_column :sent_messages, :old_id
    remove_column :messages, :old_id
    remove_column :message_threads, :old_message_id
 
    # leave these alone just in case....
    #drop_table :messages_obsolete
    #drop_table :sent_messages_obsolete
       
  end

  def self.down
    
    execute "truncate table messages"
    execute "truncate table sent_messages"
    execute "truncate table message_threads" 
    
  end
end
