# VideoSharingServiceDB

##Создание БД для сервиса совместного просмотра видео в СУБД PostgreSQL;
##Требования к отношениям - 3 нф


##Представления (views):
1. представление с отображением комнат, в которых кто-то есть ( = активных), с подсчетом участников
	select * from public.active_room_view;
2. представление для общего чата с именами юзеров, id и названиями комнат (если есть приглашение), сообщениями
	select * from public.general_chat_view;
3. представление с количеством уведомлений для юзера (всего, заявки в друзья, приглашения в комнаты, непрочитанные личные сообщения)
	select * from public.notify_view;
4. представление для чатов с именами юзеров, id и названиями комнат, сообщениями
	select * from public.room_chat_view;
5. представление с данными юзеров + кол-во друзей, членство в комнате, разрешения в текстовом виде
	select * from public.users_view;


##Триггеры:
1. таблица users - триггер add_user - триггерная функция add_profile()
	создаётся профиль (передаётся сгенерированный UUID, остальные поля либо по-умолчанию, либо пустые)
2. таблица room_user - триггер user_enter_room - триггерная функция after_user_enter_room()
	если он один в комнате (т.е. вошел в пустую комнату), сбрасываем время удаления комнаты
3. таблица rooms - триггер add_room - триггерная функция after_add_room()
	из rooms удаляются комнаты, которым было назначено время удаления, если оно меньше текущего времени
4. таблица rooms - триггер delete_room - триггерная функция before_del_room()
	перед удалением комнаты удаляет записи по этой комнате из связей с пользователями, тегами, приглашениями, чатами(2), историей ресурсов
        (по сути альтернативная реализация параметра ON CASCADE DELETE внешних ключей указанных таблиц)
5. таблица room_user - триггер user_leave_room - триггерная функция after_user_leave_room()
	- назначение нового владельца комнаты если её покинул текущий владелец 
 		(назначается следующий за владельцем юзер, то есть самый старичок из оставшихся в комнате)
	- удаляет все приглашения в комнату (табл. room_invites) от покинувшего комнату
 		(независимо от того, владелец он комнаты или нет, т.к. юзер может приглашать кого-либо только в ту комнату, в которой находится
 		и если он из нее выходит, то существующие на этот момент приглашения теряют смысл)
	- если больше в комнате никого не осталось, устанавливаем время удаления комнаты (сейчас + 24ч)
6. таблица profiles - триггер delete_profile - триггерная функция before_del_profile()
	перед удалением профиля удаляет связанные записи из других таблиц (как двумя пунктами выше, альтернативная реализация ON CASCADE DELETE)


##Таблицы:
*select * from public.users;
*select * from public.profiles;
*select * from public.roles;
*select * from public.user_role;
*select * from public.rooms;
*select * from public.tags;
*select * from public.user_tag;
*select * from public.room_tag;
*select * from public.permissions;
*select * from public.friends;
*select * from public.room_user;
*select * from public.room_invites;
*select * from public.room_chat;
*select * from public.general_chat;
*select * from public.direct_messages;
*select * from public.url_history;
*стандартная таблица истории флайвей на всякий случай

![image](https://github.com/Ldv236/VideoSharingServiceDB/assets/124390764/abb1a9c4-5418-4cf2-af97-88d2de84755b)

