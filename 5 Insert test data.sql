--**************************************************
-- ЗАКОНЧИЛОСЬ СОЗДАНИЕ ВСЕГО, ДАЛЬШЕ ВНЕСЕНИЕ ТЕСТОВЫХ ДАННЫХ
--**************************************************
INSERT INTO public.roles(name, note)
VALUES 	('user', 'default role'),
		('admin', 'full features'),
		('guest', 'without auth');

INSERT INTO public.permissions(name, note)
VALUES 	('all', 'all users'),
		('friends 2nd level', 'friends list and next level friends'),
		('friends 1st level', 'friends list'),
		('nobody', 'lock all');
		
INSERT INTO public.rooms(name, is_private, source_url, room_token, delete_time)
VALUES 	('Самая первая комната', 	false, 	'https://youtu.be/JV2JcHYMnKk', 	'some token', 		null),
		('Комната 2', 		false, 	'https://youtu.be/IGKgBZUkfwk', 	'some token 2', 	null),
		('Приватная комната', 	true, 	'https://youtu.be/G0fBKHXNx-Y', 	'some token 3', 	null),
		('Приватная 2', 	true, 	'https://youtu.be/MomSITt84wY', 	'some token 4', 	'2024-06-01 11:00:00');

INSERT INTO public.url_history(room_id, source_url)
	VALUES 	((select distinct id from rooms where name = 'Комната 2'), 'https://youtu.be/tz5PnJuOOKg'),
			((select distinct id from rooms where name = 'Самая первая комната'), 'https://youtu.be/DqBvBMSlhEA'),
			((select distinct id from rooms where name = 'Самая первая комната'), 'https://youtu.be/OBW3ZvcPIbE');

INSERT INTO public.tags(name)
	VALUES 	('Аниме'),
			('Дорамы'),
			('Death note'),
			('Время приключений'),
			('Дисней'),
			('Мультики СССР'),
			('Стендап'),
			('Мюзиклы');
			
INSERT INTO public.room_tag(room_id, tag_id)
	VALUES 	((select distinct id from rooms where name = 'Самая первая комната'), 1),
			((select distinct id from rooms where name = 'Самая первая комната'), 3),
			((select distinct id from rooms where name = 'Комната 2'), 2),
			((select distinct id from rooms where name = 'Приватная комната'), 8);			
	
INSERT INTO public.users(username, email, password, refresh_token)
	VALUES 	('admin1', 		'user1@gmail.com', 	'encrypt_pass_1', 	'refresh_token_1'),
			('user2', 	'user2@mail.ru', 	'encrypt_pass_2', 	'refresh_token_2'),
			('user3', 	'user3@bk.ru', 		'encrypt_pass_3', 	'refresh_token_3'),
			('user4', 	'user4@yandex.ru', 	'encrypt_pass_4', 	'refresh_token_4'),
			('user5_ban', 	'user5@yandex.ru', 	'encrypt_pass_5', 	'refresh_token_5');


UPDATE public.profiles SET 
is_block = false 
where id = (select id from users where username = 'user5_ban');

UPDATE public.profiles SET 
permit_invite_friendship = 4, 
permit_invite_room = 4,
permit_view_profile = 4,
permit_send_message = 4,
status = 'status1'
where id = (select id from users where username = 'user2');

UPDATE public.profiles SET 
permit_invite_friendship = 3, 
permit_invite_room = 3,
permit_view_profile = 3,
permit_send_message = 3,
birthday = '1999-01-01'
where id = (select id from users where username = 'user3');

UPDATE public.profiles SET 
permit_invite_friendship = 2, 
permit_invite_room = 2,
permit_view_profile = 2,
permit_send_message = 2
where id = (select id from users where username = 'user4');


INSERT INTO public.user_role(user_id, role_id)
	VALUES 	((select distinct id from users where username = 'admin1'), 2), --admin1
			((select distinct id from users where username = 'user2'), 1), --user
			((select distinct id from users where username = 'user3'), 1), --user
			((select distinct id from users where username = 'user4'), 1), --user
			((select distinct id from users where username = 'user5_ban'), 1); --user

INSERT INTO public.room_user(room_id, user_id, is_owner)
	VALUES 	((select distinct id from rooms where name = 'Самая первая комната'), (select distinct id from users where username = 'admin1'), true), --в первой комнате админ1 (является владельцем) и еще юзер2
			((select distinct id from rooms where name = 'Самая первая комната'), (select distinct id from users where username = 'user2'), false),
			((select distinct id from rooms where name = 'Комната 2'), (select distinct id from users where username = 'user3'), true), --просто комната с одним юзером
			((select distinct id from rooms where name = 'Приватная комната'), (select distinct id from users where username = 'user4'), true); --приватная комната с одним юзером
			
INSERT INTO public.room_invites(initiator_id, acceptor_id, room_id)
	VALUES 	((select distinct id from users where username = 'user3'), (select distinct id from users where username = 'admin1'), (select distinct id from rooms where name = 'Комната 2')), -- переманивает админа1 из комнаты1 и комнату 2 (а админ1 в комнате1 владелец, что будет если он перейдет)
			((select distinct id from users where username = 'user4'), (select distinct id from users where username = 'user2'), (select distinct id from rooms where name = 'Приватная комната')); -- переманивает юзера2 из комнаты1 в комнату3, а она приватная; если оба перейдут, комната1 станет пустой

INSERT INTO public.friends(initiator_id, acceptor_id, is_accepted)
	VALUES 	((select distinct id from users where username = 'admin1'), (select distinct id from users where username = 'user2'), true), --первый админ1 дружит с 2 3 4 (все, кроме забаненного)
			((select distinct id from users where username = 'admin1'), (select distinct id from users where username = 'user3'), true),
			((select distinct id from users where username = 'admin1'), (select distinct id from users where username = 'user4'), true),
			((select distinct id from users where username = 'user3'), (select distinct id from users where username = 'user4'), false); --3й отправил заявку 4му, у которого стоит разрешение "друзья друзей", то есть должно работать, т.к. оба они являются друзьями админа1

INSERT INTO public.room_chat(room_id, user_id, message, "time")
	VALUES 	((select distinct id from rooms where name = 'Самая первая комната'), (select distinct id from users where username = 'admin1'), 'всем привет!', 														'2023-03-08 11:00:00'),
			((select distinct id from rooms where name = 'Самая первая комната'), (select distinct id from users where username = 'user2'), 'с 8 марта, барышни', 												'2023-03-08 11:01:00'),
			((select distinct id from rooms where name = 'Комната 2'), (select distinct id from users where username = 'user3'), 'im alone im so alone in this room sad story', 						'2023-03-08 11:02:00'),
			((select distinct id from rooms where name = 'Приватная комната'), (select distinct id from users where username = 'user4'), 'это приватная комната, сюда попадают только по моему приглашению', 	'2023-03-08 11:03:00');

INSERT INTO public.direct_messages(initiator_id, acceptor_id, message, "time")
	VALUES 	((select distinct id from users where username = 'admin1'), (select distinct id from users where username = 'user2'), 'классно, что мы с тобой в одной комнате', '2023-03-08 11:00:00'),
			((select distinct id from users where username = 'user2'), (select distinct id from users where username = 'admin1'), 'может, сделаем её приватной?', '2023-03-08 11:01:00'),
			((select distinct id from users where username = 'user2'), (select distinct id from users where username = 'admin1'), 'У меня нет таких прав, только у тебя, ты owner', '2023-03-08 11:02:00'),
			((select distinct id from users where username = 'user4'), (select distinct id from users where username = 'user2'), 'заходи в мою приватную комнату, кое-чего покажу))))', '2023-03-08 11:00:00');

INSERT INTO public.general_chat(general_invite_room_id, user_id, message, "time")
	VALUES 	((select distinct id from rooms where name = 'Комната 2'), (select distinct id from users where username = 'user3'), 'приглашение в комнату 2 в общем чате', '2023-06-11 11:00:00'),
			(null, (select distinct id from users where username = 'user3'), 'просто сообщение в общем чате', '2023-06-11 11:01:00'),
			(null, (select distinct id from users where username = 'admin1'), 'Im a law (Dredd)', '2023-06-11 11:02:00');
			
		
--**************************************************
-- ТАБЛИЦА ИСТОРИИ ДЛЯ FLYWAY на всякий случай
--**************************************************
-- Table: public.flyway_schema_history

-- DROP TABLE IF EXISTS public.flyway_schema_history;
/*
CREATE TABLE IF NOT EXISTS public.flyway_schema_history
(
    installed_rank integer NOT NULL,
    version character varying(50) COLLATE pg_catalog."default",
    description character varying(200) COLLATE pg_catalog."default" NOT NULL,
    type character varying(20) COLLATE pg_catalog."default" NOT NULL,
    script character varying(1000) COLLATE pg_catalog."default" NOT NULL,
    checksum integer,
    installed_by character varying(100) COLLATE pg_catalog."default" NOT NULL,
    installed_on timestamp without time zone NOT NULL DEFAULT now(),
    execution_time integer NOT NULL,
    success boolean NOT NULL,
    CONSTRAINT flyway_schema_history_pk PRIMARY KEY (installed_rank)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.flyway_schema_history
    OWNER to postgres;
-- Index: flyway_schema_history_s_idx

-- DROP INDEX IF EXISTS public.flyway_schema_history_s_idx;

CREATE INDEX IF NOT EXISTS flyway_schema_history_s_idx
    ON public.flyway_schema_history USING btree
    (success ASC NULLS LAST)
    TABLESPACE pg_default;
	*/