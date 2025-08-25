CREATE DATABASE Clinicas_Nara;

USE Clinicas_Nara;

# APAGANDO AS TABELAS 
DROP TABLE consultas;
DROP TABLE medicos;
DROP TABLE pacientes;
DROP TABLE clinicas;
DROP TABLE avaliacoes;

CREATE TABLE consultas (
id_consulta INT PRIMARY KEY,
id_paciente INT, FOREIGN KEY (id_paciente) REFERENCES pacientes(id_paciente),
id_medico INT, FOREIGN KEY (id_medico) REFERENCES medicos(id_medico),
id_clinica INT, FOREIGN KEY (id_clinica) REFERENCES clinicas(id_clinica),
especialidade VARCHAR (50),
data_hora_agendada DATETIME,
data_hora_inicio DATETIME,
status VARCHAR (50));

SET GLOBAL local_infile = 1;

SHOW VARIABLES LIKE "secure_file_priv";

LOAD DATA INFILE "C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/consultas_final.csv"
INTO TABLE consultas
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

CREATE TABLE pacientes (
id_paciente INT PRIMARY KEY,
idade INT,
sexo VARCHAR (20),
cidade VARCHAR (50),
plano_saude VARCHAR (10));

LOAD DATA INFILE "C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/pacientes_final.csv"
INTO TABLE pacientes
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

CREATE TABLE clinicas (
id_clinica INT PRIMARY KEY,
nome VARCHAR (100),
cidade VARCHAR (50),
capacidade_diaria INT);

LOAD DATA INFILE "C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/clinicas_final.csv"
INTO TABLE clinicas
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

CREATE TABLE medicos (
id_medico INT PRIMARY KEY,
nome VARCHAR (100),
especialidade VARCHAR (50));

LOAD DATA INFILE "C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/medicos_final.csv"
INTO TABLE medicos
FIELDS TERMINATED BY ';'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

CREATE TABLE avaliacoes (
id_consulta INT PRIMARY KEY,
nota_satisfacao INT,
comentario VARCHAR (100));

LOAD DATA INFILE "C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/avaliacoes_final.csv"
INTO TABLE avaliacoes
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

SELECT * FROM consultas;

# TOTAL DE CONSULTAS POR ESPECIALIDADE
SELECT especialidade, COUNT(id_consulta) AS Total_Atendimentos FROM consultas
GROUP BY especialidade;

# TOTAL DE CONSULTAS POR MEDICO (por id) ORDENADO PELO TOTAL ATENDIMENTO.
SELECT id_medico, COUNT(id_consulta) AS Total_Atendimentos FROM consultas
GROUP BY id_medico
ORDER BY Total_Atendimentos DESC;

# TOTAL CONSULTAS POR MEDICO (COM INNER JOIN E POR NOME) ORDENADO PELO TOTAL ATENDIMENTO.
SELECT medicos.nome, COUNT(id_consulta) AS Total_atendimentos
FROM consultas
INNER JOIN medicos ON consultas.id_medico = medicos.id_medico
GROUP BY nome
ORDER BY Total_Atendimentos DESC;
#SENTENÇA CORRETA SEM O INNER JOIN
SELECT medicos.nome, COUNT(consultas.id_consulta) AS Total_atendimentos
FROM medicos, consultas
WHERE medicos.id_medico = consultas.id_medico
GROUP BY medicos.nome
ORDER BY Total_atendimentos DESC;

# TOTAL CONSULTAS POR CLINICA (COM INNER JOIN E POR NOME)
SELECT clinicas.nome, COUNT(id_consulta) AS Total_atendimentos
FROM consultas
INNER JOIN clinicas ON consultas.id_clinica = clinicas.id_clinica
GROUP BY nome
ORDER BY Total_Atendimentos DESC;

# Total de pacientes por plano de saúde
SELECT plano_saude, COUNT(id_paciente) AS total_clientes
FROM pacientes
GROUP BY plano_saude
ORDER BY total_clientes DESC;

# TOTAL CONSULTAS POR STATUS
SELECT status, COUNT(id_paciente) AS total_clientes
FROM consultas
GROUP BY status
ORDER BY total_clientes DESC;

# NOVA DEMANDA

SELECT * FROM consultas;
SELECT * FROM pacientes;
SELECT * FROM clinicas;
SELECT * FROM avaliacoes;
SELECT * FROM medicos;


#Pacientes de determinadas cidades ou faixas etárias estão mais insatisfeitos com alguma especialidade?
# POR CIDADE
SELECT consultas.especialidade, pacientes.cidade, avaliacoes.nota_satisfacao, COUNT(consultas.id_consulta) AS Total_Atendimentos
FROM consultas
INNER JOIN pacientes ON pacientes.id_paciente = consultas.id_paciente
INNER JOIN avaliacoes ON avaliacoes.id_consulta = consultas.id_consulta
GROUP BY consultas.especialidade, pacientes.cidade, avaliacoes.nota_satisfacao
HAVING avaliacoes.nota_satisfacao = 1
ORDER BY avaliacoes.nota_satisfacao ASC;

#POR FAIXA ETARIA
SELECT consultas.especialidade, pacientes.idade, avaliacoes.nota_satisfacao, 
		COUNT(consultas.id_consulta) AS Total_Atendimentos
FROM consultas
INNER JOIN pacientes ON pacientes.id_paciente = consultas.id_paciente
INNER JOIN avaliacoes ON avaliacoes.id_consulta = consultas.id_consulta
GROUP BY consultas.especialidade, pacientes.idade, avaliacoes.nota_satisfacao
HAVING avaliacoes.nota_satisfacao = 1
ORDER BY avaliacoes.nota_satisfacao ASC;

#Médicos com menor tempo médio de atendimento (espera) estão concentrando mais reclamações?
SELECT 
    medicos.nome, 
    COUNT(consultas.id_consulta) AS Total_Reclamacoes,
    AVG(TIMESTAMPDIFF(MINUTE, consultas.data_hora_agendada, consultas.data_hora_inicio)) AS Tempo_Medio_Espera
FROM consultas
INNER JOIN medicos ON medicos.id_medico = consultas.id_medico
INNER JOIN avaliacoes ON avaliacoes.id_consulta = consultas.id_consulta
WHERE avaliacoes.nota_satisfacao <= 2
GROUP BY medicos.nome, avaliacoes.nota_satisfacao
ORDER BY Tempo_Medio_Espera DESC;

#Clínicas com maior capacidade estão realmente atendendo mais ou melhor?

SELECT 
    clinicas.nome,  
    COUNT(consultas.id_consulta) AS Total_Pacientes,
    AVG(avaliacoes.nota_satisfacao) AS Avaliacao_Media
FROM consultas
INNER JOIN clinicas ON clinicas.id_clinica = consultas.id_clinica
INNER JOIN avaliacoes ON avaliacoes.id_consulta = consultas.id_consulta
GROUP BY clinicas.nome
ORDER BY Total_Pacientes DESC;

#Existe relação entre plano de saúde  e tempo de espera?

SELECT 
    pacientes.plano_saude, 
    COUNT(pacientes.plano_saude) AS Plano_Saude,
    AVG(TIMESTAMPDIFF(MINUTE, consultas.data_hora_agendada, consultas.data_hora_inicio)) AS Tempo_Medio_Espera
FROM consultas
INNER JOIN pacientes ON pacientes.id_paciente = consultas.id_paciente
GROUP BY pacientes.plano_saude;

#Há especialidades com alta taxa de cancelamento e baixa nota de satisfação?
SELECT 
    consultas.especialidade, consultas.status,  
    COUNT(consultas.status) AS Cancelamentos,
    AVG(avaliacoes.nota_satisfacao) AS Avaliacao_Media
FROM consultas
INNER JOIN avaliacoes ON avaliacoes.id_consulta = consultas.id_consulta
WHERE consultas.status = 'Cancelada'
GROUP BY consultas.especialidade
ORDER BY Cancelamentos DESC;

SELECT * FROM pacientes;

