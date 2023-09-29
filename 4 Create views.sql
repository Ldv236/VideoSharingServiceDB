--**************************************************
-- ЗАКОНЧИЛОСЬ СОЗДАНИЕ ТРИГГЕРОВ, ДАЛЬШЕ СОЗДАНИЕ ПРЕДСТАВЛЕНИЙ
--**************************************************

--КОМНАТЫ
--представление с отображением комнат, в которых кто-то есть ( = активных), с подсчетом участников
CREATE VIEW public.active_room_view AS

SELECT id, name, is_private, source_url, --room_token, 
count(user_id) as user_count  FROM rooms
join room_user on rooms.id = room_user.room_id

group by id, name, is_private, source_url; --room_token;

--**************************************************

--ЮЗЕРЫ
--представление с данными юзеров + кол-во друзей, членство в комнате, разрешения в текстовом виде
CREATE VIEW public.users_view AS

SELECT profiles.id, profiles.name, count(friends.is_accepted = true) as friends_count, room_id, 
pif.name as invite_friendship, pir.name as invite_room, pvp.name as view_profile, psm.name as send_message,
birthday, users.email, is_online, status, is_block, image 

FROM profiles
left join users 		on users.id = profiles.id
left join friends 		on profiles.id in (friends.initiator_id, friends.acceptor_id) and (friends.is_accepted = true)
left join room_user		on profiles.id = room_user.user_id
join permissions pif 	on pif.id = profiles.permit_invite_friendship
join permissions pir 	on pir.id = profiles.permit_invite_room
join permissions pvp 	on pvp.id = profiles.permit_view_profile
join permissions psm 	on psm.id = profiles.permit_send_message

group by profiles.id, profiles.name, room_id, invite_friendship, invite_room, view_profile, send_message,
birthday, users.email, is_online, status, is_block, image 
order by friends_count desc;
 
--**************************************************

--УВЕДОМЛЕНИЯ
--представление с количеством уведомлений для юзера (всего, заявки в друзья, приглашения в комнаты, непрочитанные личные сообщения)
CREATE VIEW public.notify_view AS

SELECT profiles.id, profiles.name,
count(friends.is_accepted = false) + count(room_invites.acceptor_id) + count(direct_messages.is_read = false) as total_notify,
count(friends.is_accepted = false) as friends_invite,
count(room_invites.acceptor_id) as room_invite,
count(direct_messages.is_read = false) as new_message

FROM profiles
join users 					on profiles.id = users.id
left join friends 			on profiles.id = friends.acceptor_id and (friends.is_accepted = false)
left join room_invites 		on room_invites.acceptor_id = profiles.id
left join direct_messages 	on direct_messages.acceptor_id = profiles.id and (direct_messages.is_read = false)

group by profiles.id, profiles.name; 

--**************************************************

--ЧАТ ОБЩИЙ
--представление для общего чата с именами юзеров, id и названиями комнат, сообщениями
CREATE VIEW public.general_chat_view AS

SELECT username, rooms.id as invite_room_id, rooms.name as invite_room_name, message, time

FROM general_chat
join profiles				on general_chat.user_id = profiles.id
join users 					on profiles.id = users.id
left join rooms				on rooms.id = general_chat.general_invite_room_id

order by time desc;

--**************************************************

--ЧАТ КОМНАТ
--представление для чатов с именами юзеров, id и названиями комнат, сообщениями
CREATE VIEW public.room_chat_view AS

SELECT username, rooms.id, rooms.name, message, time

FROM room_chat
join profiles				on room_chat.user_id = profiles.id
join users 					on profiles.id = users.id
left join rooms				on rooms.id = room_chat.room_id

order by time desc;


