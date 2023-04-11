CREATE DATABASE AmateurChampionship
GO

USE AmateurChampionship
GO

-- Criando tabelas
CREATE TABLE Team
(
    [Name] VARCHAR(50) NOT NULL,
    [NickName] VARCHAR(50),
    [Date_Creation] DATE,

    CONSTRAINT PK_Team PRIMARY KEY ([Name])
)
GO

CREATE TABLE Match
(
    [ID] int IDENTITY (1,1) NOT NULL,
    [Home_Goal] int NOT NULL,
    [Away_Goal] int NOT null,
    [Result] VARCHAR(20) NOT NULL,
    [Home_Team] VARCHAR(50) NOT NULL,
    [Away_Team] VARCHAR(50) NOT NULL,

    CONSTRAINT PK_Match PRIMARY KEY ([ID]),
    CONSTRAINT FK_Home_Team FOREIGN KEY (Home_Team) REFERENCES Team ([Name]),
    CONSTRAINT Fk_Away_Team FOREIGN KEY (Away_Team) REFERENCES Team ([Name])
)
GO

CREATE TABLE Standing
(
    [Name_Team] VARCHAR(50) NOT NULL,
    [Point] int NOT NULL,
    [Home_Win] int NOT NULL,
    [Away_Win] int NOT NULL,
    [Draw] int,

    CONSTRAINT PK_Standing PRIMARY KEY ([Name_Team]),
    CONSTRAINT FK_Standing_Team FOREIGN KEY ([Name_Team]) REFERENCES Team ([Name])
)
GO

-- trigger para adicionar pontos após as partidas e adicionar empates e vitorias aos times
CREATE OR ALTER trigger TGR_AddPoint ON [Match] AFTER INSERT 
AS
BEGIN
    DECLARE @home_team VARCHAR(50), @away_team VARCHAR(50), @result VARCHAR(20), @home_goal int, @away_goal int, @home_points int, @away_points int

    SELECT @home_team = [Home_Team], @away_team = [Away_Team], @result = [Result], @home_goal = [Home_goal], @away_goal = [Away_Goal]
    FROM inserted

    SET @home_points = 0
    SET @away_points = 0

    IF @result = @home_team + ' - ' + @away_team
        BEGIN
        SET @home_points = 3
    END
    ELSE IF @result = @away_team + ' - ' + @home_team
        BEGIN
        SET @away_points = 5
    END
    ELSE
        BEGIN
        IF @home_goal > @away_goal
                BEGIN
            SET @home_points = 3
        END
            ELSE IF @home_goal < @away_goal
                BEGIN
            SET @away_points = 5
        END
            ELSE
                BEGIN
            SET @home_points = 1
            SET @away_points = 1
        END
        IF @home_goal = @away_goal
                BEGIN
            UPDATE [Standing]
                    SET [Draw] = [Draw] + 1
                    WHERE [Name_team] = @home_team OR [Name_Team] = @away_team
        END
    END

    UPDATE [Standing]
    SET [Point] = [Point] + CASE
                          WHEN [Name_Team] = @home_team THEN @home_points
                          WHEN [Name_Team] = @away_team THEN @away_points
                          ELSE 0
                        END,
    [Home_Win] = [Home_Win] + CASE 
                            WHEN [Name_Team] = @home_team AND @home_goal > @away_goal THEN 1
                            WHEN [Name_Team] = @away_team AND @away_goal > @home_goal THEN 1
                            ELSE 0
                        END,
    [Away_Win] = [Away_Win] + CASE 
                            WHEN [Name_Team] = @home_team AND @home_goal < @away_goal THEN 1
                            WHEN [Name_Team] = @away_team AND @away_goal < @home_goal THEN 1
                            ELSE 0
                        END          
    WHERE [Name_Team] = @home_team OR [Name_Team] = @away_team
END;
GO

-- Procedure para calcular time que mais fez gols
CREATE OR ALTER PROCEDURE GetTopScoringTeam
AS
BEGIN
    SELECT TOP 1
        s.Name_team, SUM(CASE
                                            WHEN s.Name_Team = m.Home_Team THEN m.Home_Goal
                                            WHEN s.Name_Team = m.Away_Team THEN m.Away_Goal
                                            ELSE 0
                                        END) AS GoalsScored
    FROM Standing s
        JOIN Team t ON s.Name_Team = t.Name
        JOIN Match m ON m.Home_Team = s.Name_Team OR m.Away_Team = s.Name_team
    GROUP BY s.Name_Team
    ORDER BY GoalsScored DESC
END;
GO

-- Procedure para calcular time que mais sofreu gols
CREATE OR ALTER PROCEDURE GetTopConcedingTeam
AS
BEGIN
    SELECT TOP 1
        s.Name_team, SUM(CASE
                                  WHEN s.Name_team = m.Home_team THEN m.Away_Goal
                                  WHEN s.Name_Team = m.Away_team THEN m.Home_goal
                                  ELSE 0
                                END) AS GoalsConceded
    FROM Standing s
        JOIN Team t ON s.Name_team = t.Name
        JOIN [Match] m ON m.Home_Team = s.Name_team OR m.Away_Team = s.Name_team
    GROUP BY s.Name_team
    ORDER BY GoalsConceded DESC
END;
GO

-- Procedure para calcular o jogo que mais teve gols
CREATE OR ALTER PROCEDURE GetTopScoringMatch
AS
BEGIN
    SELECT TOP 1
        ID, Home_Team, Away_Team, Home_Goal + Away_Goal AS Goals
    FROM [Match]
    ORDER BY Goals DESC
END;
GO

--Procedure para descobrir o maior numero de gols que cada time fez em um unico jogo
CREATE OR ALTER PROCEDURE GetMaxGoals
AS
BEGIN

    SELECT Team.[Name], MAX(Home_Goal) AS MaxHomeGoals, MAX(Away_Goal) AS MaxAwayGoals
    FROM Team
    LEFT JOIN [Match] ON Team.[Name] = [Match].[Home_Team] OR Team.[Name] = [Match].[Away_Team]
    GROUP BY Team.[Name]
END

-- Inserindo os times
INSERT INTO [Team]
VALUES
    ('Palmeiras', 'Verdao', '1914-08-26')
INSERT INTO [Team]
VALUES
    ('Corinthians', 'Timao', '1910-09-01')
INSERT INTO [Team]
VALUES
    ('Sao Paulo', 'Tricolor', '1930-01-25')
INSERT INTO [Team]
VALUES
    ('Santos', 'Peixe', '1912-04-14')
INSERT INTO [Team]
VALUES
    ('Flamengo', 'Mengao', '1895-11-15')
GO

-- Inserindo tabela Standing
INSERT INTO [Standing]
    ([Name_Team], [Point], [Home_Win], [Away_Win], [Draw])
VALUES
    ('Palmeiras', 0, 0, 0, 0),
    ('Corinthians', 0, 0, 0, 0),
    ('Santos', 0, 0, 0, 0),
    ('Sao Paulo', 0, 0, 0, 0),
    ('Flamengo', 0, 0, 0, 0)
GO

-- Inserindo partidas na tabela Match
INSERT INTO [Match]
    ([Home_Goal], [Away_Goal], [Result], [Home_Team], [Away_Team])
VALUES
    (4, 1, '4-1', 'Palmeiras', 'Corinthians')
INSERT INTO [Match]
    ([Home_Goal], [Away_Goal], [Result], [Home_Team], [Away_Team])
VALUES
    (1, 3, '1-3', 'Corinthians', 'Palmeiras')
INSERT INTO [Match]
    ([Home_Goal], [Away_Goal], [Result], [Home_Team], [Away_Team])
VALUES
    (2, 1, '2-1', 'Palmeiras', 'Sao Paulo')
INSERT INTO [Match]
    ([Home_Goal], [Away_Goal], [Result], [Home_Team], [Away_Team])
VALUES
    (1, 1, '1-1', 'Sao Paulo', 'Palmeiras')
INSERT INTO [Match]
    ([Home_Goal], [Away_Goal], [Result], [Home_Team], [Away_Team])
VALUES
    (1, 2, '1-2', 'Palmeiras', 'Santos')
INSERT INTO [Match]
    ([Home_Goal], [Away_Goal], [Result], [Home_Team], [Away_Team])
VALUES
    (0, 2, '0-2', 'Santos', 'Palmeiras')
INSERT INTO [Match]
    ([Home_Goal], [Away_Goal], [Result], [Home_Team], [Away_Team])
VALUES
    (4, 3, '4-3', 'Palmeiras', 'Flamengo')
INSERT INTO [Match]
    ([Home_Goal], [Away_Goal], [Result], [Home_Team], [Away_Team])
VALUES
    (1, 1, '1-1', 'Flamengo', 'Palmeiras')
INSERT INTO [Match]
    ([Home_Goal], [Away_Goal], [Result], [Home_Team], [Away_Team])
VALUES
    (3, 1, '3-1', 'Corinthians', 'Sao Paulo')
INSERT INTO [Match]
    ([Home_Goal], [Away_Goal], [Result], [Home_Team], [Away_Team])
VALUES
    (4, 2, '4-2', 'Sao Paulo', 'Corinthians')
INSERT INTO [Match]
    ([Home_Goal], [Away_Goal], [Result], [Home_Team], [Away_Team])
VALUES
    (1, 1, '1-1', 'Corinthians', 'Santos')
INSERT INTO [Match]
    ([Home_Goal], [Away_Goal], [Result], [Home_Team], [Away_Team])
VALUES
    (3, 2, '3-2', 'Santos', 'Corinthians')
INSERT INTO [Match]
    ([Home_Goal], [Away_Goal], [Result], [Home_Team], [Away_Team])
VALUES
    (0, 2, '0-2', 'Corinthians', 'Flamengo')
INSERT INTO [Match]
    ([Home_Goal], [Away_Goal], [Result], [Home_Team], [Away_Team])
VALUES
    (3, 0, '3-0', 'Flamengo', 'Corinthians')
INSERT INTO [Match]
    ([Home_Goal], [Away_Goal], [Result], [Home_Team], [Away_Team])
VALUES
    (3, 2, '3-2', 'Sao Paulo', 'Santos')
INSERT INTO [Match]
    ([Home_Goal], [Away_Goal], [Result], [Home_Team], [Away_Team])
VALUES
    (4, 1, '4-1', 'Santos', 'Sao Paulo')
INSERT INTO [Match]
    ([Home_Goal], [Away_Goal], [Result], [Home_Team], [Away_Team])
VALUES
    (3, 1, '3-1', 'Sao Paulo', 'Flamengo')
INSERT INTO [Match]
    ([Home_Goal], [Away_Goal], [Result], [Home_Team], [Away_Team])
VALUES
    (1, 1, '1-1', 'Flamengo', 'Sao Paulo')
INSERT INTO [Match]
    ([Home_Goal], [Away_Goal], [Result], [Home_Team], [Away_Team])
VALUES
    (1, 1, '1-1', 'Santos', 'Flamengo')
INSERT INTO [Match]
    ([Home_Goal], [Away_Goal], [Result], [Home_Team], [Away_Team])
VALUES
    (1, 1, '1-1', 'Flamengo', 'Santos')
GO

-- Descobrindo o campeão
SELECT TOP 1
    [Name_team], [Point], [Home_Win], [Away_Win], [Draw]
FROM [Standing]
ORDER BY [Point] DESC, [Home_Win] DESC, [Away_Win] DESC;

-- Verificando os 5 primeiros times da tabela
SELECT TOP 5
    [Name_team], [Point], [Home_Win], [Away_Win], [Draw]
FROM [Standing]
ORDER BY [Point] DESC;

--Caso haja empate no numero de pontos, desempata pelas vitorias
SELECT [Name_team], [Point], [Home_win], [Away_win], [Draw]
FROM [Standing]
ORDER BY [Point] DESC, [Home_Win] + [Away_Win] DESC;

--Qual time fez mais gols?
EXEC.GetTopScoringTeam

-- Qual time tomou mais gols?
EXEC.GetTopConcedingTeam

-- Qual jogo teve mais gols?
exec.GetTopScoringMatch

--Execute depois de ativar as procedures
EXEC.GetTopScoringTeam

--Qual maior numero de gols que cada time fez em um unico jogo?
EXEC.GetMaxGoals
