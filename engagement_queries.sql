-- =================================================
-- КЕЙС: АНАЛИЗ ВОВЛЕЧЕННОСТИ ПОЛЬЗОВАТЕЛЕЙ (Engagement)
-- Автор: Лобанова Анна
-- Инструмент: PostgreSQL / SQLite
-- Описание: Расчет ключевых продуктовых метрик (DAU, MAU, Sticky Factor)
-- и анализ динамики активной базы пользователей.
-- =================================================

-- 1. РАСЧЕТ DAU, MAU И STICKY FACTOR ПО МЕСЯЦАМ
-- Sticky Factor показывает, насколько часто пользователи возвращаются в продукт.
WITH daily_dau AS (
    SELECT 
        DATE_TRUNC('month', entry_at)::date AS month,
        DATE(entry_at) AS day,
        COUNT(DISTINCT user_id) AS dau
    FROM UserEntry
    WHERE entry_at >= '2022-01-01' AND (user_id >= 94 OR user_id IS NULL)
    GROUP BY 1, 2
),
active_metrics AS (
    SELECT 
        DATE_TRUNC('month', entry_at)::date AS month,
        COUNT(DISTINCT user_id) AS mau,
        AVG(dau) AS avg_dau
    FROM UserEntry m
    JOIN daily_dau d ON DATE_TRUNC('month', m.entry_at)::date = d.month
    WHERE m.entry_at >= '2022-01-01' AND (m.user_id >= 94 OR m.user_id IS NULL)
    GROUP BY 1
),
-- 2. АНАЛИЗ НАКОПЛЕННОЙ БАЗЫ (TOTAL USERS)
registrations AS (
    SELECT 
        DATE_TRUNC('month', date_joined)::date AS month,
        COUNT(id) AS new_regs
    FROM users
    WHERE date_joined >= '2022-01-01' AND (id >= 94 OR id IS NULL)
    GROUP BY 1
),
cumulative_regs AS (
    SELECT 
        month,
        SUM(new_regs) OVER (ORDER BY month) AS total_users
    FROM registrations
)
-- ФИНАЛЬНАЯ ВИТРИНА ДАННЫХ
SELECT 
    a.month,
    c.total_users,
    a.mau,
    ROUND(a.avg_dau, 2) AS avg_dau,
    ROUND(100.0 * a.mau / c.total_users, 2) AS active_base_pct,
    ROUND(100.0 * a.avg_dau / a.mau, 2) AS sticky_factor_pct
FROM active_metrics a
JOIN cumulative_regs c ON a.month = c.month
ORDER BY a.month;
