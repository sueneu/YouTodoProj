THIS IS SUPABASE SQL to be run in the SQL editor of Supabase.io for setting up your initial test project.

create table todos (
  id bigint generated by default as identity primary key,
  user_id uuid references auth.users not null,
  task text check (char_length(task) > 3),
  is_complete boolean default false,
  inserted_at timestamp with time zone default timezone('utc'::text, now()) not null
);
  
CREATE TABLE Epic (
  EpicId bigint generated by default as identity primary key,
  EpicName varchar NOT NULL,
  CreatedDate timestamp WITH time zone default timezone('utc'::text, now()) not null                                                        
);
  
CREATE TABLE Quest (
  QuestId bigint generated by default as identity primary key,
  QuestName varchar not null,
  QuestDescription varchar not null,
  Reward text not null,
  Size int4 not null,
  ParentQuestId int4 default null,
  QuestStatus int4 default 0 not null,
  CreatedDate timestamp WITH time zone default timezone('utc'::text, now()) not null,                                                   
  StartDate timestamp WITH time zone null,  
  CompletedDate timestamp WITH time zone null,  
  ExpireDate timestamp WITH time zone null,
  FOREIGN KEY (ParentQuestId) REFERENCES Quest(QuestId)
);
  

CREATE TABLE UserQuest (
  UserQuestId bigint generated by default as identity primary key,
  QuestId int4 references Quest not null,
  user_id uuid references auth.users not null
);
  
CREATE TABLE UserGroup (
  GroupId bigint generated by default as identity primary key,
  GroupName varchar not null,
  GroupType int4 default 1 not null,
  CreatedDate timestamp with time zone default timezone('utc'::text, now()) not null
);

CREATE TABLE GroupEpic (
  GroupEpicId bigint generated by default as identity primary key,
  UserGroupId int4 references UserGroup not null,
  EpicId int4 references Epic not null
);

CREATE TABLE EpicQuest (
  EpicQuestId bigint generated by default as identity primary key,
  EpicId int4 references Epic not null,
  QuestId int4 references Quest not null
);

CREATE TABLE UserDetail (
  user_id uuid references auth.users not null,
  AvatarUrl varchar default null,
  DisplayName varchar default null,
  ExperiencePoints int default 0
);

  
alter table todos enable row level security;

create policy "Individuals can create todos." on todos for
    insert with check (auth.uid() = user_id);

create policy "Individuals can view their own todos. " on todos for
    select using (auth.uid() = user_id);

create policy "Individuals can update their own todos." on todos for
    update using (auth.uid() = user_id);

create policy "Individuals can delete their own todos." on todos for
    delete using (auth.uid() = user_id);