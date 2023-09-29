
--**************************************************
-- ЗАКОНЧИЛОСЬ СОЗДАНИЕ ТАБЛИЦ, ДАЛЬШЕ СОЗДАНИЕ ТРИГГЕРОВ
--**************************************************

-- ТРИГГЕР на добавление ЮЗЕРА
-- 1. создаётся профиль (передаётся сгенерированный UUID, остальные поля либо по-умолчанию, либо пустые)

CREATE OR REPLACE FUNCTION public.add_profile()
    RETURNS trigger
    LANGUAGE 'plpgsql'
     NOT LEAKPROOF
AS $BODY$
BEGIN
	INSERT INTO profiles (id, name) VALUES (NEW.id, NEW.username);
RETURN NEW;
END
$BODY$;
--триггер, запускающий функцию	
CREATE OR REPLACE TRIGGER add_user AFTER INSERT ON public.users
FOR EACH ROW
EXECUTE PROCEDURE add_profile();
--**************************************************

-- ТРИГГЕР на ВХОД ЮЗЕРА В КОМНАТУ
-- 1. если он один в комнате (т.е. вошел в пустую комнату), сбрасываем время удаления комнаты

CREATE OR REPLACE FUNCTION public.after_user_enter_room()
    RETURNS trigger
    LANGUAGE 'plpgsql'
     NOT LEAKPROOF
AS $BODY$
BEGIN		
	IF (select count(room_user.room_id) from room_user where room_user.room_id = NEW.room_id) = 1 THEN
	UPDATE public.rooms
	SET delete_time = null
	WHERE rooms.id = NEW.room_id;
	END IF;	
RETURN OLD;
END
$BODY$;

--триггер, запускающий функцию	
CREATE OR REPLACE TRIGGER user_enter_room AFTER INSERT ON public.room_user	
FOR EACH ROW
EXECUTE PROCEDURE after_user_enter_room();

--**************************************************

-- ТРИГГЕР на добавление новой комнаты
-- 1. из rooms удаляются комнаты, которым было назначено время удаления, и если оно меньше текущего времени

CREATE OR REPLACE FUNCTION public.after_add_room()
    RETURNS trigger
    LANGUAGE 'plpgsql'
     NOT LEAKPROOF
AS $BODY$
BEGIN
	DELETE FROM rooms
	WHERE delete_time < NOW()::timestamp;	
RETURN NEW;
END
$BODY$;
--триггер, запускающий функцию	
CREATE OR REPLACE TRIGGER add_room AFTER INSERT ON public.rooms
FOR EACH ROW
EXECUTE PROCEDURE after_add_room();

--**************************************************

--триггер перед удалением комнаты удаляет записи по этой комнате из связей с пользователями, тегами, приглашениями, чатами(2), историей ресурсов
--избавляемся от ставших неактуальными (по причине удаления комнаты) записей из перечисленных таблиц

CREATE OR REPLACE FUNCTION public.before_del_room()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    not LEAKPROOF
AS $BODY$
BEGIN
	IF (SELECT count(tablename) FROM pg_tables where tablename = 'tmpdelroom' /*and schemaname like '%temp%'*/) = 0 THEN
		CREATE TEMPORARY TABLE tmpdelroom (need_del_room boolean);
		--INSERT INTO tmp VALUES (true); 
	--ELSE
		--DELETE FROM tmp;
		--INSERT INTO tmp VALUES (true); 
	END IF;
	
 	--UPDATE room SET delete_time = '1970-01-01 01:01:01' WHERE room.id = OLD.id;
	DELETE FROM public.room_tag 		WHERE room_tag.room_id = OLD.id;
	DELETE FROM public.room_user 		WHERE room_user.room_id = OLD.id;
	DELETE FROM public.room_invites		WHERE room_invites.room_id = OLD.id;
	DELETE FROM public.room_chat 		WHERE room_chat.room_id = OLD.id;
	DELETE FROM public.general_chat 	WHERE general_chat.general_invite_room_id = OLD.id;
	DELETE FROM public.url_history 		WHERE url_history.room_id = OLD.id;	
RETURN OLD;
END
$BODY$;
--триггер, запускающий функцию	
CREATE OR REPLACE TRIGGER delete_room BEFORE DELETE ON public.rooms	
FOR EACH ROW
EXECUTE PROCEDURE before_del_room();

--**************************************************

-- ТРИГГЕР на ВЫХОД ЮЗЕРА ИЗ КОМНАТЫ
-- 1. назначение нового владельца комнаты если её покинул текущий владелец 
-- (назначается следующий за владельцем юзер, то есть самый старичок из оставшихся в комнате)
-- 2. удаляет все приглашения в комнату (табл. room_invites) от покинувшего комнату
-- (независимо от того, владелец он комнаты или нет, т.к. юзер может приглашать кого-либо только в ту комнату, в которой находится
-- и если он из нее выходит, то существующие на этот момент приглашения теряют смысл)
-- 3. (пока нет) если больше в комнате никого не осталось, устанавливаем время удаления комнаты

CREATE OR REPLACE FUNCTION public.after_user_leave_room()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    not LEAKPROOF
AS $BODY$
BEGIN
	--если временная таблица существует, значит происходит удаление комнаты, а не просто выход из неё юзера
	--тогда просто удаляем временную таблицу, а связанные с комнатой записи и так будут удалены 
	IF (SELECT count(tablename) FROM pg_tables where tablename = 'tmpdelroom' /*and schemaname like '%temp%'*/) = 1 THEN
	--IF EXISTS (SELECT count(tablename) FROM pg_tables where tablename = 'tmpdelroom' ) THEN
		DROP TABLE tmpdelroom;
	ELSE
		--в противном случае делаем три действия над покинутой юзером комнатой
		--если вышедший был владельцем, назначаем нового владельца
		IF OLD.is_owner = true THEN
			UPDATE public.room_user
			SET is_owner=true
			WHERE user_id = (select user_id from public.room_user where 
					 is_owner = false and 
					 room_id = OLD.room_id LIMIT 1);
		END IF;	
	--удаляем приглашения в комнату, которые отправлял вышедший
		DELETE FROM room_invites WHERE room_invites.initiator_id = OLD.user_id;
	--если больше в комнате никого не осталось, устанавливаем время удаления комнаты (сейсас) + интервал
		IF (select count(room_user.room_id) from room_user where room_user.room_id = OLD.room_id) = 0 THEN
			UPDATE public.room
			SET delete_time = NOW()::timestamp + interval '24 hour' 	
			WHERE room.id = OLD.room_id;
		END IF;
	END IF;		
RETURN OLD;
END
$BODY$;
--триггер, запускающий функцию	
CREATE OR REPLACE TRIGGER user_leave_room AFTER DELETE ON public.room_user	
FOR EACH ROW
EXECUTE PROCEDURE after_user_leave_room();
--**************************************************

--триггер перед удалением профиля удаляет связанные записи из связей с комнатами, тегами, приглашениями, чатами(2)
--избавляемся от ставших неактуальными (по причине удаления) записей из перечисленных таблиц

CREATE OR REPLACE FUNCTION public.before_del_profile()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    not LEAKPROOF
AS $BODY$
BEGIN
	--IF (SELECT count(tablename) FROM pg_tables where tablename = 'tmpdelroom' /*and schemaname like '%temp%'*/) = 0 THEN
		--CREATE TEMPORARY TABLE tmpdelroom (need_del_room boolean);
		--INSERT INTO tmp VALUES (true); 
	--ELSE
		--DELETE FROM tmp;
		--INSERT INTO tmp VALUES (true); 
	--END IF;
	
 	--UPDATE room SET delete_time = '1970-01-01 01:01:01' WHERE rooms.id = OLD.id;
	DELETE FROM public.user_tag 		WHERE user_tag.user_id = OLD.id;
	DELETE FROM public.user_role 		WHERE user_role.user_id = OLD.id;
	DELETE FROM public.room_user 		WHERE room_user.user_id = OLD.id;
	DELETE FROM public.room_invites 	WHERE room_invites.initiator_id = OLD.id;
	DELETE FROM public.room_invites 	WHERE room_invites.acceptor_id = OLD.id;
	DELETE FROM public.friends		WHERE friends.initiator_id = OLD.id;
	DELETE FROM public.friends		WHERE friends.acceptor_id = OLD.id;
	DELETE FROM public.room_chat 		WHERE room_chat.user_id = OLD.id;	
	DELETE FROM public.general_chat		WHERE general_chat.user_id = OLD.id;
	DELETE FROM public.direct_messages	WHERE direct_messages.initiator_id = OLD.id;
	DELETE FROM public.direct_messages	WHERE direct_messages.acceptor_id = OLD.id;
RETURN OLD;
END
$BODY$;
--триггер, запускающий функцию	
CREATE OR REPLACE TRIGGER delete_profile BEFORE DELETE ON public.profiles	
FOR EACH ROW
EXECUTE PROCEDURE before_del_profile();

