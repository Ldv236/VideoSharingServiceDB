--**************************************************
--СОЗДАНИЕ ТАБЛИЦ
--**************************************************

-- список ролей - юзер, админ, мало ли какие еще будут, можно не только роли целиком, а отдельные права определять
-- (для этого на перспективу и нужна связь многие-ко-многим между юзерами и ролями - ниже таблица user_role)
CREATE TABLE roles
(
    id 				int GENERATED ALWAYS AS IDENTITY NOT NULL,
    name 			varchar (100) NOT NULL,
    note 			varchar (200),
	
    CONSTRAINT roles_pk PRIMARY KEY (id)
);

--**************************************************
-- список разрешений на приглашения в друзья, приглашения в комнаты, просмотр профиля и т.п.
-- (все, никто, только друзья, друзья и друзья друзей)
CREATE TABLE permissions
(
    id 				int GENERATED ALWAYS AS IDENTITY NOT NULL,
    name 			varchar (100) NOT NULL,
    note 			varchar (200),
	
    CONSTRAINT permission_pk PRIMARY KEY (id)
);		

--**************************************************
-- список комнат
CREATE TABLE rooms
(
    id 				UUID DEFAULT gen_random_uuid(),
    name 			varchar (100) UNIQUE NOT NULL,
    is_private			boolean NOT NULL DEFAULT false,
    source_url			varchar,
    room_token			varchar,
    delete_time			timestamp,
	
    CONSTRAINT room_pk PRIMARY KEY (id)
);

--**************************************************
-- url in room history
-- при удалении комнаты триггер удаляет связанные с ней записи
CREATE TABLE url_history
(
    room_id 		UUID NOT NULL,
    source_url		varchar NOT NULL,
	
    CONSTRAINT url_history_fk_room 	FOREIGN KEY (room_id) 	REFERENCES rooms(id)
);

--**************************************************
--теги для комнат
CREATE TABLE tags
(	
	id 				int GENERATED ALWAYS AS IDENTITY NOT NULL,	
	name				varchar (50) UNIQUE NOT NULL,
	
	CONSTRAINT tags_pk PRIMARY KEY (id)
);

--**************************************************
-- связь комнаты-теги (many to many)
-- при удалении комнаты триггер удаляет связанные с ней записи
CREATE TABLE room_tag
(
    room_id 		        UUID NOT NULL,
    tag_id 			int NOT NULL,
	
    CONSTRAINT room_tag_pk 		PRIMARY KEY (room_id, tag_id),
    CONSTRAINT room_tag_fk_room 	FOREIGN KEY (room_id) 	REFERENCES rooms(id),
    CONSTRAINT room_tag_fk_tag 		FOREIGN KEY (tag_id) 	REFERENCES tags(id)
);

--**************************************************
-- список пользователей с данными аутентификации
-- (разделил данные пользователя для аутентификации и данные профиля)
CREATE TABLE users
(	
	id 				UUID DEFAULT gen_random_uuid(),	
	username			varchar (50) UNIQUE NOT NULL,
	email				varchar (200) UNIQUE NOT NULL, 
	password 			varchar NOT NULL,
	refresh_token		        varchar,
	
	CONSTRAINT users_pk PRIMARY KEY (id)
);

--**************************************************
-- данные профилей пользователей
-- за счет требования уникальности значения юзер_ид и ФК на этом поле с референсом на юзерс.ид реализуется связь один-к-одному
CREATE TABLE profiles
(	
        id 					UUID UNIQUE NOT NULL,
	name					varchar (50) UNIQUE NOT NULL,
	is_block				boolean NOT NULL DEFAULT false, 
	
	birthday				date,
	image					bytea,
	permit_invite_friendship		int DEFAULT 1,
	permit_invite_room			int DEFAULT 1,
	permit_view_profile			int DEFAULT 1,
	permit_send_message 			int DEFAULT 1,
	is_online				boolean DEFAULT false,
	status					varchar (100),	

	CONSTRAINT profile_fk_user 		FOREIGN KEY (id) 				REFERENCES users(id),
	CONSTRAINT profile_fk_invite_frnd 	FOREIGN KEY (permit_invite_friendship) 		REFERENCES permissions(id),
	CONSTRAINT profile_fk_invite_room 	FOREIGN KEY (permit_invite_room) 		REFERENCES permissions(id),
	CONSTRAINT profile_fk_view_profile 	FOREIGN KEY (permit_view_profile) 		REFERENCES permissions(id),
	CONSTRAINT profile_fk_send_message 	FOREIGN KEY (permit_send_message) 		REFERENCES permissions(id)
);

--**************************************************

-- для построения рекомендаций связь юзеры-теги, т.е. предпочтения юзеров (many to many)
CREATE TABLE user_tag
(
    user_id 			UUID NOT NULL,
    tag_id 			int NOT NULL,
	
    CONSTRAINT user_tag_pk 		PRIMARY KEY (user_id, tag_id),
    CONSTRAINT user_tag_fk_user 	FOREIGN KEY (user_id) 	REFERENCES profiles(id),
    CONSTRAINT user_tag_fk_tag 		FOREIGN KEY (tag_id) 	REFERENCES tags(id)
);

--**************************************************
-- связь многие-ко-многим для назначения прав/ролей юзерам
CREATE TABLE user_role
(
    user_id 		UUID NOT NULL,
    role_id 		int NOT NULL,
	
    CONSTRAINT user_role_pk 		PRIMARY KEY (user_id, role_id),
    CONSTRAINT user_role_fk_user 	FOREIGN KEY (user_id) 	REFERENCES profiles(id),
    CONSTRAINT user_role_fk_role 	FOREIGN KEY (role_id) 	REFERENCES roles(id)
);

--**************************************************
-- несмотря на то, что юзер может быть только в одной комнате одновременно, и следовательно требуется связь один-ко-многим,
-- чтобы постоянно не дергать таблицу юзеров (профилей) и комнат, используется связующая таблица
-- следовательно, из users убрано поле room_id, из room убрано поле role_owner, 
-- а из room_invites убрано булевское значение, означающее факт принятия приглашения.
-- при удалении комнаты триггер удаляет связанные с ней записи
CREATE TABLE room_user
(
    room_id 		UUID NOT NULL,
    user_id 		UUID UNIQUE NOT NULL, --user may be a member of one room only
    
	-- is_owner - указывает владельца комнаты; при её создании надо передавать явно тру для создающего юзера
	-- при выходе его из комнаты, если же она продолжает существовать
	-- триггер назначает тру следующему пользователю в этой комнате (на фронт передавать нового владельца, чтобы это как-то подсвечивалось)
    is_owner		boolean NOT NULL DEFAULT false, 
	
    CONSTRAINT room_user_pk 		PRIMARY KEY (room_id, user_id),
    CONSTRAINT room_user_fk_room 	FOREIGN KEY (room_id) 	REFERENCES rooms(id),
    CONSTRAINT room_user_fk_user 	FOREIGN KEY (user_id) 	REFERENCES profiles(id)
);

--**************************************************
-- приглашении пользователя в комнату
-- связь комната-юзер и приглашения разделены потому что
-- 1. в комнату попадают не только по приглашениям (создают, заходят с главной страницы...)
-- 2. поле инициатор станет бессмысленным лишним как при входе НЕ по приглашению, так и при принятии заявки
-- 3. надо хранить поле is_acceped, из-за всего этого получается слишком сложная логика работы с таблицей, с двумя разными проще
-- при принятии приглашения соответствующая связь вносится в табл room_user, а отсюда строка удаляется 
-- (можно реализовать внесение через триггер на delete на эту таблицу, или наоборот удаление отсюда по триггеру на инсерт в room_user)
-- (также отсюда записи удаляются триггерами при удалении комнат и при выходе из комнат юзера-инициатора)
CREATE TABLE room_invites
(
    initiator_id 		UUID NOT NULL,
    acceptor_id 		UUID NOT NULL,
    room_id			UUID NOT NULL,
	
    CONSTRAINT room_invites_pk 			PRIMARY KEY (initiator_id, acceptor_id),
    CONSTRAINT room_invites_fk_initiator 	FOREIGN KEY (initiator_id) 	REFERENCES profiles(id),
    CONSTRAINT room_invites_fk_acceptor 	FOREIGN KEY (acceptor_id) 	REFERENCES profiles(id),
    CONSTRAINT room_invites_fk_room 		FOREIGN KEY (room_id) 		REFERENCES rooms(id)
);

--**************************************************
-- список дружеских связей
-- когда is_accepted == false, значит заявка в друзья подана и находится на рассмотрении
-- когда is_accepted == true, значит заявка принята и эта запись содержит уже дружескую связь, а не заявку
CREATE TABLE friends
(
    initiator_id 		UUID NOT NULL,
    acceptor_id 		UUID NOT NULL,
    is_accepted 		boolean NOT NULL DEFAULT false,
	
    CONSTRAINT friends_pk 		PRIMARY KEY (initiator_id, acceptor_id),
    CONSTRAINT friends_fk_initiator 	FOREIGN KEY (initiator_id) 	REFERENCES profiles(id),
    CONSTRAINT friends_fk_acceptor 	FOREIGN KEY (acceptor_id) 	REFERENCES profiles(id)
);

--**************************************************
-- чаты в комнатах
-- старые записи можно автоматически удалять через какое-то время
-- при удалении комнаты триггер удаляет связанные с ней записи
CREATE TABLE room_chat
(
    room_id				UUID NOT NULL,
    user_id 				UUID NOT NULL,
    message 				varchar (500) NOT NULL,
    time 				timestamp NOT NULL,
	
    CONSTRAINT room_chat_fk_room 	FOREIGN KEY (room_id) 	REFERENCES rooms(id),
    CONSTRAINT room_chat_fk_user 	FOREIGN KEY (user_id) 	REFERENCES profiles(id)
);

--**************************************************

--таблица для общего чата на главной странице
CREATE TABLE general_chat
(
    general_invite_room_id		UUID, 		--если в общем чате можно звать всех в комнату
    user_id 				UUID NOT NULL,
    message 				varchar (500) NOT NULL,
    time 				timestamp NOT NULL,
	
    CONSTRAINT general_chat_fk_room 	FOREIGN KEY (general_invite_room_id) 	REFERENCES rooms(id),
    CONSTRAINT general_chat_fk_user 	FOREIGN KEY (user_id) 			REFERENCES profiles(id)
);

--**************************************************

--сообщения в личку
CREATE TABLE direct_messages
(
    initiator_id 		UUID NOT NULL,
    acceptor_id 		UUID NOT NULL,
    message 			varchar (500) NOT NULL,
    time 			timestamp NOT NULL,
    is_read 			boolean NOT NULL DEFAULT false,
	
    CONSTRAINT direct_fk_initiator 	FOREIGN KEY (initiator_id) 	REFERENCES profiles(id),
    CONSTRAINT direct_fk_acceptor 	FOREIGN KEY (acceptor_id) 	REFERENCES profiles(id)
);

