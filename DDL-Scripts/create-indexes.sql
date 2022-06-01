-- INCOMPLETE, WAITING FOR THE REST OF THE QUERIES


-- should speed up 3.7
CREATE INDEX idx_amount ON project (amount);
CREATE INDEX idx_type ON organization (type);
-- should speed up 3.3
CREATE INDEX idx_end_date ON project (end_date);