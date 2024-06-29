CREATE SCHEMA IF NOT EXISTS Project3;
USE Project3;

-- Creación de la tabla customer_courier_chat_messages
CREATE TABLE IF NOT EXISTS customer_courier_chat_messages (
    sender_app_type VARCHAR(255),
    customer_id INT,
    from_id INT,
    to_id INT,
    chat_started_by_message CHAR(1),
    order_id INT,
    order_stage VARCHAR(255),
    courier_id INT,
    message_sent_time TIMESTAMP
);

-- Creación de la tabla orders
CREATE TABLE IF NOT EXISTS orders (
    order_id INT,
    city_code VARCHAR(50)
);

-- Insertar datos en customer_courier_chat_messages
INSERT INTO customer_courier_chat_messages (sender_app_type, customer_id, from_id, to_id, chat_started_by_message, order_id, order_stage, courier_id, message_sent_time) VALUES
('Customer iOS', 17071099, 17071099, 16293039, 'f', 59528555, 'PICKING_UP', 16293039, '2019-08-19 08:03:00'),
('Courier iOS', 17071099, 16293039, 17071099, 'f', 59528555, 'ARRIVING', 16293039, '2019-08-19 08:01:00'),
('Customer iOS', 17071099, 17071099, 16293039, 'f', 59528555, 'PICKING_UP', 16293039, '2019-08-19 08:00:00'),
('Courier Android', 12874122, 18325287, 12874122, 't', 59528038, 'ADDRESS_DELIVERY', 18325287, '2019-08-19 07:59:00');

-- Insertar datos en orders
INSERT INTO orders (order_id, city_code) VALUES
(59528555, 'BCN'),
(59528038, 'MAD');

DROP TABLE IF EXISTS customer_courier_conversations;

CREATE TABLE customer_courier_conversations AS
WITH FirstMessages AS (
    SELECT
        order_id,
        MIN(message_sent_time) AS first_message_time
    FROM
        customer_courier_chat_messages
    GROUP BY
        order_id
),
FirstCourierMessages AS (
    SELECT
        order_id,
        MIN(message_sent_time) AS first_courier_message_time
    FROM
        customer_courier_chat_messages
    WHERE
        sender_app_type LIKE 'Courier%'
    GROUP BY
        order_id
),
FirstCustomerMessages AS (
    SELECT
        order_id,
        MIN(message_sent_time) AS first_customer_message_time
    FROM
        customer_courier_chat_messages
    WHERE
        sender_app_type LIKE 'Customer%'
    GROUP BY
        order_id
)
SELECT
    ccm.order_id,
    o.city_code,
    fc.first_courier_message_time,
    fcu.first_customer_message_time,
    SUM(CASE WHEN ccm.sender_app_type LIKE 'Courier%' THEN 1 ELSE 0 END) AS courier_message_count,
    SUM(CASE WHEN ccm.sender_app_type LIKE 'Customer%' THEN 1 ELSE 0 END) AS customer_message_count,
    fm.first_message_time,
    CASE
        WHEN fm.first_message_time = fc.first_courier_message_time THEN 'courier'
        ELSE 'customer'
    END AS first_sender,
    MIN(CASE
        WHEN ccm.message_sent_time > fm.first_message_time
        THEN TIMESTAMPDIFF(SECOND, fm.first_message_time, ccm.message_sent_time)
    END) AS first_response_time,
    MAX(ccm.message_sent_time) AS last_message_time,
    MAX(ccm.order_stage) AS last_order_stage
FROM
    customer_courier_chat_messages ccm
JOIN
    orders o ON ccm.order_id = o.order_id
JOIN
    FirstMessages fm ON ccm.order_id = fm.order_id
LEFT JOIN
    FirstCourierMessages fc ON ccm.order_id = fc.order_id
LEFT JOIN
    FirstCustomerMessages fcu ON ccm.order_id = fcu.order_id
GROUP BY
    ccm.order_id, o.city_code, fm.first_message_time, fc.first_courier_message_time, fcu.first_customer_message_time;
