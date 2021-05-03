--THIS IS SUPABASE SQL to be run in the SQL editor of Supabase.io for setting up your initial test project.

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
  CreatedByUserId uuid references auth.users not null,
  FOREIGN KEY (ParentQuestId) REFERENCES Quest(QuestId)
);
  

CREATE TABLE UserQuest (
  UserQuestId bigint generated by default as identity primary key,
  QuestId int4 references Quest not null,
  user_id uuid references auth.users not null
);

CREATE TABLE Party (
  GroupId bigint generated by default as identity primary key,
  GroupName varchar not null,
  GroupType int4 default 1 not null,
  CreatedDate timestamp with time zone default timezone('utc'::text, now()) not null
);

CREATE TABLE UserParty (
  UserPartyId bigint generated by default as identity primary key,
  user_id uuid references auth.users not null,
  PartyId bigint references Party not null,
  RoleId int4 default 1 not null
);

CREATE TABLE PartyEpic (
  PartyEpicId bigint generated by default as identity primary key,
  PartyId int4 references Party not null,
  EpicId int4 references Epic not null
);

CREATE TABLE EpicQuest (
  EpicQuestId bigint generated by default as identity primary key,
  EpicId int4 references Epic not null,
  QuestId int4 references Quest not null
);

CREATE TABLE Reward (
  RewardId bigint generated by default as identity primary key,
  user_id uuid references auth.users not null,
  Reward text,
  RedemptionStatus int default 0,
  RedemptionDate timestampe default null
)

CREATE TABLE UserDetail (
  UserDetailId bigint generated by default as identity primary key,
  user_id uuid references auth.users not null,
  AvatarUrl varchar default null,
  DisplayName varchar default null,
  ExperiencePoints int default 0
);

--- function for getting and creating hero information if it doesn't exist...
CREATE OR REPLACE FUNCTION GetHero()
RETURNS table(avatarurl varchar, displayname varchar, experiencepoints int4)
AS $Body$
  DECLARE userId uuid;
begin
  userId = auth.uid();
  IF NOT EXISTS (SELECT user_id FROM userdetail WHERE user_id = userId) THEN
    INSERT INTO userdetail
      (user_id, avatarurl, displayname, experiencepoints) VALUES (userId, '','New Hero',0);
  END IF;
  return 
    QUERY SELECT ud.avatarurl, ud.displayname, ud.experiencepoints FROM userdetail ud WHERE user_id = userId;
END
$Body$
LANGUAGE plpgsql VOLATILE;

---


  
ALTER TABLE Quest ENABLE ROW LEVEL SECURITY;
ALTER TABLE UserQuest ENABLE ROW LEVEL SECURITY;
ALTER TABLE UserDetail ENABLE ROW LEVEL SECURITY;
ALTER TABLE Reward ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Individuals can create Quests" on quest FOR INSERT
	WITH CHECK (auth.uid() = CreatedByUserId);

CREATE POLICY "Individuals can update quests" ON Quest FOR UPDATE
  USING (auth.uid() = CreatedByUserId);

CREATE POLICY "Individuals can Get Quests" on Quest FOR SELECT
	using (auth.uid() = CreatedByUserId);

CREATE POLICY "Individuals can link quests" on UserQuest FOR ALL
	WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Individuals can create/Update Rewards" on Reward FOR ALL
	WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Individuals can Get Rewards" on Reward FOR SELECT
	using (auth.uid() = user_id);


--create policy "Individuals can create todos." on todos for insert with check (auth.uid() = user_id);

--create policy "Individuals can view their own todos. " on todos for select using (auth.uid() = user_id);

--create policy "Individuals can update their own todos." on todos for update using (auth.uid() = user_id);

--create policy "Individuals can delete their own todos." on todos for delete using (auth.uid() = user_id);

create policy "Individuals can update their own user details." on userdetail for
    update using (auth.uid() = user_id);

create policy "Individuals can create user details." on userdetail for
    insert with check (auth.uid() = user_id);

create policy "Individuals can view their own details" on userdetail FOR
    select using (auth.uid() = user_id);
	
--- STORED PROCEDURES TO MAKE CODING EASIER AND MORE LOGICAL
CREATE OR REPLACE FUNCTION AddNewQuest(questName text, questDescription text, reward text, questSize text)
RETURNS integer
AS $Body$
  DECLARE newQuestId integer;
  DECLARE userId uuid;
begin
  userId = auth.uid();
  INSERT INTO quest(questname, questdescription, queststatus, reward, size,createddate, createdbyuserid) 
    VALUES (questName, questDescription, 1, reward, cast(questSize as integer), current_date, userId) RETURNING questid INTO newQuestId;
  INSERT INTO userquest (user_id, questid) VALUES (userId, NewQuestId);
  return NewQuestId;
end;
$Body$
LANGUAGE plpgsql VOLATILE;

--- Create Party
CREATE OR REPLACE FUNCTION CreateNewParty(PartyName text)
RETURNS integer
AS $Body$
  DECLARE newPartyId integer;
  DECLARE userId uuid;
begin
  userId = auth.uid();
  INSERT INTO Party(PartyName) VALUES (PartyName) RETURNING PartyId INTO newPartyId;
  INSERT INTO UserParty(user_id, PartyId, RoleId) VALUES (userId, newPartyId,3);
  return newPartyId;
end;
$Body$
LANGUAGE plpgsql VOLATILE;

--- Add Party Member
CREATE OR REPLACE FUNCTION AddPartyMember(partyid int, newMemberEmail text)
RETURNS integer
AS $Body$
  DECLARE userId uuid;
  DECLARE roleId int4;
  DECLARE newUserId uuid;
begin
  userId = auth.uid();
  -- check to see if the user is an admin of the party
  SELECT RoleId INTO roleId FROM UserParty WHERE PartyId = partyid AND user_id = userId;
  -- get the USER of the email requested
  SELECT id INTO newUserId FROM auth.users WHERE email = newMemberEmail; 
  IF (RoleId = 3) THEN 
    INSERT INTO UserParty(user_id, PartyId, RoleId) VALUES (newUserId, partyid,1);
    return NewQuestId;
  ELSE  
    RETURN 1;
  END IF;
end;
$Body$
LANGUAGE plpgsql VOLATILE;

CREATE OR REPLACE FUNCTION GetPartyAndUsers() 
RETURNS TABLE(partyId bigint, partyName text, partyUserId uuid, partyUserEmail text)
AS $Body$
  DECLARE userId uuid;
begin
  userId = auth.uid();
  return 
    QUERY SELECT 
            p.PartyId, p.PartyName, up.user_id, u.email 
          FROM 
            UserParty up 
            LEFT JOIN Party p ON p.PartyId = up.PartyId
            LEFT JOIN auth.users u ON u.user_id = up.user_id
          WHERE up.PartyId IN (SELECT PartyId FROM UserParty WHERE user_id = userId);
end;
$Body$
LANGUAGE plpgsql VOLATILE;

--- Create quest for party member
CREATE OR REPLACE FUNCTION CreateQuestForPartyMember(questName text, questDescription text, reward text, questSize text, targetUserId uuid)
RETURNS integer
AS $Body$
  DECLARE newQuestId integer;
  DECLARE userId uuid;
begin
  userId = auth.uid();
  --check to see if this is a party admin for the target user
  IF EXISTS (SELECT user_id FROM UserGroup WHERE GroupId IN (SELECT groupid FROM usergroup WHERE user_id = targetUserId) AND user_id = userId AND roleid = 3) THEN
    INSERT INTO quest(questname, questdescription, queststatus, reward, size,createddate, createdbyuserid) 
      VALUES (questName, questDescription, 1, reward, cast(questSize as integer), current_date, userId) RETURNING questid INTO newQuestId;
    INSERT INTO userquest (targetUserId, questid) VALUES (userId, NewQuestId);
    return NewQuestId;
  ELSE 
    return 0;
  END IF;
end;
$Body$
LANGUAGE plpgsql VOLATILE;
 
	
--- GET QUESTS
CREATE OR REPLACE FUNCTION GetQuests()
RETURNS TABLE (questId int8, questname varchar, questdescription varchar, questatus int4, reward text, size int4, createddate timestamptz, completeddate timestamptz, expiredate timestamptz)
AS $Body$
  DECLARE userId uuid;
begin
  userId = auth.uid();
  return 
    QUERY SELECT 
            q.QuestId, q.questname, q.questdescription, q.queststatus, q.reward, q.size, q.createddate, q.completeddate, q.expiredate 
          FROM UserQuest uq LEFT JOIN Quest q ON q.questid = uq.questid 
          WHERE uq.user_id = userId AND q.queststatus = 1;
end;
$Body$
LANGUAGE plpgsql VOLATILE;
	
--- COMPLETE QUEST
CREATE OR REPLACE FUNCTION completequest(completedquestid bigint)
RETURNS integer
AS $Body$
  DECLARE userId uuid;
  DECLARE QuestReward text;
  DECLARE QuestSize int;
  DECLARE xpValue int;
begin
  userId = auth.uid();
  --Check to see if this quest ID is owned by this user
  IF EXISTS (SELECT questId FROM userquest WHERE questid = completedquestid AND user_id = userId) THEN
    SELECT reward, size INTO QuestReward, QuestSize FROM quest WHERE questid = completedquestid;
    UPDATE quest SET completeddate = current_date, queststatus = 2 WHERE questid = completedquestid;
    INSERT INTO reward (user_id, reward) VALUES (userId, QuestReward);
    CASE 
      WHEN QuestSize = 1 THEN xpValue = 100;
      WHEN QuestSize = 2 THEN xpValue = 400;
      WHEN QuestSize = 3 THEN xpValue = 1200;
      WHEN QuestSize = 4 THEN xpValue = 2500;
      ELSE xpValue = 0;
    END CASE;
    UPDATE userdetail SET experiencepoints = experiencepoints + xpValue WHERE user_id = userId;
  END IF;
  return 1;
END;
$Body$
LANGUAGE plpgsql VOLATILE;

--Permissions for functions/stored proceedures to access the auth

GRANT EXECUTE ON FUNCTION GetQuests() TO PUBLIC;
GRANT EXECUTE ON FUNCTION completequest(completedquestid bigint) TO PUBLIC;
GRANT EXECUTE ON FUNCTION createnewparty(partyname text) TO PUBLIC;
GRANT EXECUTE ON FUNCTION addpartymember(partyid int, newmemberemail text) TO PUBLIC;
GRANT EXECUTE ON FUNCTION createquestforpartymember(questname text, questdescription text, reward text, questsize text, targetuserid uuid)
GRANT EXECUTE ON FUNCTION GetPartyAndUsers() 


grant usage on schema auth to anon;
grant usage on schema auth to authenticated;

