use mysql;

-- Para ver todos los usuarios/roles definidos (no muestra los roles predefinidos)
select * from mysql.user;

-- Para ver los permisos a nivel BD
select * from mysql.db;

-- Para ver los permisos a nivel tabla
select * from mysql.tables_priv;

-- Para ver los permisos a nivel columna
select * from mysql.columns_priv;

-- Para ver los permisos a nivel procedimiento
select * from mysql.procs_priv;

-- Requerimiento #1
-- ----------------

-- Para crear un usuario:
create user if not exists 'usuario2' identified by 'user222052025'; -- por defecto, el host vale '%'
create user if not exists 'usuario3' identified by 'user322052025'; 
create user if not exists 'usuario4' identified by 'user422052025'; 
-- create user if not exists 'usuario2'@'%'; -- sin clave


select * from mysql.user
where user in ('usuario1', 'usuario2', 'usuario3', 'usuario4');

-- Verificar que usuario1, usuario2, usuario3 y usuario4 se pueden conectar a MySQL

-- Por ahora, ninguna de estas cuentas puede realizar ninguna tarea en el servidor, salvo conectarse 
-- (en la tabla mysql.user todas las columnas de permisos valen ‘N’).
-- Para ver los permisos de un usuario:
show grants for 'usuario1'@'%';
show grants for 'usuario2'@'%';
show grants for 'usuario3'@'%';
show grants for 'usuario4'@'localhost';
-- Por ahora sólo aparece el permiso 'usage': indica que la cuenta no tiene privilegio alguno


-- Requerimiento #2
-- ----------------

-- Conectarse como usuario3 o usuario4 y verificar que no se pueden crear bases de datos

-- Creación de un grupo
create role if not exists IT; -- por defecto, el host vale '%'

select * from mysql.user;
-- los roles también aparecen en mysql.user

-- Asignación de usuarios a grupos
grant IT to 'usuario3'@'%', 'usuario4'@'%'; -- grant, para asignar usuarios a roles, emplea TO

-- Asignación de permisos a un rol
grant create on *.* to IT; -- El comando grant para asignar permisos emplea ON
-- Como el comando grant para asignar usuarios a roles difiere del comando grant para asignar permisos, 
-- no se puede combinar la asignación de permisos con la de usuarios en la misma sentencia

select * from mysql.user
where user = 'IT'; -- observar la columna create_priv 

-- Permisos de 'usuario3'
show grants for 'usuario3'@'%'; -- muestra el permiso usage y que pertenece a 'IT
show grants for 'usuario3'@'%' using IT; -- muestra el permiso create (por IT) y que pertenece a IT 

-- Para sacar un usuario de un grupo:
revoke IT from 'usuario3'@'%';
show grants for 'usuario3'@'%';

-- Borrado de un grupo:
drop role if exists IT;

-- Probar que si usuario3/usuario4 se reconectan e intentan crear una BD, no podrán
-- Esto se debe a que al asignárseles el rol Grupo2, el mismo no se activa automáticamente al conectarse
-- Esto se puede ver si usuario3/usuario4 ejecutan: select current_role()
-- Para especificar qué roles se activan cuando se conectan usuario3/usuario4:
set default role IT to 'usuario3'@'%';

-- También se puede especificar ALL para que se activen todos los roles de un usuario:
-- create role if not exists 'Grupo4', 'Grupo5';
-- grant 'Grupo4'@'%' to 'usuario3'@'%';
-- grant 'Grupo5'@'%' to 'usuario3'@'%';
-- set default role all to 'usuario3'@'%';

-- Probar que ahora usuario3/usuario4 sí pueden crear una BD
-- Al asignar el permiso create el usuario también puede ver cualquier BD (hacer use <BD>), pero no puede seleccionar nada de ninguna BD

-- Un usuario puede modificar sus propios permisos efectivos para la sesión actual especificando cuáles roles a los que pertenece están activos.
-- Por ejemplo, si usuario3 quiere que ningún rol esté activo, puede ejecutar set role none;
-- Si ahora usuario3 quiere activar distintos roles: set role <rol1>, <rol2>, ...;
-- Si quisiera activav todos los roles: set role all;
-- Si quisiera activar los roles que le fueron activados mediante SET DEFAULT ROLE: set role default;

-- Si en lugar de crear roles se trabaja individualmente con los usuarios, 
-- a cada uno se le debería otorgar un permiso
-- Para emplear la interfaz gráfica, en la solapa de roles administrativos se tilda el permiso correspondiente  


-- Requerimiento #3
-- ----------------

-- Verificar que usuario1 y usuario2 no pueden pararse en la BD northwind
-- Crear el grupo Grupo1: 
create role if not exists Personal;
-- Agregar a Personal a usuario1 y usuario2:
grant Personal to 'usuario1'@'%', 'usuario2'@'%';
set default role Personal to 'usuario1'@'%';

-- Si se asignan a Personal los permisos select, insert, update y delete a nivel servidor 
-- (grant select, insert, update, delete on *.* to Personal)
-- usuario1 y usuario2 se podrán parar, insertar, borrar y modificar cualquier BD, 
-- y sólo se quiere esto para la BD northwind:
grant select, insert, update, delete on northwind.* to Personal;

select * from mysql.db
where user = 'Personal';

-- Si se hubiera querido limitar los permisos sólo a una tabla de la BD, por ejemplo categories:
-- grant select, insert, update, delete on northwind.categories to Personal;

-- Requerimiento #4
-- ----------------

USE northwind;

DROP PROCEDURE IF EXISTS ver_categorias;

DELIMITER //
CREATE PROCEDURE ver_categorias()
BEGIN  
	SELECT * FROM categories;   
END //
DELIMITER ;

CALL ver_categorias();

use mysql;

-- Probar que usuario1 no puede ejecutar el procedimiento ver_categorias
-- Para que sólo usuario1 pueda ejecutar el procedimiento ver_categorias:
grant execute on procedure northwind.ver_categorias to 'usuario1'@'%';
show grants for 'usuario1'@'%';
select * from mysql.procs_priv
where user = 'usuario1';


-- Requerimiento #5
-- ----------------

-- Crear el usuario PersonalAp y verificar que se pueda conectar pero no pueda pararse en ninguna BD:
create user if not exists 'PersonalAp' identified by 'ApPersonal22052025';
 
-- Asignarle permisos de selección sobre cualquier tabla de northwind (sólo a esa BD, no a todo el servidor):
grant select on northwind.* to 'PersonalAp'@'%';


-- Requerimiento #6
-- ----------------

-- Asignación de clave (conectado como usuario1)
-- alter user 'PersonalAp'@'%' identified by 'ApPersonal20250522';



drop user if exists 'usuario1'@'%';
drop user if exists 'usuario2'@'%';
drop user if exists 'usuario3'@'%';
drop user if exists 'usuario4'@'%';
drop user if exists 'PersonalAp'@'%';
drop role if exists IT;
drop role if exists Personal;

select * from mysql.user;